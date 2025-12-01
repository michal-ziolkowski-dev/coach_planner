-- migration: 20251124202451_initial_schema.sql
-- purpose: bootstrap core coach planner schema, roles, policies, and triggers
-- details: creates enums, tables, constraints, indexes, triggers, and rls policies for users, slots, bookings, activity logs, booking history, and trainer directory

begin;

-- ensure required extensions exist for uuid generation, citext comparisons, and gist indexes.
create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists btree_gist;

-- domain enums representing roles, booking statuses, and logging metadata.
create type public.user_role as enum ('admin', 'trainer', 'athlete');
create type public.booking_status as enum ('reserved', 'cancelled', 'completed');
create type public.log_entity_type as enum ('user', 'slot', 'booking');
create type public.log_action_type as enum ('create', 'update', 'delete', 'status_auto_update');

create table public.users (
    id uuid primary key references auth.users (id) on delete cascade,
    email citext not null unique,
    password_hash text not null,
    first_name text not null,
    last_name text,
    role public.user_role not null default 'athlete',
    contact_email citext,
    contact_phone text,
    preferences jsonb not null default '{}'::jsonb,
    is_anonymous boolean not null default false,
    deleted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint users_trainer_contact_chk check (
        role <> 'trainer' or contact_email is not null or contact_phone is not null
    )
);

-- availability slots authored by trainers.
create table public.slots (
    id uuid primary key default gen_random_uuid(),
    trainer_id uuid not null references public.users (id),
    start_at timestamptz not null,
    end_at timestamptz not null,
    duration_minutes smallint not null default 60 check (duration_minutes between 30 and 240),
    capacity smallint not null default 1 check (capacity between 1 and 20),
    notes text,
    cancelled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint slots_time_chk check (end_at > start_at)
);

-- booking records created by athletes against slots.
create table public.bookings (
    id uuid primary key default gen_random_uuid(),
    slot_id uuid not null references public.slots (id) on delete cascade,
    user_id uuid not null references public.users (id),
    status public.booking_status not null default 'reserved',
    status_changed_at timestamptz not null default now(),
    auto_processed boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint bookings_unique_slot_user unique (slot_id, user_id)
);

-- audit history for application events.
create table public.activity_logs (
    id uuid primary key default gen_random_uuid(),
    entity_type public.log_entity_type not null,
    entity_id uuid not null,
    action public.log_action_type not null,
    changed_by uuid references public.users (id),
    changed_by_role public.user_role,
    changed_fields jsonb not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    constraint activity_logs_changed_fields_chk check (
        jsonb_typeof(changed_fields) = 'object' and changed_fields <> '{}'::jsonb
    )
);

-- booking status transitions stored separately for analytics.
create table public.booking_status_history (
    id bigserial primary key,
    booking_id uuid not null references public.bookings (id) on delete cascade,
    previous_status public.booking_status not null,
    current_status public.booking_status not null,
    changed_at timestamptz not null default now(),
    changed_by uuid references public.users (id),
    auto_processed boolean not null default false
);

-- trainer directory table exposed to public consumers through rls policies.
create table public.trainer_directory (
    trainer_id uuid primary key references public.users (id),
    display_name text not null,
    contact_email citext,
    contact_phone text,
    updated_at timestamptz not null default now()
);

-- synchronize rows from auth.users into public.users so supabase auth remains source of truth.
create or replace function public.sync_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    meta jsonb;
    prefs jsonb;
    requested_role text;
    resolved_role public.user_role := 'athlete';
    first_name_value text;
    last_name_value text;
    contact_email_value citext;
    contact_phone_value text;
    is_anonymous_value boolean;
