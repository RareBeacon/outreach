-- Initial production schema for the self-hosted outreach platform.
-- MVP excludes SMTP verification. External verification providers can be added later.

create extension if not exists pgcrypto;

do $$ begin
  create type public.lead_status as enum (
    'valid',
    'risky',
    'catch_all',
    'invalid',
    'duplicate',
    'unknown'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.campaign_status as enum (
    'draft',
    'scheduled',
    'running',
    'paused',
    'completed',
    'stopped',
    'archived'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.queue_status as enum (
    'queued',
    'locked',
    'sending',
    'sent',
    'failed',
    'skipped',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.verification_provider as enum (
    'local',
    'zerobounce',
    'neverbounce',
    'bouncer'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.email_event_type as enum (
    'queued',
    'sent',
    'failed',
    'bounced',
    'replied',
    'skipped'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.gmail_connection_status as enum (
    'connected',
    'disconnected',
    'expired',
    'error'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.inbox_thread_status as enum (
    'unread',
    'read',
    'archived'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.inbox_message_direction as enum (
    'inbound',
    'outbound'
  );
exception when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  avatar_url text,
  timezone text not null default 'Africa/Lagos',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gmail_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  gmail_email text not null,
  encrypted_refresh_token text not null,
  scopes text[] not null default '{}',
  status public.gmail_connection_status not null default 'connected',
  last_token_refresh_at timestamptz,
  last_sync_at timestamptz,
  history_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, gmail_email)
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  first_name text,
  last_name text,
  company text,
  website text,
  email text not null,
  normalized_email text generated always as (lower(btrim(email))) stored,
  phone text,
  industry text,

  custom_fields jsonb not null default '{}',

  status public.lead_status not null default 'unknown',
  confidence_score integer not null default 0 check (confidence_score >= 0 and confidence_score <= 100),

  last_verified_at timestamptz,
  verification_provider public.verification_provider,
  verification_details jsonb not null default '{}',

  source text,
  notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, normalized_email)
);

create table if not exists public.lead_imports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text,
  total_rows integer not null default 0,
  inserted_count integer not null default 0,
  duplicate_count integer not null default 0,
  invalid_count integer not null default 0,
  error_count integer not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.lead_import_columns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  import_id uuid not null references public.lead_imports(id) on delete cascade,
  original_column text not null,
  variable_key text not null,
  is_standard_field boolean not null default false,
  created_at timestamptz not null default now(),
  unique (import_id, original_column),
  unique (import_id, variable_key)
);

create table if not exists public.lead_variable_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  variable_key text not null,
  original_column text,
  source text not null default 'csv',
  is_standard_field boolean not null default false,
  first_seen_import_id uuid references public.lead_imports(id) on delete set null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, variable_key)
);

create table if not exists public.lead_import_rows (
  id uuid primary key default gen_random_uuid(),
  import_id uuid not null references public.lead_imports(id) on delete cascade,
  row_number integer not null,
  raw_data jsonb not null,
  status text not null,
  error_message text,
  lead_id uuid references public.leads(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

create table if not exists public.lead_tags (
  lead_id uuid not null references public.leads(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (lead_id, tag_id)
);

create table if not exists public.lead_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lead_list_members (
  list_id uuid not null references public.lead_lists(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (list_id, lead_id)
);

create table if not exists public.email_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  email text not null,
  normalized_email text generated always as (lower(btrim(email))) stored,
  provider public.verification_provider not null,
  status public.lead_status not null,
  confidence_score integer not null check (confidence_score >= 0 and confidence_score <= 100),

  syntax_valid boolean,
  domain_valid boolean,
  mx_valid boolean,
  is_disposable boolean,
  is_duplicate boolean,
  is_catch_all boolean,

  details jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.email_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  subject text not null,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  gmail_connection_id uuid references public.gmail_connections(id) on delete set null,

  name text not null,
  status public.campaign_status not null default 'draft',

  template_id uuid references public.email_templates(id) on delete set null,

  subject_snapshot text,
  body_snapshot text,

  send_delay_seconds integer not null default 120 check (send_delay_seconds > 0),
  daily_send_limit integer not null default 100 check (daily_send_limit > 0),
  hourly_send_limit integer not null default 20 check (hourly_send_limit > 0),
  random_delay_min_seconds integer not null default 30 check (random_delay_min_seconds >= 0),
  random_delay_max_seconds integer not null default 180 check (random_delay_max_seconds >= 0),
  working_hours_start time not null default '09:00',
  working_hours_end time not null default '17:00',
  working_days integer[] not null default '{1,2,3,4,5}',

  allow_risky boolean not null default false,
  allow_catch_all boolean not null default false,

  started_at timestamptz,
  paused_at timestamptz,
  completed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (random_delay_max_seconds >= random_delay_min_seconds),
  check (working_hours_end > working_hours_start)
);

create table if not exists public.campaign_leads (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,

  status text not null default 'pending',
  approved_risky boolean not null default false,
  approved_catch_all boolean not null default false,

  personalized_subject text,
  personalized_body text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (campaign_id, lead_id)
);

create table if not exists public.send_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  campaign_lead_id uuid not null references public.campaign_leads(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,

  status public.queue_status not null default 'queued',

  scheduled_for timestamptz not null,
  locked_at timestamptz,
  lock_expires_at timestamptz,

  attempt_count integer not null default 0,
  max_attempts integer not null default 3,

  last_error text,
  gmail_message_id text,
  gmail_thread_id text,

  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (campaign_id, lead_id)
);

create table if not exists public.email_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campaign_id uuid references public.campaigns(id) on delete set null,
  lead_id uuid references public.leads(id) on delete set null,
  send_queue_id uuid references public.send_queue(id) on delete set null,

  event_type public.email_event_type not null,
  gmail_message_id text,
  gmail_thread_id text,

  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.inbox_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  gmail_connection_id uuid references public.gmail_connections(id) on delete set null,
  campaign_id uuid references public.campaigns(id) on delete set null,
  lead_id uuid references public.leads(id) on delete set null,

  gmail_thread_id text not null,
  subject text,
  snippet text,
  status public.inbox_thread_status not null default 'unread',
  unread_count integer not null default 0,

  first_message_at timestamptz,
  last_message_at timestamptz,
  last_synced_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, gmail_thread_id)
);

create table if not exists public.inbox_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  inbox_thread_id uuid not null references public.inbox_threads(id) on delete cascade,

  gmail_message_id text not null,
  gmail_thread_id text not null,

  direction public.inbox_message_direction not null,
  from_email text,
  to_emails text[] not null default '{}',
  cc_emails text[] not null default '{}',

  subject text,
  snippet text,
  body_text text,
  body_html text,

  is_unread boolean not null default false,
  message_date timestamptz,

  created_at timestamptz not null default now(),

  unique (user_id, gmail_message_id)
);

create table if not exists public.gmail_sync_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  gmail_connection_id uuid not null references public.gmail_connections(id) on delete cascade,

  sync_type text not null,
  status text not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text,
  metadata jsonb not null default '{}'
);

