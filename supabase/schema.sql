-- Orbitrip V3.4 — Instalação inicial reproduzível (aplicada ao projeto Supabase).
-- Não execute uma segunda vez no projeto já configurado.
-- Autorização por RLS e RPC com revisão otimista.
create schema if not exists orbitrip_private;
revoke all on schema orbitrip_private from public, anon;
grant usage on schema orbitrip_private to authenticated;

create table public.trips (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null check(jsonb_typeof(payload)='object'),
  revision bigint not null default 1 check(revision>=1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trips_owner_idx on public.trips(owner_id);
create table public.trip_members (
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check(role in ('editor','viewer')),
  joined_at timestamptz not null default now(),
  primary key (trip_id,user_id)
);
create index trip_members_user_idx on public.trip_members(user_id);
create table public.trip_invites (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  code text not null unique default substr(replace(gen_random_uuid()::text,'-',''),1,24),
  role text not null default 'editor' check(role in ('editor','viewer')),
  expires_at timestamptz not null default (now()+interval '7 days'),
  created_at timestamptz not null default now()
);
create index trip_invites_trip_idx on public.trip_invites(trip_id);
create index trip_invites_created_by_idx on public.trip_invites(created_by);

create function orbitrip_private.is_owner(p_trip uuid) returns boolean
 language sql stable security definer set search_path=''
 as $$select exists(select 1 from public.trips t where t.id=p_trip and t.owner_id=(select auth.uid()))$$;
create function orbitrip_private.can_view(p_trip uuid) returns boolean
 language sql stable security definer set search_path=''
 as $$select exists(select 1 from public.trips t where t.id=p_trip
 and(t.owner_id=(select auth.uid()) or exists(
 select 1 from public.trip_members m where m.trip_id=p_trip and m.user_id=(select auth.uid()))))$$;
create function orbitrip_private.can_edit(p_trip uuid) returns boolean
 language sql stable security definer set search_path=''
 as $$select exists(select 1 from public.trips t where t.id=p_trip
 and(t.owner_id=(select auth.uid()) or exists(
 select 1 from public.trip_members m where m.trip_id=p_trip and m.user_id=(select auth.uid()) and m.role='editor')))$$;

alter table public.trips enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_invites enable row level security;

-- O proprietário é identificado diretamente para permitir INSERT ... RETURNING
-- na mesma instrução; a verificação de colaboradores continua em can_view.
create policy trips_select on public.trips for select to authenticated
 using(owner_id=(select auth.uid()) or orbitrip_private.can_view(id));
create policy trips_insert on public.trips for insert to authenticated
 with check(owner_id=(select auth.uid()) and payload->>'id'=id::text);
create policy trips_delete on public.trips for delete to authenticated using(orbitrip_private.is_owner(id));
create policy members_select on public.trip_members for select to authenticated using(orbitrip_private.can_view(trip_id));
create policy members_insert on public.trip_members for insert to authenticated with check(orbitrip_private.is_owner(trip_id));
create policy members_update on public.trip_members for update to authenticated
 using(orbitrip_private.is_owner(trip_id)) with check(orbitrip_private.is_owner(trip_id));
create policy members_delete on public.trip_members for delete to authenticated using(orbitrip_private.is_owner(trip_id));
create policy invites_select on public.trip_invites for select to authenticated using(orbitrip_private.is_owner(trip_id));
create policy invites_insert on public.trip_invites for insert to authenticated
 with check(created_by=(select auth.uid()) and orbitrip_private.is_owner(trip_id));
create policy invites_delete on public.trip_invites for delete to authenticated using(orbitrip_private.is_owner(trip_id));

revoke all on public.trips,public.trip_members,public.trip_invites from public,anon,authenticated;
grant select,insert,delete on public.trips to authenticated;
grant select,insert,update,delete on public.trip_members to authenticated;
grant select,insert,delete on public.trip_invites to authenticated;

-- Nenhum UPDATE direto em trips: o servidor verifica autorização + revisão.
create function orbitrip_private.save_trip_impl(p_trip_id uuid,p_payload jsonb,p_expected_revision bigint)
returns bigint language plpgsql security definer set search_path='' as $$
declare v_revision bigint;
begin
 if(select auth.uid()) is null or not orbitrip_private.can_edit(p_trip_id) then
   raise exception 'Permissão insuficiente' using errcode='42501';
 end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object'
    or p_payload->>'id' is distinct from p_trip_id::text then
   raise exception 'Conteúdo da viagem inválido' using errcode='22023';
 end if;
 update public.trips set payload=p_payload, revision=revision+1,updated_at=now()
   where id=p_trip_id and revision=p_expected_revision returning revision into v_revision;
 if v_revision is null then
   raise exception 'CONFLICT_OR_DENIED: roteiro alterado em outra sessão' using errcode='P0001';
 end if;
 return v_revision;
end;$$;
create function public.orbitrip_save_trip(p_trip_id uuid,p_payload jsonb,p_expected_revision bigint)
 returns bigint language sql security invoker set search_path=''
 as $$select orbitrip_private.save_trip_impl(p_trip_id,p_payload,p_expected_revision)$$;

-- Convites: 96 bits aleatórios, expiração em 7 dias, consumo único.
create function orbitrip_private.accept_invite_impl(p_code text)
 returns uuid language plpgsql security definer set search_path='' as $$
declare v public.trip_invites%rowtype; v_user uuid;
begin
 v_user=(select auth.uid());
 if v_user is null then raise exception 'Faça login para aceitar o convite' using errcode='42501'; end if;
 select * into v from public.trip_invites where code=lower(trim(p_code))
 and expires_at>now() for update;
 if not found then raise exception 'Convite inválido, expirado ou utilizado' using errcode='P0001';end if;
 if not orbitrip_private.is_owner(v.trip_id) then
   insert into public.trip_members(trip_id,user_id,role) values(v.trip_id,v_user,v.role)
   on conflict(trip_id,user_id) do update set role=excluded.role;
 end if;
 delete from public.trip_invites where id=v.id;
 return v.trip_id;
end;$$;
create function public.orbitrip_accept_invite(p_code text)
 returns uuid language sql security invoker set search_path=''
 as $$select orbitrip_private.accept_invite_impl(p_code)$$;

revoke all on all functions in schema orbitrip_private from public,anon,authenticated;
revoke all on function public.orbitrip_save_trip(uuid,jsonb,bigint) from public,anon;
revoke all on function public.orbitrip_accept_invite(text) from public,anon;
grant execute on function orbitrip_private.is_owner(uuid),
 orbitrip_private.can_view(uuid),orbitrip_private.can_edit(uuid),
 orbitrip_private.save_trip_impl(uuid,jsonb,bigint),orbitrip_private.accept_invite_impl(text)
 to authenticated;
grant execute on function public.orbitrip_save_trip(uuid,jsonb,bigint),
 public.orbitrip_accept_invite(text) to authenticated;
revoke create on schema public from public;

alter publication supabase_realtime add table public.trips;
alter publication supabase_realtime add table public.trip_members;
