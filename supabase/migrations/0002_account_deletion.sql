-- Account deletion, required by App Store guideline 5.1.1(v) and the
-- equivalent Google Play policy: an app that creates accounts must let the
-- user delete one from inside the app.
--
-- Every user-owned table cascades from auth.users, with one exception:
-- testimonies.user_id is `on delete set null`, so deleting the auth row would
-- leave the testimony published and merely detached from its author. That is
-- the wrong default for a deletion request, so this function removes them
-- explicitly first. The confirmation copy in the app says so.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'delete_account: no authenticated user';
  end if;

  -- Not covered by cascade (see note above).
  delete from public.testimonies where user_id = uid;

  -- profiles, sermon_likes, saved_devotionals, event_registrations,
  -- testimony_amens, playback_progress, devotional_reads and prayer_requests
  -- all cascade from this.
  delete from auth.users where id = uid;
end;
$$;

-- security definer runs as the owner, so lock the entry point down to
-- signed-in callers only. Anonymous sessions are `authenticated` too, so a
-- guest can delete their own guest account.
revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