begin
    if tg_op = 'DELETE' then
        delete from public.users where id = old.id;
        return old;
    end if;

    meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
    prefs := coalesce(meta->'preferences', '{}'::jsonb);
    requested_role := meta->>'role';

    if requested_role in ('admin', 'trainer', 'athlete') then
        resolved_role := requested_role::public.user_role;
    end if;

    first_name_value := coalesce(nullif(meta->>'first_name', ''), 'anonymous');
    last_name_value := nullif(meta->>'last_name', '');
    contact_email_value := nullif(meta->>'contact_email', '');
    contact_phone_value := nullif(meta->>'contact_phone', '');
    is_anonymous_value := coalesce((meta->>'is_anonymous')::boolean, false);

    if jsonb_typeof(prefs) is distinct from 'object' then
        prefs := '{}'::jsonb;
    end if;

    insert into public.users (
        id,
        email,
        password_hash,
        first_name,
        last_name,
        role,
        contact_email,
        contact_phone,
        preferences,
        is_anonymous,
        deleted_at,
        created_at,
        updated_at
    ) values (
        new.id,
        new.email,
        coalesce(new.encrypted_password, ''),
        first_name_value,
        last_name_value,
        resolved_role,
        contact_email_value,
        contact_phone_value,
        prefs,
        is_anonymous_value,
        new.deleted_at,
        new.created_at,
        new.updated_at
    )
    on conflict (id) do update
        set email = excluded.email,
            password_hash = excluded.password_hash,
            first_name = excluded.first_name,
            last_name = excluded.last_name,
            role = excluded.role,
            contact_email = excluded.contact_email,
            contact_phone = excluded.contact_phone,
            preferences = excluded.preferences,
            is_anonymous = excluded.is_anonymous,
            deleted_at = excluded.deleted_at,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at;

    return new;
end;
$$;

create trigger auth_users_sync
    after insert or update on auth.users
    for each row
    execute function public.sync_auth_user();

create trigger auth_users_delete
    after delete on auth.users
    for each row
    execute function public.sync_auth_user();

