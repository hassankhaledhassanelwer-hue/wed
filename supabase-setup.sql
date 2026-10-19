create table if not exists public.kv (
  path text primary key,
  val  jsonb not null
);

alter table public.kv enable row level security;

drop policy if exists "public read" on public.kv;
create policy "public read" on public.kv
  for select to anon, authenticated using (true);

drop policy if exists "admin write" on public.kv;
create policy "admin write" on public.kv
  for all to authenticated
  using      ((auth.jwt() ->> 'email') = 'hassankhaledhassanelwer@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'hassankhaledhassanelwer@gmail.com');

create or replace function public.increment_stat(field text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if field not in ('views','followers') then
    raise exception 'bad field';
  end if;
  insert into public.kv(path, val)
  values ('stats/main', jsonb_build_object(field, 1))
  on conflict (path) do update
    set val = public.kv.val
        || jsonb_build_object(field, coalesce((public.kv.val ->> field)::bigint, 0) + 1);
end $$;

grant execute on function public.increment_stat(text) to anon, authenticated;