create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,

  default_send_delay_seconds integer not null default 120 check (default_send_delay_seconds > 0),
  max_daily_sends integer not null default 100 check (max_daily_sends > 0),
  max_hourly_sends integer not null default 20 check (max_hourly_sends > 0),
  random_delay_min_seconds integer not null default 30 check (random_delay_min_seconds >= 0),
  random_delay_max_seconds integer not null default 180 check (random_delay_max_seconds >= 0),
  working_hours_start time not null default '09:00',
  working_hours_end time not null default '17:00',
  working_days integer[] not null default '{1,2,3,4,5}',

  reverify_after_days integer not null default 30 check (reverify_after_days > 0),

  block_invalid boolean not null default true,
  require_approval_for_risky boolean not null default true,
  require_approval_for_catch_all boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (random_delay_max_seconds >= random_delay_min_seconds),
  check (working_hours_end > working_hours_start)
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,

  action text not null,
  entity_type text,
  entity_id uuid,
  ip_address text,
  user_agent text,
  metadata jsonb not null default '{}',

  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_gmail_connections_updated_at on public.gmail_connections;
create trigger set_gmail_connections_updated_at before update on public.gmail_connections
for each row execute function public.set_updated_at();

drop trigger if exists set_leads_updated_at on public.leads;
create trigger set_leads_updated_at before update on public.leads
for each row execute function public.set_updated_at();