-- helper function to surface admin role checks within policies and triggers.
create or replace function public.is_admin(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_user_id is null then
        return false;
    end if;

    return exists (
        select 1
        from public.users u
        where u.id = p_user_id
          and u.role = 'admin'
          and u.deleted_at is null
    );
end;
$$;

grant execute on function public.is_admin(uuid) to public;

-- helper function to evaluate whether a user is a trainer.
create or replace function public.is_trainer(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_user_id is null then
        return false;
    end if;

    return exists (
        select 1
        from public.users u
        where u.id = p_user_id
          and u.role = 'trainer'
          and u.deleted_at is null
    );
end;
$$;

grant execute on function public.is_trainer(uuid) to public;

-- generic trigger function to keep updated_at fresh.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

-- trigger updating users.updated_at on modifications.
create trigger users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

-- trigger updating slots.updated_at on modifications.
create trigger slots_set_updated_at
before update on public.slots
for each row
execute function public.set_updated_at();

-- trigger updating bookings.updated_at on modifications.
create trigger bookings_set_updated_at
before update on public.bookings
for each row
execute function public.set_updated_at();

-- soft delete trigger for users to anonymize pii and keep history intact.
create or replace function public.users_soft_delete_tg()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.deleted_at is not null and old.deleted_at is null then
        new.is_anonymous := true;
        new.first_name := 'anonymous';
        new.last_name := null;
        new.contact_email := null;
        new.contact_phone := null;
        new.preferences := '{}'::jsonb;
        new.email := 'deleted-' || new.id::text || '@example.invalid';
        new.password_hash := crypt(gen_random_uuid()::text, gen_salt('bf'));
    end if;

    return new;
end;
$$;

create trigger users_soft_delete
before update on public.users
for each row
when (new.deleted_at is not null and old.deleted_at is distinct from new.deleted_at)
execute function public.users_soft_delete_tg();

-- guard bookings from exceeding capacity and enforce late cancellation rule.
create or replace function public.bookings_capacity_guard_tg()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    slot_capacity smallint;
    slot_start timestamptz;
    active_count integer;
begin
    select s.capacity, s.start_at
    into slot_capacity, slot_start
    from public.slots s
    where s.id = new.slot_id
    for update;

    if slot_capacity is null then
        raise exception 'slot % does not exist', new.slot_id;
    end if;

    select count(*)
    into active_count
    from public.bookings b
    where b.slot_id = new.slot_id
      and b.status <> 'cancelled'
      and (tg_op <> 'update' or b.id <> old.id);

    if new.status <> 'cancelled' and active_count >= slot_capacity then
        raise exception 'slot % is at capacity', new.slot_id;
    end if;

    if tg_op = 'insert' then
        new.status_changed_at := coalesce(new.status_changed_at, now());
    elsif tg_op = 'update' and old.status <> new.status then
        new.status_changed_at := now();
    end if;

    if tg_op = 'update'
       and old.status <> 'cancelled'
       and new.status = 'cancelled'
       and slot_start - now() < interval '60 minutes'
       and not public.is_admin(auth.uid()) then
        raise exception 'cancellations must occur at least 60 minutes before start';
    end if;

    return new;
end;
$$;

create trigger bookings_capacity_guard
before insert or update on public.bookings
for each row
execute function public.bookings_capacity_guard_tg();

-- capture status transitions for downstream analytics.
create or replace function public.booking_status_history_tg()
returns trigger
language plpgsql
as $$
begin
    if old.status = new.status then
        return new;
    end if;

    insert into public.booking_status_history (
        booking_id,
        previous_status,
        current_status,
        changed_at,
        changed_by,
        auto_processed
    ) values (
        new.id,
        old.status,
        new.status,
        now(),
        auth.uid(),
        new.auto_processed
    );

    return new;
end;
$$;

create trigger booking_status_history
after update on public.bookings
for each row
when (old.status is distinct from new.status)
execute function public.booking_status_history_tg();

-- prevent slot deletion when active future bookings exist.
create or replace function public.slots_delete_guard_tg()
returns trigger
language plpgsql
as $$
begin
    if exists (
        select 1
        from public.bookings b
        join public.slots s on s.id = b.slot_id
        where b.slot_id = old.id
          and b.status <> 'cancelled'
          and s.start_at > now()
    ) then
        raise exception 'cannot delete slot % with future bookings', old.id;
    end if;

    return old;
end;
$$;

create trigger slots_delete_guard
before delete on public.slots
for each row
execute function public.slots_delete_guard_tg();

-- keep trainer directory synchronized with trainer profile updates.
create or replace function public.trainer_directory_refresh_tg()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.role = 'trainer' and new.deleted_at is null then
        insert into public.trainer_directory (trainer_id, display_name, contact_email, contact_phone, updated_at)
        values (
            new.id,
            coalesce(new.first_name || ' ' || coalesce(new.last_name, ''), 'trainer'),
            new.contact_email,
            new.contact_phone,
            now()
        )
        on conflict (trainer_id) do update
        set display_name = excluded.display_name,
            contact_email = excluded.contact_email,
            contact_phone = excluded.contact_phone,
            updated_at = excluded.updated_at;
    else
        delete from public.trainer_directory td where td.trainer_id = new.id;
    end if;

    return new;
end;
$$;

create trigger trainer_directory_refresh
after insert or update on public.users
for each row
execute function public.trainer_directory_refresh_tg();

-- indexes aligned with query workloads described in the data plan.
create index if not exists users_role_active_idx on public.users (role, deleted_at);
create index if not exists slots_trainer_start_idx on public.slots (trainer_id, start_at);
create index if not exists slots_time_idx on public.slots using gist (tstzrange(start_at, end_at));
create index if not exists bookings_slot_status_idx on public.bookings (slot_id, status);
create index if not exists bookings_user_status_idx on public.bookings (user_id, status);
create index if not exists activity_logs_entity_idx on public.activity_logs (entity_type, entity_id, created_at desc);
create index if not exists booking_status_history_booking_idx on public.booking_status_history (booking_id, changed_at desc);

-- enable row level security globally to enforce policies.
alter table public.users enable row level security;
alter table public.slots enable row level security;
alter table public.bookings enable row level security;
alter table public.activity_logs enable row level security;
alter table public.booking_status_history enable row level security;
alter table public.trainer_directory enable row level security;

-- users policies
create policy users_self_select_authenticated
    on public.users
    for select
    to authenticated
    using (id = auth.uid());

create policy users_self_update_authenticated
    on public.users
    for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());

create policy users_admin_select
    on public.users
    for select
    to authenticated
    using (public.is_admin(auth.uid()));

create policy users_admin_update
    on public.users
    for update
    to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));

