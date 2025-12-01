1. Tables
- `users`

This table is managed by Subbase Auth.

  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
  - `email CITEXT NOT NULL UNIQUE`.
  - `password_hash TEXT NOT NULL` (managed by Supabase auth triggers).
  - `first_name TEXT NOT NULL`, `last_name TEXT`.
  - `role user_role NOT NULL DEFAULT 'athlete'`.
  - `contact_email CITEXT`, `contact_phone TEXT`.
  - `preferences JSONB NOT NULL DEFAULT '{}'::jsonb`.
  - `is_anonymous BOOLEAN NOT NULL DEFAULT FALSE`, `deleted_at TIMESTAMPTZ`.
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - Constraints: trainers must provide at least one contact channel (`CHECK (role <> 'trainer' OR contact_email IS NOT NULL OR contact_phone IS NOT NULL)`); soft-delete enforced through `deleted_at` and `is_anonymous`.

- `slots`
  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
  - `trainer_id UUID NOT NULL REFERENCES users(id)`.
  - `start_at TIMESTAMPTZ NOT NULL`, `end_at TIMESTAMPTZ NOT NULL`, `CHECK (end_at > start_at)`.
  - `duration_minutes SMALLINT NOT NULL DEFAULT 60 CHECK (duration_minutes BETWEEN 30 AND 240)`.
  - `capacity SMALLINT NOT NULL DEFAULT 1 CHECK (capacity BETWEEN 1 AND 20)`.
  - `notes TEXT`, `cancelled_at TIMESTAMPTZ`.
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - Constraints: `EXCLUDE USING gist (trainer_id WITH =, tstzrange(start_at, end_at) WITH &&) WHERE (capacity < 0)` intentionally omitted to allow overlapping slots per requirements; deletion prevented by trigger when bookings exist.

- `bookings`
  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
  - `slot_id UUID NOT NULL REFERENCES slots(id) ON DELETE CASCADE`.
  - `user_id UUID NOT NULL REFERENCES users(id)`.
  - `status booking_status NOT NULL DEFAULT 'reserved'`.
  - `status_changed_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - `auto_processed BOOLEAN NOT NULL DEFAULT FALSE`.
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - Constraints: `UNIQUE (slot_id, user_id)`; cancellation window enforced by trigger preventing `status = 'cancelled'` when `slots.start_at - NOW() < interval '60 minutes'`; capacity respected through transactional check comparing `capacity` with count of active bookings.

- `activity_logs`
  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
  - `entity_type log_entity_type NOT NULL`.
  - `entity_id UUID NOT NULL`.
  - `action log_action_type NOT NULL`.
  - `changed_by UUID REFERENCES users(id)`.
  - `changed_by_role user_role`.
  - `changed_fields JSONB NOT NULL` (partial snapshot of modified columns).
  - `metadata JSONB NOT NULL DEFAULT '{}'::jsonb`.
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - Constraints: `(entity_type, entity_id)` indexed; `changed_fields` must not be empty (`CHECK (jsonb_typeof(changed_fields) = 'object' AND jsonb_array_length(jsonb_object_keys(changed_fields)) IS NULL)` is enforced via trigger to guarantee at least one field entry).

- `booking_status_history`
  - `id BIGSERIAL PRIMARY KEY`.
  - `booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE`.
  - `previous_status booking_status NOT NULL`.
  - `current_status booking_status NOT NULL`.
  - `changed_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
  - `changed_by UUID REFERENCES users(id)`.
  - `auto_processed BOOLEAN NOT NULL DEFAULT FALSE`.
  - Captures chronological status transitions separate from general logs to simplify analytics.

- `trainer_directory` (materialized view or table)
  - Columns: `trainer_id`, `display_name`, `contact_email`, `contact_phone`, `updated_at`.
  - Populated via trigger on `users` to expose only active trainers (`deleted_at IS NULL AND role = 'trainer'`); granted `SELECT` to anonymous/public role per decision 7.