drop trigger if exists set_lead_lists_updated_at on public.lead_lists;
create trigger set_lead_lists_updated_at before update on public.lead_lists
for each row execute function public.set_updated_at();

drop trigger if exists set_email_templates_updated_at on public.email_templates;
create trigger set_email_templates_updated_at before update on public.email_templates
for each row execute function public.set_updated_at();

drop trigger if exists set_campaigns_updated_at on public.campaigns;
create trigger set_campaigns_updated_at before update on public.campaigns
for each row execute function public.set_updated_at();

drop trigger if exists set_campaign_leads_updated_at on public.campaign_leads;
create trigger set_campaign_leads_updated_at before update on public.campaign_leads
for each row execute function public.set_updated_at();

drop trigger if exists set_send_queue_updated_at on public.send_queue;
create trigger set_send_queue_updated_at before update on public.send_queue
for each row execute function public.set_updated_at();

drop trigger if exists set_inbox_threads_updated_at on public.inbox_threads;
create trigger set_inbox_threads_updated_at before update on public.inbox_threads
for each row execute function public.set_updated_at();

drop trigger if exists set_user_settings_updated_at on public.user_settings;
create trigger set_user_settings_updated_at before update on public.user_settings
for each row execute function public.set_updated_at();

create index if not exists idx_gmail_connections_user_id on public.gmail_connections(user_id);

create index if not exists idx_leads_user_id on public.leads(user_id);
create index if not exists idx_leads_user_status on public.leads(user_id, status);
create index if not exists idx_leads_user_company on public.leads(user_id, company);
create index if not exists idx_leads_user_industry on public.leads(user_id, industry);
create index if not exists idx_leads_custom_fields on public.leads using gin(custom_fields);

create index if not exists idx_lead_imports_user_id on public.lead_imports(user_id);
create index if not exists idx_lead_import_columns_user_id on public.lead_import_columns(user_id);
create index if not exists idx_lead_variable_keys_user_id on public.lead_variable_keys(user_id);

create index if not exists idx_tags_user_id on public.tags(user_id);
create index if not exists idx_lead_tags_tag_id on public.lead_tags(tag_id);

create index if not exists idx_lead_lists_user_id on public.lead_lists(user_id);
create index if not exists idx_lead_list_members_lead_id on public.lead_list_members(lead_id);

create index if not exists idx_email_verifications_user_id on public.email_verifications(user_id);
create index if not exists idx_email_verifications_lead_id on public.email_verifications(lead_id);

create index if not exists idx_email_templates_user_id on public.email_templates(user_id);

create index if not exists idx_campaigns_user_id on public.campaigns(user_id);
create index if not exists idx_campaigns_user_status on public.campaigns(user_id, status);

create index if not exists idx_campaign_leads_campaign_id on public.campaign_leads(campaign_id);
create index if not exists idx_campaign_leads_lead_id on public.campaign_leads(lead_id);

create index if not exists idx_send_queue_status_scheduled_for on public.send_queue(status, scheduled_for);
create index if not exists idx_send_queue_user_status on public.send_queue(user_id, status);
create index if not exists idx_send_queue_campaign_status on public.send_queue(campaign_id, status);
create index if not exists idx_send_queue_lock_expires_at on public.send_queue(lock_expires_at);

