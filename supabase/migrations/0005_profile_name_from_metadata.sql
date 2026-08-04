-- Seed profiles.full_name from the sign-up metadata.
--
-- The app passes the name as `data: {'full_name': ...}` and then writes it to
-- `profiles` itself. That second step needs a session — and there are two
-- routes where there isn't one:
--
--   * email sign-up with confirmations required returns no session at all, so
--     the follow-up update is skipped and the name is lost outright;
--   * Google and Apple sign-in, where the name arrives inside the ID token.
--
-- Doing it in the trigger means the name lands with the row, whatever route
-- created it. `handle_new_user` is otherwise unchanged from 0001.
--
-- `name` is checked as well as `full_name` because that is the claim Google
-- puts in an OIDC ID token.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, member_code)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      '')), ''),
    'WGN-' || lpad((floor(random() * 9000) + 1000)::int::text, 4, '0')
      || '-' || upper(substr(new.id::text, 1, 2))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