2. Relationships
- `users (role='trainer')` 1-to-many `slots` through `trainer_id`.
- `slots` 1-to-many `bookings`; each `bookings.user_id` references `users` (role `athlete`).
- `bookings` 1-to-many `booking_status_history`.
- `activity_logs` references any entity via `(entity_type, entity_id)`; `changed_by` optionally references `users`.
- `trainer_directory` derives from `users` and is read-only for clients.

3. Indexes
- `users_email_idx` on `users(email)` (unique, CITEXT).
- `users_role_active_idx` on `users(role, deleted_at)` to speed up trainer listing.
- `slots_trainer_start_idx` on `slots(trainer_id, start_at)` for calendar queries.
- `slots_time_idx` on `slots USING gist (tstzrange(start_at, end_at))` to accelerate overlap lookups for reporting.
- `bookings_slot_status_idx` on `bookings(slot_id, status)` to compute availability.
- `bookings_user_status_idx` on `bookings(user_id, status)` for upcoming sessions per user.
- `activity_logs_entity_idx` on `activity_logs(entity_type, entity_id, created_at DESC)`.
- `booking_status_history_booking_idx` on `booking_status_history(booking_id, changed_at DESC)`.

4. PostgreSQL Row-Level Security
- Enable RLS on `users`, `slots`, `bookings`, `activity_logs`.
- `users`
  - Policy `trainer_directory_public`: allow `SELECT` on `trainer_directory` view to `PUBLIC`.
  - Policy `self_access`: authenticated users may `SELECT/UPDATE` their own rows.
  - Policy `admin_all`: service role or `role = 'admin'` may `ALL`.
- `slots`
  - Policy `read_all_authenticated`: authenticated users can `SELECT`.
  - Policy `manage_own_slots`: trainers may `INSERT/UPDATE/DELETE` rows where `trainer_id = auth.uid()`.
  - Policy `service_maintenance`: service role may `ALL`.
- `bookings`
  - Policy `athlete_owns_booking`: users may `SELECT/UPDATE` rows with `user_id = auth.uid()`.
  - Policy `trainer_related_booking`: trainers may `SELECT` bookings for their slots via `USING (EXISTS (SELECT 1 FROM slots s WHERE s.id = slot_id AND s.trainer_id = auth.uid()))`.
  - Policy `create_booking`: authenticated non-trainers may `INSERT` with `user_id = auth.uid()`.
  - Policy `admin_all`: service role may `ALL`.
- `activity_logs`
  - Policy `self_or_admin`: allow `SELECT` where `changed_by = auth.uid()` OR user is admin.
  - Policy `related_slot_booking`: trainers can read logs tied to their slots/bookings via a join condition.
  - Inserts performed only by trusted service role.

5. Additional Notes
- Enum types:
  - `user_role`: `admin`, `trainer`, `athlete`.
  - `booking_status`: `reserved`, `cancelled`, `completed`.
  - `log_entity_type`: `user`, `slot`, `booking`.
  - `log_action_type`: `create`, `update`, `delete`, `status_auto_update`.
- Triggers:
  - `users_soft_delete_tg`: when `deleted_at` set, flag `is_anonymous = TRUE`, blank out PII, and update related bookings to label “anonymous user” (without dropping booking history).
  - `bookings_capacity_guard_tg`: `BEFORE INSERT` ensures `active_booking_count < capacity`; `BEFORE UPDATE` prevents late cancellation (<60 minutes to `start_at`) unless `role='admin'`.
  - `booking_status_history_tg`: `AFTER UPDATE` on `bookings` writing to `booking_status_history`.
  - `slots_delete_guard_tg`: `BEFORE DELETE` raises exception if future bookings exist.
  - `trainer_directory_refresh_tg`: keeps `trainer_directory` view/table in sync with `users`.
- Availability counts computed via aggregation (`SELECT capacity - COUNT(*) FROM bookings WHERE status='reserved'`) to avoid denormalized columns.
- All timestamps stored as `TIMESTAMPTZ` in server timezone per PRD, with UI messaging to indicate timezone.
- Consider partitioning `activity_logs` by month once volume grows; current design keeps single table with indexes sufficient for MVP.

