# REST API Plan

## 1. Resources
- `AuthSession` → Supabase Auth session and refresh token wrappers.
- `User` → `users` table; includes roles (`admin`, `trainer`, `athlete`), contact data,
  preferences, lifecycle flags.
- `TrainerDirectoryEntry` → `trainer_directory` view/table with read-only trainer info.
- `Slot` → `slots` table; trainer-owned availability windows.
- `Booking` → `bookings` table; connects athletes to slots with lifecycle metadata.
- `BookingStatusHistory` → `booking_status_history` table; audit trail for booking
  transitions.
- `ActivityLog` → `activity_logs` table; cross-entity change history.
- `AutomationJob` (virtual) → operational endpoints for scheduled tasks (e.g.,
  booking status sync).

## 2. Endpoints
All list endpoints support `page` (default 1), `page_size` (default 50, max 200),
`sort` (comma-separated `<field>:asc|desc`), and `include_total=true` for count
metadata. All timestamps use ISO 8601 with timezone.

### 2.2 Trainer Directory & Calendar

#### GET /trainers
- Description: Public trainer listing sourced from `trainer_directory`.
- Query params: `search`, `page`, `page_size`, `sort` (default `display_name:asc`).
- Response sample:
```json
{
  "data": [
    {
      "trainerId": "uuid",
      "displayName": "Anna Kowalska",
      "contactEmail": "anna@fit.com",
      "contactPhone": "+48123456789",
      "updatedAt": "2025-12-01T12:00:00Z"
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 120
}
```
- Errors: 429 rate limit (public endpoint protection).

#### GET /trainers/{trainerId}
- Description: Detailed trainer profile (requires auth).
- Response: Trainer metadata, aggregated stats (slots count, next available slot).
- Errors: 404 trainer missing or soft-deleted.

#### GET /trainers/{trainerId}/calendar
- Description: Weekly calendar view with slot statuses and remaining capacity.
- Query params:
  - `week_start` (ISO Monday, default current week).
  - `weeks` (1–4, default 1).
  - `includePast=false|true`.
- Response:
```json
{
  "trainerId": "uuid",
  "timezone": "UTC",
  "weeks": [
    {
      "weekStart": "2025-12-01",
      "slots": [
        {
          "slotId": "uuid",
          "startAt": "2025-12-02T08:00:00Z",
          "endAt": "2025-12-02T09:00:00Z",
          "capacity": 3,
          "reserved": 1,
          "status": "available"
        }
      ]
    }
  ]
}
```
- Errors: 400 invalid date range, 404 trainer not found.

### 2.3 Slots

#### POST /slots
- Description: Trainer creates an availability slot.
- Request body:
```json
{
  "startAt": "2025-12-05T10:00:00Z",
  "endAt": "2025-12-05T11:00:00Z",
  "capacity": 2,
  "notes": "Bring water"
}
```
- Response (201 Created): Slot object with `durationMinutes`, `status`.
- Errors: 400 invalid window, 403 role not trainer, 422 capacity/duration out of range.

#### GET /slots
- Description: Search slots across trainers (auth required).
- Query params: `trainer_id`, `starts_after`, `starts_before`, `status`, `include_cancelled`,
  `capacity_gte`, pagination defaults.
- Response: `{ "data": [Slot...], "page": 1, ... }`.

#### GET /slots/{slotId}
- Description: Fetch slot plus aggregated booking counts for authorized viewer.
- Errors: 404 slot missing or unauthorized.

#### PATCH /slots/{slotId}
- Description: Trainer updates slot (time or capacity) before completion.
- Request body allows `startAt`, `endAt`, `capacity`, `notes`.
- Response: Updated slot.
- Errors: 400 overlap validations (client-side), 403 not owner, 409 slot started or bookings conflict.

#### DELETE /slots/{slotId}
- Description: Remove slot with no upcoming bookings.
- Success: 204 No Content.
- Errors: 403 not owner, 409 slot has future bookings, 410 slot already past/locked.

#### GET /slots/{slotId}/bookings
- Description: Trainer view of bookings for that slot.
- Query params: `status`, `includeHistory`.
- Response: list of booking summaries.
- Errors: 403 trainer mismatch.

### 2.4 Bookings

#### POST /slots/{slotId}/bookings
- Description: Athlete reserves a seat in the slot.
- Request body (optional metadata):
```json
{ "notes": "Need mat", "autoProcessed": false }
```
- Response (201 Created):
```json
{
  "bookingId": "uuid",
  "slotId": "uuid",
  "userId": "uuid",
  "status": "reserved",
  "statusChangedAt": "2025-12-03T09:00:00Z"
}
```
- Errors: 400 already booked, 403 trainers cannot book, 409 capacity reached, 410 slot started.

#### GET /bookings
- Description: List bookings for current user (role-aware).
- Query params:
  - `scope=self|trainer|admin` (defaults by role).
  - `status` (multi).
  - `starts_after`, `starts_before`.
  - `auto_processed=true|false`.
