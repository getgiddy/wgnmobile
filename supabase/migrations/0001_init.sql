-- WGN Mobile initial schema
-- Content tables are world-readable; user tables are owner-only via RLS.

create type sermon_kind as enum ('audio', 'video', 'series');
create type event_cta as enum ('register', 'remind', 'volunteer');
create type prayer_status as enum ('received', 'prayed');

-- ---------------------------------------------------------------------------
-- Content
-- ---------------------------------------------------------------------------

create table sermons (
  id bigint generated always as identity primary key,
  title text not null,
  short_title text not null,
  series text not null,
  speaker text not null,
  kind sermon_kind not null,
  preached_on date not null,
  duration_secs int not null,
  size_bytes bigint,
  audio_path text,
  youtube_id text,
  artwork_path text,
  scripture text,
  scripture_ref text,
  created_at timestamptz not null default now()
);

create table devotionals (
  id bigint generated always as identity primary key,
  for_date date not null unique,
  title text not null,
  verse text not null,
  verse_ref text not null,
  tag text not null,
  body text[] not null default '{}',
  prayer text,
  image_path text,
  created_at timestamptz not null default now()
);

create table events (
  id bigint generated always as identity primary key,
  name text not null,
  starts_at timestamptz not null,
  location text not null,
  blurb text not null,
  capacity int,
  cta_type event_cta not null default 'register',
  spots_note text,
  flyer_path text,
  created_at timestamptz not null default now()
);

create table testimonies (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete set null,
  display_name text not null,
  initials text not null,
  location_tag text not null,
  category text not null,
  body text not null,
  amens_base int not null default 0,
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table journal_articles (
  id bigint generated always as identity primary key,
  issue_no int not null,
  title text not null,
  dek text not null,
  read_mins int not null,
  body text,
  cover_path text,
  published_at date not null default current_date
);

create table updates (
  id bigint generated always as identity primary key,
  title text not null,
  body text not null,
  published_at date not null default current_date
);

create table broadcast_platforms (
  id bigint generated always as identity primary key,
  kind text not null, -- TV | FM | WEB
  name text not null,
  schedule_text text not null,
  url text,
  sort_order int not null default 0
);

create table app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- User-owned
-- ---------------------------------------------------------------------------

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  branch text,
  member_code text unique,
  created_at timestamptz not null default now()
);

create table sermon_likes (
  user_id uuid not null references auth.users (id) on delete cascade,
  sermon_id bigint not null references sermons (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, sermon_id)
);

create table saved_devotionals (
  user_id uuid not null references auth.users (id) on delete cascade,
  devotional_id bigint not null references devotionals (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, devotional_id)
);

create table event_registrations (
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id bigint not null references events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create table testimony_amens (
  user_id uuid not null references auth.users (id) on delete cascade,
  testimony_id bigint not null references testimonies (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, testimony_id)
);

create table playback_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  sermon_id bigint not null references sermons (id) on delete cascade,
  position_secs int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, sermon_id)
);

create table devotional_reads (
  user_id uuid not null references auth.users (id) on delete cascade,
  for_date date not null,
  read_at timestamptz not null default now(),
  primary key (user_id, for_date)
);

create table prayer_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  tags text[] not null default '{}',
  body text not null,
  anonymous boolean not null default false,
  status prayer_status not null default 'received',
  created_at timestamptz not null default now()
);

-- Auto-create a profile row (with a member code) for every new user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, member_code)
  values (
    new.id,
    new.email,
    'WGN-' || lpad((floor(random() * 9000) + 1000)::int::text, 4, '0')
      || '-' || upper(substr(new.id::text, 1, 2))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profile email in sync when an anonymous user links an email identity.
create or replace function public.handle_user_updated()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_updated
  after update of email on auth.users
  for each row execute function public.handle_user_updated();

-- ---------------------------------------------------------------------------
-- Grants (hosted Supabase grants these by default; local PG17 image doesn't).
-- RLS below is what actually protects rows.
-- ---------------------------------------------------------------------------

grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table sermons enable row level security;
alter table devotionals enable row level security;
alter table events enable row level security;
alter table testimonies enable row level security;
alter table journal_articles enable row level security;
alter table updates enable row level security;
alter table broadcast_platforms enable row level security;
alter table app_config enable row level security;
alter table profiles enable row level security;
alter table sermon_likes enable row level security;
alter table saved_devotionals enable row level security;
alter table event_registrations enable row level security;
alter table testimony_amens enable row level security;
alter table playback_progress enable row level security;
alter table devotional_reads enable row level security;
alter table prayer_requests enable row level security;

-- Content: readable by everyone, written only via dashboard/service role.
create policy "content read" on sermons for select using (true);
create policy "content read" on devotionals for select using (true);
create policy "content read" on events for select using (true);
create policy "content read" on journal_articles for select using (true);
create policy "content read" on updates for select using (true);
create policy "content read" on broadcast_platforms for select using (true);
create policy "content read" on app_config for select using (true);

-- Testimonies: only approved ones are public; users may submit (unapproved)
-- and see their own submissions.
create policy "approved or own read" on testimonies
  for select using (approved or user_id = (select auth.uid()));
create policy "submit own" on testimonies
  for insert with check (user_id = (select auth.uid()) and not approved);

create policy "own profile read" on profiles
  for select using (id = (select auth.uid()));
create policy "own profile update" on profiles
  for update using (id = (select auth.uid()));

create policy "own rows" on sermon_likes
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on saved_devotionals
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on event_registrations
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on testimony_amens
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on playback_progress
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on devotional_reads
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own read" on prayer_requests
  for select using (user_id = (select auth.uid()));
create policy "own insert" on prayer_requests
  for insert with check (user_id = (select auth.uid()));

-- Amen counts need to be visible on public testimonies without exposing who
-- amen'd: expose an aggregate view instead of the raw table.
create view testimony_amen_counts
  with (security_invoker = off) as
  select testimony_id, count(*)::int as amens
  from testimony_amens
  group by testimony_id;
grant select on testimony_amen_counts to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Storage buckets (public read)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public) values
  ('sermon-audio', 'sermon-audio', true),
  ('artwork', 'artwork', true),
  ('devotional-images', 'devotional-images', true),
  ('event-flyers', 'event-flyers', true),
  ('journal-covers', 'journal-covers', true);