create index if not exists idx_email_events_campaign_id on public.email_events(campaign_id);
create index if not exists idx_email_events_lead_id on public.email_events(lead_id);
create index if not exists idx_email_events_event_type on public.email_events(event_type);
create index if not exists idx_email_events_created_at on public.email_events(created_at);

create index if not exists idx_inbox_threads_user_status on public.inbox_threads(user_id, status);
create index if not exists idx_inbox_threads_last_message_at on public.inbox_threads(last_message_at);
create index if not exists idx_inbox_messages_thread_id on public.inbox_messages(inbox_thread_id);
create index if not exists idx_inbox_messages_user_unread on public.inbox_messages(user_id, is_unread);

create index if not exists idx_gmail_sync_events_connection_id on public.gmail_sync_events(gmail_connection_id);
create index if not exists idx_audit_logs_user_id on public.audit_logs(user_id);
create index if not exists idx_audit_logs_created_at on public.audit_logs(created_at);

alter table public.profiles enable row level security;
alter table public.gmail_connections enable row level security;
alter table public.leads enable row level security;
alter table public.lead_imports enable row level security;
alter table public.lead_import_columns enable row level security;
alter table public.lead_variable_keys enable row level security;
alter table public.lead_import_rows enable row level security;
alter table public.tags enable row level security;
alter table public.lead_tags enable row level security;
alter table public.lead_lists enable row level security;
alter table public.lead_list_members enable row level security;
alter table public.email_verifications enable row level security;
alter table public.email_templates enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_leads enable row level security;
alter table public.send_queue enable row level security;
alter table public.email_events enable row level security;
alter table public.inbox_threads enable row level security;
alter table public.inbox_messages enable row level security;
alter table public.gmail_sync_events enable row level security;
alter table public.user_settings enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles_select_own" on public.profiles for select using (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "gmail_connections_own" on public.gmail_connections for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "leads_own" on public.leads for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "lead_imports_own" on public.lead_imports for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "lead_import_columns_own" on public.lead_import_columns for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "lead_variable_keys_own" on public.lead_variable_keys for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "lead_import_rows_own" on public.lead_import_rows for all
using (
  exists (
    select 1 from public.lead_imports
    where public.lead_imports.id = public.lead_import_rows.import_id
    and public.lead_imports.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.lead_imports
    where public.lead_imports.id = public.lead_import_rows.import_id
    and public.lead_imports.user_id = auth.uid()
  )
);

create policy "tags_own" on public.tags for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "lead_tags_own" on public.lead_tags for all
using (
  exists (
    select 1 from public.leads
    where public.leads.id = public.lead_tags.lead_id
    and public.leads.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.leads
    where public.leads.id = public.lead_tags.lead_id
    and public.leads.user_id = auth.uid()
  )
);

create policy "lead_lists_own" on public.lead_lists for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "lead_list_members_own" on public.lead_list_members for all
using (
  exists (
    select 1 from public.lead_lists
    where public.lead_lists.id = public.lead_list_members.list_id
    and public.lead_lists.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.lead_lists
    where public.lead_lists.id = public.lead_list_members.list_id
    and public.lead_lists.user_id = auth.uid()
  )
);

create policy "email_verifications_own" on public.email_verifications for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "email_templates_own" on public.email_templates for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "campaigns_own" on public.campaigns for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "campaign_leads_own" on public.campaign_leads for all
using (
  exists (
    select 1 from public.campaigns
    where public.campaigns.id = public.campaign_leads.campaign_id
    and public.campaigns.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.campaigns
    where public.campaigns.id = public.campaign_leads.campaign_id
    and public.campaigns.user_id = auth.uid()
  )
);

create policy "send_queue_own" on public.send_queue for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "email_events_own" on public.email_events for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "inbox_threads_own" on public.inbox_threads for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "inbox_messages_own" on public.inbox_messages for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "gmail_sync_events_own" on public.gmail_sync_events for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_settings_own" on public.user_settings for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "audit_logs_select_own" on public.audit_logs for select using (user_id = auth.uid());