- Response: bookings with embedded slot summary.

#### GET /bookings/{bookingId}
- Description: Detailed booking view with slot + trainer contact.
- Errors: 404 no access.

#### POST /bookings/{bookingId}:cancel
- Description: Cancel booking if ≥60 min before slot start; handles reason logging.
- Request body:
```json
{ "reason": "Flu symptoms" }
```
- Response: Updated booking with `status="cancelled"`.
- Errors: 400 reason missing, 403 not owner/trainer/admin, 409 cancellation window elapsed.

#### GET /bookings/upcoming
- Description: Convenience endpoint returning authenticated user’s chronological upcoming trainings.
- Query params: `limit` (default 10, max 50).
- Response: array of booking cards.

### 2.5 Booking Status History

#### GET /bookings/{bookingId}/status-history
- Description: Ordered list of status transitions.
- Response:
```json
{
  "bookingId": "uuid",
  "history": [
    {
      "previousStatus": "reserved",
      "currentStatus": "cancelled",
      "changedAt": "2025-12-03T11:00:00Z",
      "changedBy": "uuid",
      "autoProcessed": false
    }
  ]
}
```
- Errors: 403 unauthorized, 404 booking missing.

### 2.6 Activity Logs

#### GET /activity-logs
- Description: Filterable audit trail for admins/trainers (trainer scope limited to own slots/bookings).
- Query params: `entity_type`, `entity_id`, `action`, `changed_by`, `since`, `until`.
- Response: list ordered by `created_at DESC`.
- Errors: 403 insufficient role.

#### GET /activity-logs/{logId}
- Description: Fetch specific log entry including `changedFields`.
- Errors: 403 unauthorized, 404 missing.

### 2.7 Automation Jobs

#### POST /jobs/booking-status-sync
- Description: Admin/system trigger that processes overdue slots and sets bookings to `completed`.
- Request body: `{ "until": "2025-12-03T23:59:59Z" }` (optional).
- Success: 202 Accepted with job summary.
- Errors: 403 unauthorized (requires admin/service role).

#### GET /jobs/booking-status-sync/last-run
- Description: Observability for last automation execution.
- Response: `{ "lastRunAt": "...", "processedBookings": 42, "durationMs": 350 }`.

## 3. Authentication and Authorization
- **Mechanism**: Supabase Auth JWT (access + refresh); JWT includes `sub` (user id) and
  `role` claim mirrored from `users.role`.
- **Transport**: Bearer token in `Authorization` header; refresh via `/auth/login`.
- **RLS alignment**: Every write hits Supabase Postgres with policies:
  - Trainers restricted to `slots.trainer_id = auth.uid()`.
  - Athletes limited to their bookings; trainers read bookings referencing their slots.
  - Admin/service role bypasses restrictions for support tooling.
- **Session expiry**: Access tokens 1 hour, refresh 30 days; forced logout after account
  deletion.
- **Rate limiting**: API gateway enforces 60 rpm/user on authenticated routes, 30 rpm/IP
  on public trainer directory.

## 4. Validation and Business Logic

### User
- Email unique (case-insensitive); enforced before calling Supabase.
- Trainer registration requires `contactEmail` or `contactPhone`.
- Soft delete sets `isAnonymous=true`, nulls PII, cascades booking relabeling.

### Slot
- `endAt` must be after `startAt`; duration defaults to 60 minutes; allowed range 30–240.
- Capacity 1–20; cannot be negative.
- Trainers may overlap slots; API warns (409) only if `max_overlap_per_trainer` policy
  changes in future.
- Deletion blocked when future bookings exist (pre-check + DB trigger).
- `notes` optional, trimmed to 500 chars.

### Booking
- One active booking per `(slotId, userId)`; API checks before insert.
- Creation blocked once `slot.startAt <= now()` or when reserved count equals capacity.
- Cancellation allowed only if `slot.startAt - now() >= 60 minutes` unless admin role;
  endpoint enforces guard prior to hitting trigger.
- `status` transitions allowed: `reserved -> cancelled/completed`, `cancelled` is terminal.
- Automatic completion handled via job; manual completion available to trainers/admins.

### Booking Status History
- Append-only; API reads only. Each entry captures actor and `autoProcessed` flag for PRD
  analytics requirements.

### Activity Logs
- `changedFields` must contain at least one key; server rejects empty objects.
- Logs created by service role on every slot/booking mutation, including auto jobs.

### Automation
- Background job updates bookings whose slot end is past and status still `reserved`;
  logs entries with `log_action_type = status_auto_update`.

### Error Handling
- All errors follow `{ "error": { "code": "string", "message": "string" } }`.
- Common codes: `VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `CONFLICT`,
  `RESOURCE_NOT_FOUND`, `RATE_LIMITED`.

### Localization & Time Zone
- API returns server timezone identifier (UTC) in calendar responses per PRD.
- Client displays note referencing timezone string.


