-- Guest → account merge, for the Google / Apple sign-in paths.
--
-- The email path in the auth sheet upgrades the anonymous session in place
-- with `updateUser`, so the user id never changes and nothing has to move.
-- An ID-token sign-in cannot do that: gotrue has no "link this ID token to
-- the session I already hold" call, so the user lands on a *different* id and
-- the guest's streak, saves, registrations, prayers and testimonies would be
-- stranded on an abandoned account. That would quietly break the promise the
-- app makes on its own sign-up sheet ("keeps your streak, saves and
-- registrations").
--
-- Moving rows between users needs proof that the caller actually held the
-- guest session — otherwise `merge(some_other_uid)` would be a data-theft and
-- account-deletion primitive. The proof here is a one-hour bearer token:
-- issued while authenticated *as the guest*, redeemed moments later as the
-- signed-in user. Neither call ever takes a user id as an argument.

create table account_merge_tokens (
  token uuid primary key default gen_random_uuid(),
  from_user uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- 0001 sets default privileges that grant every new public table to anon and
-- authenticated, so revoke explicitly. RLS with no policies would already deny
-- these roles; this makes the intent legible rather than incidental. The two
-- functions below are security definer and so are unaffected.
alter table account_merge_tokens enable row level security;
revoke all on table account_merge_tokens from anon, authenticated;

-- ---------------------------------------------------------------------------

create or replace function public.issue_merge_token()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  new_token uuid;
begin
  if uid is null then
    raise exception 'issue_merge_token: no authenticated user';
  end if;

  -- Only a guest account is ever the *source* of a merge. Without this a
  -- fully signed-in user could volunteer their own account for absorption.
  if not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    raise exception 'issue_merge_token: only guest sessions can be merged';
  end if;

  -- One live token per guest, and opportunistic cleanup of expired ones so the
  -- table does not need a scheduled sweep.
  delete from public.account_merge_tokens
   where from_user = uid
      or created_at < now() - interval '1 hour';

  insert into public.account_merge_tokens (from_user)
  values (uid)
  returning token into new_token;

  return new_token;
end;
$$;

revoke all on function public.issue_merge_token() from public, anon;
grant execute on function public.issue_merge_token() to authenticated;

-- ---------------------------------------------------------------------------

create or replace function public.claim_merge_token(p_token uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target uuid := auth.uid();
  source uuid;
begin
  if target is null then
    raise exception 'claim_merge_token: no authenticated user';
  end if;

  select from_user into source
    from public.account_merge_tokens
   where token = p_token
     and created_at > now() - interval '1 hour';

  if source is null then
    raise exception 'claim_merge_token: unknown or expired token';
  end if;

  -- Single use, whatever happens next.
  delete from public.account_merge_tokens where token = p_token;

  -- The email path keeps the same id, so this is a no-op rather than an error.
  if source = target then
    return;
  end if;

  if not exists (select 1 from auth.users where id = source and is_anonymous) then
    raise exception 'claim_merge_token: source is not a guest account';
  end if;

  -- Collections: `do nothing` on conflict, because the destination account
  -- already having liked a sermon is not a conflict worth resolving.
  insert into public.sermon_likes (user_id, sermon_id, created_at)
  select target, sermon_id, created_at
    from public.sermon_likes where user_id = source
  on conflict do nothing;

  insert into public.saved_devotionals (user_id, devotional_id, created_at)
  select target, devotional_id, created_at
    from public.saved_devotionals where user_id = source
  on conflict do nothing;

  insert into public.event_registrations (user_id, event_id, created_at)
  select target, event_id, created_at
    from public.event_registrations where user_id = source
  on conflict do nothing;

  insert into public.testimony_amens (user_id, testimony_id, created_at)
  select target, testimony_id, created_at
    from public.testimony_amens where user_id = source
  on conflict do nothing;

  insert into public.devotional_reads (user_id, for_date, read_at)
  select target, for_date, read_at
    from public.devotional_reads where user_id = source
  on conflict do nothing;

  -- Playback is the one case where the two rows mean different things: keep
  -- whichever device got further into the sermon.
  insert into public.playback_progress (user_id, sermon_id, position_secs, updated_at)
  select target, sermon_id, position_secs, updated_at
    from public.playback_progress where user_id = source
  on conflict (user_id, sermon_id) do update
    set position_secs = greatest(
          playback_progress.position_secs, excluded.position_secs),
        updated_at = greatest(
          playback_progress.updated_at, excluded.updated_at);

  -- Authored content is reassigned, not copied — it has its own identity and
  -- must survive the delete below. prayer_requests cascades from auth.users
  -- and testimonies is `on delete set null`, so both would otherwise be lost
  -- or orphaned.
  update public.prayer_requests set user_id = target where user_id = source;
  update public.testimonies     set user_id = target where user_id = source;

  -- Profile: fill only the gaps. The destination account's own name, and its
  -- member code (which is printed on the QR the welcome desk scans), win.
  update public.profiles p
     set full_name = coalesce(nullif(p.full_name, ''), g.full_name),
         branch    = coalesce(nullif(p.branch, ''), g.branch)
    from public.profiles g
   where p.id = target
     and g.id = source;

  -- Cascades the now-empty guest rows away.
  delete from auth.users where id = source;
end;
$$;

revoke all on function public.claim_merge_token(uuid) from public, anon;
grant execute on function public.claim_merge_token(uuid) to authenticated;