-- slots policies
create policy slots_read_authenticated
    on public.slots
    for select
    to authenticated
    using (true);

create policy slots_trainer_insert
    on public.slots
    for insert
    to authenticated
    with check (trainer_id = auth.uid() and public.is_trainer(auth.uid()));

create policy slots_trainer_update
    on public.slots
    for update
    to authenticated
    using (trainer_id = auth.uid())
    with check (trainer_id = auth.uid());

create policy slots_trainer_delete
    on public.slots
    for delete
    to authenticated
    using (trainer_id = auth.uid());

create policy slots_admin_all
    on public.slots
    for all
    to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));

-- bookings policies
create policy bookings_self_select
    on public.bookings
    for select
    to authenticated
    using (user_id = auth.uid());

create policy bookings_self_update
    on public.bookings
    for update
    to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

create policy bookings_create_athlete
    on public.bookings
    for insert
    to authenticated
    with check (
        user_id = auth.uid()
        and not public.is_trainer(auth.uid())
    );

create policy bookings_trainer_select
    on public.bookings
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.slots s
            where s.id = bookings.slot_id
              and s.trainer_id = auth.uid()
        )
    );

create policy bookings_admin_all
    on public.bookings
    for all
    to authenticated
    using (public.is_admin(auth.uid()))
    with check (public.is_admin(auth.uid()));

-- activity_logs policies
create policy activity_logs_self_or_admin
    on public.activity_logs
    for select
    to authenticated
    using (
        public.is_admin(auth.uid())
        or changed_by = auth.uid()
    );

create policy activity_logs_trainer_related
    on public.activity_logs
    for select
    to authenticated
    using (
        case entity_type
            when 'slot' then exists (
                select 1 from public.slots s
                where s.id = activity_logs.entity_id
                  and s.trainer_id = auth.uid()
            )
            when 'booking' then exists (
                select 1 from public.bookings b
                join public.slots s on s.id = b.slot_id
                where b.id = activity_logs.entity_id
                  and s.trainer_id = auth.uid()
            )
            else false
        end
    );

create policy activity_logs_insert_service
    on public.activity_logs
    for insert
    to service_role
    with check (true);

-- booking_status_history policies (read-only outside admin/service)
create policy booking_status_history_self
    on public.booking_status_history
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.bookings b
            where b.id = booking_status_history.booking_id
              and b.user_id = auth.uid()
        )
    );

create policy booking_status_history_trainer
    on public.booking_status_history
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.bookings b
            join public.slots s on s.id = b.slot_id
            where b.id = booking_status_history.booking_id
              and s.trainer_id = auth.uid()
        )
    );

create policy booking_status_history_admin
    on public.booking_status_history
    for select
    to authenticated
    using (public.is_admin(auth.uid()));

create policy booking_status_history_insert_authenticated
    on public.booking_status_history
    for insert
    to authenticated
    with check (true);

create policy booking_status_history_insert_service
    on public.booking_status_history
    for insert
    to service_role
    with check (true);

-- trainer directory policies granting read-only public visibility.
create policy trainer_directory_select_authenticated
    on public.trainer_directory
    for select
    to authenticated
    using (true);

create policy trainer_directory_select_anon
    on public.trainer_directory
    for select
    to anon
    using (true);

create policy trainer_directory_maintain_service
    on public.trainer_directory
    for all
    to service_role
    using (true)
    with check (true);

commit;
