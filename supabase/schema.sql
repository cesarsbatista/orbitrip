-- Orbitrip V3.4 | Execute UMA vez no SQL Editor do Supabase.
-- Segurança: nunca use uma service_role key no navegador.
create extension if not exists pgcrypto;

create table if not exists public.trips (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists trips_owner_idx on public.trips(owner_id);

create table if not exists public.trip_members (
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('editor','viewer')),
  joined_at timestamptz not null default now(),
  primary key (trip_id,user_id)
);
create index if not exists trip_members_user_idx on public.trip_members(user_id);

create table if not exists public.trip_invites (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  code text not null unique default substr(replace(gen_random_uuid()::text,'-',''),1,24),
  role text not null default 'editor' check(role in ('editor','viewer')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now()
);
create index if not exists trip_invites_trip_idx on public.trip_invites(trip_id);

-- Estas funções evitam recursão nas políticas RLS.
create or replace function public.orbitrip_can_view(p_trip uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists(
    select 1 from public.trips t where t.id=p_trip
      and (t.owner_id=(select auth.uid())
           or exists(select 1 from public.trip_members m where m.trip_id=p_trip and m.user_id=(select auth.uid())))
  )
$$;

create or replace function public.orbitrip_can_edit(p_trip uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists(
    select 1 from public.trips t where t.id=p_trip
      and (t.owner_id=(select auth.uid())
           or exists(select 1 from public.trip_members m where m.trip_id=p_trip
                     and m.user_id=(select auth.uid()) and m.role='editor'))
  )
$$;

create or replace function public.orbitrip_is_owner(p_trip uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists(select 1 from public.trips where id=p_trip and owner_id=(select auth.uid()))
$$;

alter table public.trips enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_invites enable row level security;

drop policy if exists trips_select on public.trips;
create policy trips_select on public.trips for select to authenticated
using (public.orbitrip_can_view(id));
drop policy if exists trips_insert on public.trips;
create policy trips_insert on public.trips for insert to authenticated
with check (owner_id=(select auth.uid()));
drop policy if exists trips_update on public.trips;
create policy trips_update on public.trips for update to authenticated
using (public.orbitrip_can_edit(id)) with check (public.orbitrip_can_edit(id));
drop policy if exists trips_delete on public.trips;
create policy trips_delete on public.trips for delete to authenticated
using (public.orbitrip_is_owner(id));

drop policy if exists members_select on public.trip_members;
create policy members_select on public.trip_members for select to authenticated
using (public.orbitrip_can_view(trip_id));
drop policy if exists members_insert on public.trip_members;
create policy members_insert on public.trip_members for insert to authenticated
with check (public.orbitrip_is_owner(trip_id));
drop policy if exists members_update on public.trip_members;
create policy members_update on public.trip_members for update to authenticated
using (public.orbitrip_is_owner(trip_id)) with check (public.orbitrip_is_owner(trip_id));
drop policy if exists members_delete on public.trip_members;
create policy members_delete on public.trip_members for delete to authenticated
using (public.orbitrip_is_owner(trip_id));

drop policy if exists invites_select on public.trip_invites;
create policy invites_select on public.trip_invites for select to authenticated
using (public.orbitrip_is_owner(trip_id));
drop policy if exists invites_insert on public.trip_invites;
create policy invites_insert on public.trip_invites for insert to authenticated
with check (created_by=(select auth.uid()) and public.orbitrip_is_owner(trip_id));
drop policy if exists invites_delete on public.trip_invites;
create policy invites_delete on public.trip_invites for delete to authenticated
using (public.orbitrip_is_owner(trip_id));

-- Menor privilégio: membros não podem tomar posse de uma viagem.
revoke all on public.trips,public.trip_members,public.trip_invites from anon;
revoke all on public.trips,public.trip_members,public.trip_invites from authenticated;
grant select,insert,delete on public.trips to authenticated;
grant update(payload,revision,updated_at) on public.trips to authenticated;
grant select,insert,update,delete on public.trip_members to authenticated;
grant select,insert,delete on public.trip_invites to authenticated;

-- Controle de revisão: impede que uma edição antiga sobrescreva a nova.
create or replace function public.orbitrip_save_trip(
  p_trip_id uuid, p_payload jsonb, p_expected_revision bigint
) returns bigint language plpgsql security invoker set search_path = ''
as $$
declare new_revision bigint;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Dados de viagem inválidos';
  end if;
  update public.trips
  set payload=p_payload,revision=revision+1,updated_at=now()
  where id=p_trip_id and revision=p_expected_revision
  returning revision into new_revision;
  if new_revision is null then
    raise exception 'CONFLICT_OR_DENIED' using errcode='P0001';
  end if;
  return new_revision;
end;
$$;

-- O código funciona apenas uma vez e expira após sete dias.
create or replace function public.orbitrip_accept_invite(p_code text)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_invite public.trip_invites%rowtype;
begin
  if (select auth.uid()) is null then raise exception 'Faça login primeiro'; end if;
  select * into v_invite from public.trip_invites
    where code=lower(trim(p_code)) and expires_at>now()
    for update;
  if not found then raise exception 'Convite inválido, expirado ou utilizado'; end if;
  if not public.orbitrip_is_owner(v_invite.trip_id) then
    insert into public.trip_members (trip_id,user_id,role)
    values(v_invite.trip_id,(select auth.uid()),v_invite.role)
    on conflict (trip_id,user_id) do update set role=excluded.role;
  end if;
  delete from public.trip_invites where id=v_invite.id;
  return v_invite.trip_id;
end;
$$;

revoke execute on function public.orbitrip_can_view(uuid) from public,anon;
revoke execute on function public.orbitrip_can_edit(uuid) from public,anon;
revoke execute on function public.orbitrip_is_owner(uuid) from public,anon;
revoke execute on function public.orbitrip_save_trip(uuid,jsonb,bigint) from public,anon;
revoke execute on function public.orbitrip_accept_invite(text) from public,anon;
grant execute on function public.orbitrip_can_view(uuid),public.orbitrip_can_edit(uuid),
 public.orbitrip_is_owner(uuid),public.orbitrip_save_trip(uuid,jsonb,bigint),
 public.orbitrip_accept_invite(text) to authenticated;

-- Sincronização. Postgres Changes: o acesso continua controlado por RLS.
do $$ begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trips') then
    alter publication supabase_realtime add table public.trips;
  end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trip_members') then
    alter publication supabase_realtime add table public.trip_members;
  end if;
end $$;
