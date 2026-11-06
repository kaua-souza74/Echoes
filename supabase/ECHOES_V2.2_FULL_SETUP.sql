-- ECHOES V2.2 — script completo de instalação (schema + catálogo educativo)
-- Antes de executar: rode supabase/qa/preflight_remote.sql e confira conflitos.
-- CREATE TABLE IF NOT EXISTS não corrige uma tabela preexistente com formato diferente.
-- Esta transação não apaga tabelas nem dados de jogadores; o seed atualiza textos pelos IDs estáveis.
-- Se houver erro, a transação não deve ser concluída. Leia a mensagem antes de tentar novamente.

begin;

-- MIGRATION: 20261030120000_echoes_v22_legacy_update.sql
-- ECHOES V2.2 foundational schema. Apply only after reviewing project drift.
-- Client-reported run times remain unverified; see docs/RANKING_RULES.md.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 24),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stages (
  id text primary key,
  title text not null,
  stage_order smallint not null unique check (stage_order between 1 and 3),
  version integer not null check (version > 0),
  description text not null,
  difficulty text not null,
  category text not null,
  reward_points integer not null default 100 check (reward_points >= 0),
  published boolean not null default true
);

create table if not exists public.collectibles (
  id text primary key,
  stage_id text not null references public.stages(id),
  title text not null,
  memory_id text not null unique,
  unique_reward_points integer not null default 10 check (unique_reward_points >= 0)
);

create table if not exists public.memory_entries (
  id text primary key,
  collectible_id text not null unique references public.collectibles(id),
  stage_id text not null references public.stages(id),
  title text not null,
  narrative text not null,
  character_or_event text not null,
  concept text not null,
  explanation text not null,
  illustration_asset text not null
);

create table if not exists public.learning_checks (
  id text primary key,
  stage_id text not null references public.stages(id),
  prompt text not null,
  options jsonb not null check (jsonb_typeof(options)='array' and jsonb_array_length(options) between 2 and 5),
  correct_index smallint not null check (correct_index >= 0),
  feedback_correct text not null,
  feedback_incorrect text not null,
  memory_ids text[] not null default '{}',
  check (correct_index < jsonb_array_length(options))
);
create table if not exists public.user_learning_checks (
  user_id uuid not null references auth.users(id) on delete cascade,
  check_id text not null references public.learning_checks(id),
  attempts integer not null default 0 check (attempts >= 0),
  passed_at timestamptz,
  last_answer smallint,
  updated_at timestamptz not null default now(),
  primary key(user_id,check_id)
);

create table if not exists public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  icon_asset text not null,
  condition_key text not null unique
);

create table if not exists public.user_stages (
  user_id uuid not null references auth.users(id) on delete cascade,
  stage_id text not null references public.stages(id),
  status text not null default 'available' check (status in ('available','in_progress','completed')),
  first_completed_at timestamptz,
  total_deaths integer not null default 0 check (total_deaths >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, stage_id),
  check ((status = 'completed') = (first_completed_at is not null))
);

create table if not exists public.score_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check (source_type in ('stage_first_clear','collectible_first_found')),
  source_id text not null,
  points integer not null check (points > 0),
  created_at timestamptz not null default now(),
  unique(user_id,source_type,source_id)
);
create index if not exists score_ledger_user_idx on public.score_ledger(user_id);

create table if not exists public.stage_runs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  stage_id text not null references public.stages(id),
  stage_version integer not null check (stage_version > 0),
  mode text not null check (mode in ('story','speedrun')),
  duration_ms integer not null check (duration_ms between 1 and 86400000),
  deaths integer not null check (deaths between 0 and 10000),
  completed boolean not null,
  verified boolean not null default false,
  started_at timestamptz not null default clock_timestamp(),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, id)
);
create index if not exists stage_runs_ranking_idx
  on public.stage_runs (stage_id, stage_version, duration_ms, created_at)
  where completed and mode = 'speedrun';
create index if not exists stage_runs_user_idx on public.stage_runs(user_id, created_at desc);

create table if not exists public.personal_bests (
  user_id uuid not null references auth.users(id) on delete cascade,
  stage_id text not null references public.stages(id),
  stage_version integer not null check (stage_version > 0),
  run_id uuid not null,
  duration_ms integer not null check (duration_ms between 1 and 86400000),
  deaths integer not null check (deaths >= 0),
  mode text not null check (mode = 'speedrun'),
  achieved_at timestamptz not null default now(),
  primary key (user_id, stage_id, stage_version),
  foreign key (user_id, run_id) references public.stage_runs(user_id, id)
);

create table if not exists public.user_collectibles (
  user_id uuid not null references auth.users(id) on delete cascade,
  collectible_id text not null references public.collectibles(id),
  first_run_id uuid not null,
  collected_at timestamptz not null default now(),
  primary key (user_id, collectible_id),
  foreign key (user_id, first_run_id) references public.stage_runs(user_id, id)
);

create table if not exists public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

create table if not exists public.user_memories (
  user_id uuid not null references auth.users(id) on delete cascade,
  memory_id text not null references public.memory_entries(id),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, memory_id)
);

create table if not exists public.dialogue_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  dialogue_id text not null,
  viewed_at timestamptz not null default now(),
  primary key (user_id, dialogue_id)
);

create table if not exists public.player_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  master_volume double precision not null default 1 check (master_volume between 0 and 1),
  effects_volume double precision not null default 1 check (effects_volume between 0 and 1),
  music_volume double precision not null default 1 check (music_volume between 0 and 1),
  show_timer boolean not null default true,
  dialogue_speed double precision not null default 1 check (dialogue_speed between 0.5 and 2),
  reduce_visual_effects boolean not null default false,
  text_scale double precision not null default 1 check (text_scale between 0.8 and 1.6),
  vibration boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.stages(id,title,stage_order,version,description,difficulty,category) values
('stage_01','O Despertar',1,2,'Reconstrua vestígios de uma história que começa a voltar.','Fácil','Memória e identidade'),
('stage_02','Galerias Quebradas',2,1,'Descubra o que as pedras preservam e o que só as pessoas podem transmitir.','Médio','Patrimônio cultural'),
('stage_03','Torre do Eco',3,1,'Reúna as vozes e escolha como o Vale continuará lembrando.','Desafiador','Pertencimento e preservação')
on conflict (id) do nothing;

-- IDs are copied verbatim from the three authored level JSON files.
insert into public.collectibles(id,stage_id,title,memory_id) values
('echo_01','stage_01','Eco do Despertar','memory_echo_01'),('echo_roots','stage_01','Eco das Raízes','memory_echo_roots'),('echo_bridge','stage_01','Eco da Ponte','memory_echo_bridge'),('echo_depths','stage_01','Eco das Profundezas','memory_echo_depths'),('echo_heart','stage_01','Eco do Coração','memory_echo_heart'),('echo_secret','stage_01','Eco Oculto','memory_echo_secret'),('echo_return','stage_01','Eco do Retorno','memory_echo_return'),
('galleries_gate','stage_02','Eco do Portão','memory_galleries_gate'),('galleries_wings','stage_02','Eco das Asas','memory_galleries_wings'),('galleries_chain','stage_02','Eco das Correntes','memory_galleries_chain'),('galleries_rupture','stage_02','Eco da Ruptura','memory_galleries_rupture'),('galleries_secret','stage_02','Eco Oculto','memory_galleries_secret'),('galleries_bridge','stage_02','Eco da Ponte','memory_galleries_bridge'),('galleries_last','stage_02','Último Eco das Galerias','memory_galleries_last'),
('tower_threshold','stage_03','Eco do Limiar','memory_tower_threshold'),('tower_glass','stage_03','Eco do Vidro','memory_tower_glass'),('tower_guardian','stage_03','Eco do Guardião','memory_tower_guardian'),('tower_shadow','stage_03','Eco da Sombra','memory_tower_shadow'),('tower_alcove','stage_03','Eco do Nicho','memory_tower_alcove'),('tower_memory','stage_03','Eco da Memória','memory_tower_memory'),('tower_last','stage_03','O Último Eco','memory_tower_last')
on conflict (id) do nothing;

insert into public.memory_entries(id,collectible_id,stage_id,title,narrative,character_or_event,concept,explanation,illustration_asset)
select c.memory_id,c.id,c.stage_id,c.title,
  'Um fragmento de lembrança do Vale, reunido pelo Errante.',
  'Vozes e habitantes do Vale','memória coletiva',
  'Uma lembrança compartilhada ajuda pessoas a contar a história de um lugar e de seus vínculos.',
  'assets/images/props/echo_fragment.png'
from public.collectibles c on conflict (id) do nothing;

insert into public.learning_checks(id,stage_id,prompt,options,correct_index,feedback_correct,feedback_incorrect,memory_ids) values
('check_stage_01','stage_01','A família preservou um pote rachado. Que pistas ajudam a descobrir sua história?','["A marca de tinta e o relato de quem o guardou","A cor do céu no mapa","A quantidade de pedras na ponte"]',0,'O objeto é uma pista; relacioná-lo a relatos e contexto ajuda a reconstruir a história.','O pote e a história de quem o preservou são pistas ligadas ao passado. Tente relacioná-las.','{memory_echo_01,memory_echo_secret}'),
('check_stage_02','stage_02','Qual par liga um bem material a um saber imaterial associado?','["A ponte de pedra e o conhecimento de encaixar suas pedras","A ponte e a cor do luar","A canção e o número de degraus"]',0,'A ponte é física; o saber de construí-la é transmitido pelas pessoas. As dimensões se relacionam.','Procure um bem físico e o conhecimento praticado para construí-lo ou cuidar dele.','{memory_galleries_rupture,memory_galleries_bridge}'),
('check_stage_03','stage_03','Como o arquivo deve preservar versões diferentes de uma festa?','["Ouvir quem as conta, registrar contexto e manter visíveis as versões","Escolher uma versão e apagar as demais","Deixar que só o guardião decida o significado"]',0,'Preservar envolve participação e contexto; versões diversas revelam diferentes perspectivas.','Pense em como ouvir as pessoas envolvidas e manter visíveis diferentes perspectivas.','{memory_tower_guardian,memory_tower_shadow}')
on conflict(id) do nothing;

insert into public.achievements(id,title,description,icon_asset,condition_key) values
('first_awakening','Primeiro Despertar','Conclua O Despertar.','assets/images/props/checkpoint_lume.png','first_stage_complete'),
('first_echo','Primeiro Eco','Encontre seu primeiro Eco.','assets/images/props/echo_fragment.png','first_collectible'),
('memory_guardian','Guardião das Memórias','Desbloqueie todas as memórias.','assets/images/props/echo_fragment.png','all_memories'),
('gallery_explorer','Explorador das Galerias','Conclua Galerias Quebradas.','assets/images/props/checkpoint_lume.png','stage_02_complete'),
('last_echo','O Último Eco','Conclua Torre do Eco.','assets/images/props/checkpoint_lume.png','stage_03_complete'),
('no_falls','Sem Quedas','Conclua uma fase sem morrer.','assets/images/props/checkpoint_lume.png','zero_death_clear'),
('against_time','Contra o Tempo','Conclua um speedrun elegível em até 180 segundos.','assets/images/effects/dash_trail.png','speedrun_complete'),
('voices_past','Vozes do Passado','Leia todas as conversas essenciais.','assets/images/narrative/memory_portrait.png','all_dialogues'),
('heritage_guardian','Guardião da Herança','Conclua a interação educativa das Galerias.','assets/images/props/echo_fragment.png','gallery_learning'),
('complete_memories','Memórias Completas','Reúna os 21 Ecos.','assets/images/props/echo_fragment.png','all_collectibles')
on conflict (id) do nothing;

create or replace function private.create_echoes_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,nickname)
  values (new.id, case when char_length(trim(new.raw_user_meta_data->>'nickname')) between 2 and 24 then trim(new.raw_user_meta_data->>'nickname') else 'Errante' end)
  on conflict (id) do nothing;
  insert into public.user_stages(user_id,stage_id,status)
  values (new.id,'stage_01','available') on conflict do nothing;
  insert into public.player_settings(user_id) values(new.id) on conflict do nothing;
  return new;
end $$;
revoke all on function private.create_echoes_profile() from public, anon, authenticated;
create or replace trigger echoes_auth_user_created after insert on auth.users
for each row execute function private.create_echoes_profile();

create or replace function private.record_stage_run(
  p_run_id uuid, p_stage_id text, p_version integer, p_mode text,
  p_duration_ms integer, p_deaths integer, p_completed boolean, p_collectibles text[]
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid(); v_stage_order smallint; v_reward integer := 0; v_stage_reward integer := 0;
  v_run public.stage_runs%rowtype;
  v_new_collectibles integer := 0; v_previous boolean := false;
  v_id text;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,0));
  select stage_order into v_stage_order from public.stages where id=p_stage_id and published and version=p_version;
  if v_stage_order is null or p_duration_ms is null or p_deaths is null or p_mode is null or p_completed is null or p_duration_ms not between 1 and 86400000
     or p_deaths not between 0 and 10000 or p_mode not in ('story','speedrun')
     or p_run_id is null then raise exception 'invalid run'; end if;
  if p_stage_id <> 'stage_01' and not exists (
    select 1 from public.user_stages where user_id=v_user and stage_id=(case when p_stage_id='stage_02' then 'stage_01' else 'stage_02' end) and status='completed'
  ) then raise exception 'stage locked'; end if;
  if p_completed and exists (
    select 1 from (values
      ('stage_01','echo_heart'),('stage_02','galleries_rupture'),('stage_03','tower_memory'),('stage_03','tower_last')
    ) as req(stage_id,collectible_id)
    where req.stage_id=p_stage_id
      and not (req.collectible_id=any(coalesce(p_collectibles,array[]::text[]))
        or exists(select 1 from public.user_collectibles uc where uc.user_id=v_user and uc.collectible_id=req.collectible_id))
  ) then raise exception 'required echoes missing'; end if;
  select * into v_run from public.stage_runs where user_id=v_user and id=p_run_id for update;
  if not found or v_run.stage_id<>p_stage_id or v_run.stage_version<>p_version or v_run.mode<>p_mode then raise exception 'run not started'; end if;
  if v_run.submitted_at is not null then
    return jsonb_build_object('duplicate',true,'points',0);
  end if;
  if p_completed and p_duration_ms < (case p_stage_id when 'stage_01' then 15000 when 'stage_02' then 20000 else 25000 end) then raise exception 'implausible duration'; end if;
  if p_duration_ms > extract(epoch from (clock_timestamp()-v_run.started_at))*1000+5000 then raise exception 'duration exceeds server elapsed time'; end if;
  if cardinality(coalesce(p_collectibles,array[]::text[]))>21 or exists(
    select 1 from unnest(coalesce(p_collectibles,array[]::text[])) u(collectible_id) where not exists(select 1 from public.collectibles c where c.id=u.collectible_id and c.stage_id=p_stage_id)
  ) then raise exception 'invalid collectible'; end if;
  update public.stage_runs set duration_ms=p_duration_ms,deaths=p_deaths,completed=p_completed,submitted_at=clock_timestamp()
  where id=p_run_id and user_id=v_user;
  insert into public.user_stages(user_id,stage_id,status,total_deaths)
  values(v_user,p_stage_id,'in_progress',p_deaths)
  on conflict(user_id,stage_id) do update set
    status=case when public.user_stages.status='completed' then 'completed' else 'in_progress' end,
    total_deaths=public.user_stages.total_deaths+excluded.total_deaths,updated_at=now();
  foreach v_id in array coalesce(p_collectibles, array[]::text[]) loop
    if exists(select 1 from public.collectibles where id=v_id and stage_id=p_stage_id) then
      insert into public.user_collectibles(user_id,collectible_id,first_run_id)
      values(v_user,v_id,p_run_id) on conflict do nothing;
      if found then
        v_new_collectibles := v_new_collectibles+1;
        insert into public.score_ledger(user_id,source_type,source_id,points)
        values(v_user,'collectible_first_found',v_id,10) on conflict do nothing;
        insert into public.user_memories(user_id,memory_id)
        select v_user,memory_id from public.collectibles where id=v_id on conflict do nothing;
      end if;
    end if;
  end loop;
  v_reward := v_reward + v_new_collectibles * 10;
  if v_new_collectibles > 0 then
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'first_echo') on conflict do nothing;
  end if;
  if (select count(*) from public.user_collectibles where user_id=v_user)=21 then
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'memory_guardian') on conflict do nothing;
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'complete_memories') on conflict do nothing;
  end if;
  if p_completed then
    select (first_completed_at is not null) into v_previous from public.user_stages where user_id=v_user and stage_id=p_stage_id;
    update public.user_stages set status='completed', first_completed_at=coalesce(first_completed_at,now()), updated_at=now()
    where user_id=v_user and stage_id=p_stage_id;
    if not v_previous then
      select reward_points into v_stage_reward from public.stages where id=p_stage_id;
      insert into public.score_ledger(user_id,source_type,source_id,points)
      values(v_user,'stage_first_clear',p_stage_id,v_stage_reward) on conflict do nothing;
      v_reward := v_reward+v_stage_reward;
    end if;
    if v_new_collectibles > 0 then
      insert into public.user_achievements(user_id,achievement_id) values(v_user,'first_echo') on conflict do nothing;
    end if;
    if (select count(*) from public.user_collectibles where user_id=v_user)=21 then
      insert into public.user_achievements(user_id,achievement_id) values(v_user,'memory_guardian') on conflict do nothing;
      insert into public.user_achievements(user_id,achievement_id) values(v_user,'complete_memories') on conflict do nothing;
    end if;
    if not v_previous then
      if p_stage_id='stage_01' then insert into public.user_achievements(user_id,achievement_id) values(v_user,'first_awakening') on conflict do nothing; end if;
      if p_stage_id='stage_02' then insert into public.user_achievements(user_id,achievement_id) values(v_user,'gallery_explorer') on conflict do nothing; end if;
      if p_stage_id='stage_03' then insert into public.user_achievements(user_id,achievement_id) values(v_user,'last_echo') on conflict do nothing; end if;
    end if;
    if p_deaths=0 then insert into public.user_achievements(user_id,achievement_id) values(v_user,'no_falls') on conflict do nothing; end if;
    if v_stage_order < 3 then
      insert into public.user_stages(user_id,stage_id,status)
      values(v_user,case when v_stage_order=1 then 'stage_02' else 'stage_03' end,'available') on conflict do nothing;
    end if;
  end if;
  if p_mode='speedrun' and p_completed then
    if p_duration_ms<=180000 then insert into public.user_achievements(user_id,achievement_id) values(v_user,'against_time') on conflict do nothing; end if;
    insert into public.personal_bests(user_id,stage_id,stage_version,run_id,duration_ms,deaths,mode)
    values(v_user,p_stage_id,p_version,p_run_id,p_duration_ms,p_deaths,'speedrun')
    on conflict(user_id,stage_id,stage_version) do update set run_id=excluded.run_id,duration_ms=excluded.duration_ms,deaths=excluded.deaths,achieved_at=now()
    where excluded.duration_ms < public.personal_bests.duration_ms;
  end if;
  return jsonb_build_object('duplicate',false,'points',v_reward,'new_collectibles',v_new_collectibles,'completed',p_completed);
end $$;
revoke all on function private.record_stage_run(uuid,text,integer,text,integer,integer,boolean,text[]) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.record_stage_run(uuid,text,integer,text,integer,integer,boolean,text[]) to authenticated;

create or replace function private.record_dialogues(p_dialogues text[]) returns integer
language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid(); v_added integer := 0; v_id text;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  foreach v_id in array coalesce(p_dialogues,array[]::text[]) loop
    if v_id ~ '^(awakening|bridge|heart|passage|g_entry|g_wings|g_depth|g_rupture|g_exit|t_base|t_fragments|t_guardians|t_memory|t_final)$' then
      insert into public.dialogue_progress(user_id,dialogue_id) values(v_user,v_id) on conflict do nothing;
      if found then v_added := v_added+1; end if;
    end if;
  end loop;
  if (select count(*) from public.dialogue_progress where user_id=v_user)=14 then
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'voices_past') on conflict do nothing;
  end if;
  return v_added;
end $$;
revoke all on function private.record_dialogues(text[]) from public, anon;
grant execute on function private.record_dialogues(text[]) to authenticated;

create or replace function private.answer_learning_check(p_check_id text,p_answer smallint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid(); v_check public.learning_checks%rowtype; v_passed boolean;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  select * into v_check from public.learning_checks where id=p_check_id;
  if not found or p_answer is null or p_answer < 0 or p_answer >= jsonb_array_length(v_check.options) then raise exception 'invalid answer'; end if;
  if v_check.stage_id <> 'stage_01' and not exists (
    select 1 from public.user_stages where user_id=v_user and stage_id=(case when v_check.stage_id='stage_02' then 'stage_01' else 'stage_02' end) and status='completed'
  ) then raise exception 'stage locked'; end if;
  v_passed := p_answer=v_check.correct_index;
  insert into public.user_learning_checks(user_id,check_id,attempts,passed_at,last_answer)
  values(v_user,p_check_id,1,case when v_passed then now() end,p_answer)
  on conflict(user_id,check_id) do update set attempts=public.user_learning_checks.attempts+1,
    passed_at=coalesce(public.user_learning_checks.passed_at,case when v_passed then now() end),
    last_answer=excluded.last_answer,updated_at=now();
  if v_passed and p_check_id='check_stage_02' then
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'heritage_guardian') on conflict do nothing;
  end if;
  return jsonb_build_object('correct',v_passed,'feedback',case when v_passed then v_check.feedback_correct else v_check.feedback_incorrect end);
end $$;
revoke all on function private.answer_learning_check(text,smallint) from public, anon;
grant execute on function private.answer_learning_check(text,smallint) to authenticated;

do $$ declare t text; begin
  foreach t in array array['profiles','stages','collectibles','memory_entries','learning_checks','user_learning_checks','achievements','user_stages','stage_runs','personal_bests','user_collectibles','user_achievements','user_memories','dialogue_progress','player_settings','score_ledger'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from anon, authenticated',t);
  end loop;
end $$;
grant select on public.stages,public.collectibles,public.memory_entries,public.learning_checks,public.achievements to anon,authenticated;
grant select on public.profiles to authenticated;
grant update (nickname) on public.profiles to authenticated;
grant select on public.user_stages,public.stage_runs,public.personal_bests,public.user_collectibles,public.user_achievements,public.user_memories,public.user_learning_checks,public.dialogue_progress,public.player_settings,public.score_ledger to authenticated;
grant insert,update on public.player_settings to authenticated;

create policy "catalog readable" on public.stages for select to anon,authenticated using (published);
create policy "collectibles readable" on public.collectibles for select to anon,authenticated using (true);
create policy "memories readable" on public.memory_entries for select to anon,authenticated using (true);
create policy "learning checks readable" on public.learning_checks for select to anon,authenticated using (true);
create policy "achievements readable" on public.achievements for select to anon,authenticated using (true);
create policy "own profile" on public.profiles for select to authenticated using ((select auth.uid())=id);
create policy "profile owner updates nickname" on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy "own user stages" on public.user_stages for select to authenticated using ((select auth.uid())=user_id);
create policy "own score ledger" on public.score_ledger for select to authenticated using ((select auth.uid())=user_id);
create policy "own runs" on public.stage_runs for select to authenticated using ((select auth.uid())=user_id);
create policy "own bests" on public.personal_bests for select to authenticated using ((select auth.uid())=user_id);
create policy "own collectibles" on public.user_collectibles for select to authenticated using ((select auth.uid())=user_id);
create policy "own achievements" on public.user_achievements for select to authenticated using ((select auth.uid())=user_id);
create policy "own learning checks" on public.user_learning_checks for select to authenticated using ((select auth.uid())=user_id);
create policy "own memories" on public.user_memories for select to authenticated using ((select auth.uid())=user_id);
create policy "own dialogue progress" on public.dialogue_progress for select to authenticated using ((select auth.uid())=user_id);
create policy "own settings" on public.player_settings for select to authenticated using ((select auth.uid())=user_id);
create policy "owner inserts settings" on public.player_settings for insert to authenticated with check ((select auth.uid())=user_id);
create policy "owner updates settings" on public.player_settings for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

-- Deliberately owner-executed aggregation: exposes only nickname and point total.
-- Base private tables remain ungranted to anon; emails and user ids are not projected.
create or replace view public.public_leaderboard with (security_invoker=true) as
select p.nickname, coalesce(sum(l.points),0)::bigint as points
from public.profiles p left join public.score_ledger l on l.user_id=p.id
group by p.id,p.nickname;
revoke all on public.public_leaderboard from public,anon,authenticated;

-- Private transactional operations; only the narrow invoker wrappers below are
-- exposed through the default public Data API. Do not expose the private schema.
create or replace function private.echoes_bootstrap() returns void
language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_name text;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  select trim(raw_user_meta_data->>'nickname') into v_name from auth.users where id=v_user;
  if v_name is null or char_length(v_name) not between 2 and 24 then v_name:='Errante'; end if;
  insert into public.profiles(id,nickname) values(v_user,v_name) on conflict do nothing;
  insert into public.user_stages(user_id,stage_id,status) values(v_user,'stage_01','available') on conflict do nothing;
  insert into public.player_settings(user_id) values(v_user) on conflict do nothing;
end $$;

create or replace function private.start_stage(p_run_id uuid,p_stage_id text,p_version integer,p_mode text)
returns void language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_order smallint;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,0));
  perform private.echoes_bootstrap();
  select stage_order into v_order from public.stages where id=p_stage_id and version=p_version and published;
  if v_order is null or p_run_id is null or p_mode is null or p_mode not in ('story','speedrun') then raise exception 'invalid stage'; end if;
  if v_order>1 and not exists(select 1 from public.user_stages us join public.stages s on s.id=us.stage_id
    where us.user_id=v_user and us.status='completed' and s.stage_order=v_order-1) then raise exception 'stage locked'; end if;
  insert into public.stage_runs(id,user_id,stage_id,stage_version,mode,duration_ms,deaths,completed)
  values(p_run_id,v_user,p_stage_id,p_version,p_mode,1,0,false) on conflict(id) do nothing;
  if not exists(select 1 from public.stage_runs where id=p_run_id and user_id=v_user and stage_id=p_stage_id and stage_version=p_version and mode=p_mode and submitted_at is null) then raise exception 'invalid run identity'; end if;
  insert into public.user_stages(user_id,stage_id,status) values(v_user,p_stage_id,'in_progress')
  on conflict(user_id,stage_id) do update set status=case when public.user_stages.status='completed' then 'completed' else 'in_progress' end,updated_at=now();
end $$;

create or replace function private.collect_echo(p_run_id uuid,p_collectible_id text)
returns void language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_run public.stage_runs%rowtype; v_c public.collectibles%rowtype;
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text,0));
  select * into v_run from public.stage_runs where id=p_run_id and user_id=v_user for update;
  if not found then raise exception 'run not started'; end if;
  select * into v_c from public.collectibles where id=p_collectible_id and stage_id=v_run.stage_id;
  if not found then raise exception 'invalid collectible'; end if;
  if exists(select 1 from public.user_collectibles where user_id=v_user and collectible_id=p_collectible_id) then return; end if;
  if v_run.submitted_at is not null then raise exception 'run already submitted'; end if;
  insert into public.user_collectibles(user_id,collectible_id,first_run_id) values(v_user,p_collectible_id,p_run_id) on conflict do nothing;
  insert into public.score_ledger(user_id,source_type,source_id,points) values(v_user,'collectible_first_found',p_collectible_id,v_c.unique_reward_points) on conflict do nothing;
  insert into public.user_memories(user_id,memory_id) values(v_user,v_c.memory_id) on conflict do nothing;
  insert into public.user_achievements(user_id,achievement_id) values(v_user,'first_echo') on conflict do nothing;
  if (select count(*) from public.user_collectibles where user_id=v_user)=21 then
    insert into public.user_achievements(user_id,achievement_id) values(v_user,'memory_guardian'),(v_user,'complete_memories') on conflict do nothing;
  end if;
end $$;

create or replace function private.player_state() returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid();
begin
  if v_user is null then raise exception 'authentication required' using errcode='28000'; end if;
  return jsonb_build_object(
    'nickname',(select nickname from public.profiles where id=v_user),
    'points',coalesce((select sum(points) from public.score_ledger where user_id=v_user),0),
    'completed_runs',(select count(*) from public.stage_runs where user_id=v_user and completed),
    'stages',coalesce((select jsonb_object_agg(stage_id,status) from public.user_stages where user_id=v_user),'{}'::jsonb),
    'echoes',coalesce((select jsonb_agg(collectible_id order by collectible_id) from public.user_collectibles where user_id=v_user),'[]'::jsonb),
    'memories',coalesce((select jsonb_agg(memory_id order by memory_id) from public.user_memories where user_id=v_user),'[]'::jsonb),
    'dialogues',coalesce((select jsonb_agg(dialogue_id order by dialogue_id) from public.dialogue_progress where user_id=v_user),'[]'::jsonb),
    'learning_checks',coalesce((select jsonb_agg(check_id order by check_id) from public.user_learning_checks where user_id=v_user and passed_at is not null),'[]'::jsonb),
    'settings',(select to_jsonb(s)-'user_id' from public.player_settings s where user_id=v_user),
    'bests',coalesce((select jsonb_agg(to_jsonb(b)-'user_id' order by stage_id,stage_version) from public.personal_bests b where user_id=v_user),'[]'::jsonb),
    'achievements',(select jsonb_agg(to_jsonb(a)||jsonb_build_object('unlocked_at',u.unlocked_at) order by a.id)
      from public.achievements a left join public.user_achievements u on u.achievement_id=a.id and u.user_id=v_user)
  );
end $$;

create or replace function private.leaderboard(p_kind text,p_stage_id text)
returns table("position" bigint,player_id uuid,nickname text,result bigint)
language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode='28000'; end if;
  if p_kind is null or p_kind not in ('points','speedrun','combined','echoes') then raise exception 'invalid ranking'; end if;
  if p_kind='speedrun' and not exists(select 1 from public.stages where id=p_stage_id and published) then raise exception 'invalid stage'; end if;
  return query
  with scores as (
    select l.user_id,sum(l.points)::bigint value,min(l.created_at) achieved from public.score_ledger l where p_kind='points' group by l.user_id
    union all
    select c.user_id,count(*)::bigint,min(c.collected_at) from public.user_collectibles c where p_kind='echoes' group by c.user_id
    union all
    select b.user_id,b.duration_ms::bigint,b.achieved_at from public.personal_bests b join public.stages s on s.id=b.stage_id and s.version=b.stage_version and s.published
      where p_kind='speedrun' and b.stage_id=p_stage_id
    union all
    select b.user_id,sum(b.duration_ms)::bigint,max(b.achieved_at) from public.personal_bests b join public.stages s on s.id=b.stage_id and s.version=b.stage_version and s.published
      where p_kind='combined' group by b.user_id having count(distinct b.stage_id)=3
  ), ranked as (
    select row_number() over(order by case when p_kind in ('speedrun','combined') then sc.value else -sc.value end,sc.achieved,p.id) pos,
      p.id pid,p.nickname name,sc.value val
    from scores sc join public.profiles p on p.id=sc.user_id where sc.value>0
  ) select r.pos,r.pid,r.name,r.val from ranked r where r.pos<=100 or r.pid=auth.uid() order by r.pos;
end $$;

create index if not exists user_stages_stage_idx on public.user_stages(stage_id);
create index if not exists user_collectibles_collectible_idx on public.user_collectibles(collectible_id);
create index if not exists user_achievements_achievement_idx on public.user_achievements(achievement_id);
create index if not exists user_memories_memory_idx on public.user_memories(memory_id);
create index if not exists personal_bests_run_idx on public.personal_bests(run_id);
create index if not exists personal_bests_stage_ranking_idx on public.personal_bests(stage_id,stage_version,duration_ms,achieved_at);
create index if not exists stage_runs_stage_idx on public.stage_runs(stage_id);

revoke all on function private.echoes_bootstrap(),private.start_stage(uuid,text,integer,text),private.collect_echo(uuid,text),private.player_state(),private.leaderboard(text,text) from public,anon;
grant execute on function private.echoes_bootstrap(),private.start_stage(uuid,text,integer,text),private.collect_echo(uuid,text),private.player_state(),private.leaderboard(text,text) to authenticated;

create or replace function public.echoes_bootstrap() returns void language sql security invoker set search_path='' as $$select private.echoes_bootstrap()$$;
create or replace function public.echoes_player_state() returns jsonb language sql security invoker set search_path='' as $$select private.player_state()$$;
create or replace function public.echoes_start_stage(p_run_id uuid,p_stage_id text,p_version integer,p_mode text) returns void language sql security invoker set search_path='' as $$select private.start_stage(p_run_id,p_stage_id,p_version,p_mode)$$;
create or replace function public.echoes_collect_echo(p_run_id uuid,p_collectible_id text) returns void language sql security invoker set search_path='' as $$select private.collect_echo(p_run_id,p_collectible_id)$$;
create or replace function public.echoes_record_stage_run(p_run_id uuid,p_stage_id text,p_version integer,p_mode text,p_duration_ms integer,p_deaths integer,p_completed boolean,p_collectibles text[]) returns jsonb language sql security invoker set search_path='' as $$select private.record_stage_run(p_run_id,p_stage_id,p_version,p_mode,p_duration_ms,p_deaths,p_completed,p_collectibles)$$;
create or replace function public.echoes_record_dialogues(p_dialogues text[]) returns integer language sql security invoker set search_path='' as $$select private.record_dialogues(p_dialogues)$$;
create or replace function public.echoes_answer_learning_check(p_check_id text,p_answer smallint) returns jsonb language sql security invoker set search_path='' as $$select private.answer_learning_check(p_check_id,p_answer)$$;
create or replace function public.echoes_leaderboard(p_kind text,p_stage_id text) returns table("position" bigint,player_id uuid,nickname text,result bigint) language sql security invoker set search_path='' as $$select * from private.leaderboard(p_kind,p_stage_id)$$;

revoke all on function public.echoes_bootstrap(),public.echoes_player_state(),public.echoes_start_stage(uuid,text,integer,text),public.echoes_collect_echo(uuid,text),public.echoes_record_stage_run(uuid,text,integer,text,integer,integer,boolean,text[]),public.echoes_record_dialogues(text[]),public.echoes_answer_learning_check(text,smallint),public.echoes_leaderboard(text,text) from public,anon;
grant execute on function public.echoes_bootstrap(),public.echoes_player_state(),public.echoes_start_stage(uuid,text,integer,text),public.echoes_collect_echo(uuid,text),public.echoes_record_stage_run(uuid,text,integer,text,integer,integer,boolean,text[]),public.echoes_record_dialogues(text[]),public.echoes_answer_learning_check(text,smallint),public.echoes_leaderboard(text,text) to authenticated;

-- SEED: memory_catalog.sql
-- Generated by tools/generate_memory_seed.py from memory_catalog.json.

insert into public.memory_entries (id,collectible_id,stage_id,title,narrative,character_or_event,concept,explanation,illustration_asset) values
('memory_echo_01','echo_01','stage_01','O pote azul','Uma marca de tinta atravessa o fundo do pote. Alguém o guardou mesmo depois de rachado.','Objeto guardado por uma família','vestígios do passado','Um objeto pode oferecer pistas sobre quem o usou e por que foi preservado. Uma pista precisa ser relacionada a outras fontes para reconstruir uma história.','assets/images/props/echo_fragment.png'),
('memory_echo_roots','echo_roots','stage_01','O caminho das raízes','As raízes cresceram em volta da pedra onde duas amigas combinavam se encontrar.','Encontro entre amigas','memória individual e coletiva','A lembrança de cada amiga é individual; quando elas compartilham o relato, ele passa a compor uma memória comum daquele lugar.','assets/images/props/echo_fragment.png'),
('memory_echo_bridge','echo_bridge','stage_01','O nome da ponte','Uma avó contou que a ponte recebeu o nome de uma criança que ajudou a reconstruí-la.','Relato transmitido por uma pessoa mais velha','tradição oral como fonte','Relatos orais preservam lembranças e perspectivas. Registrar quem contou, quando e em que contexto ajuda a compreender a fonte.','assets/images/props/echo_fragment.png'),
('memory_echo_depths','echo_depths','stage_01','A praça das lanternas','Todo inverno, moradores acendiam lanternas na praça para receber quem voltava da viagem.','Lugar significativo para a comunidade','referências culturais','Um lugar pode importar por abrigar encontros e práticas coletivas, além de sua forma física.','assets/images/props/echo_fragment.png'),
('memory_echo_heart','echo_heart','stage_01','O coração emprestado','A luz só voltou quando várias pessoas trouxeram partes das próprias lembranças.','A comunidade reúne suas histórias','memória coletiva','A memória coletiva é construída e revisitada por grupos; não é uma única lembrança igual para todas as pessoas.','assets/images/props/echo_fragment.png'),
('memory_echo_secret','echo_secret','stage_01','A marca na parede','Pequenas linhas registram a altura de três gerações da mesma casa.','Marcas domésticas acumuladas no tempo','vestígios e fontes históricas','Marcas materiais podem ser fontes históricas quando interpretadas junto de relatos e contexto.','assets/images/props/echo_fragment.png'),
('memory_echo_return','echo_return','stage_01','Voltar pelo mesmo caminho','O caminho parecia outro quando o Errante ouviu as histórias de quem o atravessava.','A comunidade conta a história de um lugar','identidade e lugar','A relação entre pessoas, lembranças e lugares participa da construção de identidades individuais e coletivas.','assets/images/props/echo_fragment.png'),
('memory_galleries_gate','galleries_gate','stage_02','O portão de muitas mãos','As marcas na madeira mostram reparos feitos em épocas diferentes.','Reparos comunitários no portão','patrimônio cultural material','Bens físicos, como construções e objetos, podem ser referências importantes para a memória e a identidade de grupos.','assets/images/props/echo_fragment.png'),
('memory_galleries_wings','galleries_wings','stage_02','A canção das asas','Uma melodia guiava as mariposas até os faróis, e cada geração acrescentava um verso.','Canção transmitida e recriada','patrimônio cultural imaterial','Práticas, expressões e conhecimentos vivos podem ser transmitidos entre gerações e recriados pelas comunidades.','assets/images/props/echo_fragment.png'),
('memory_galleries_chain','galleries_chain','stage_02','O nó que não se esquece','Aprendizes observavam artesãos trançarem correntes sem molde escrito.','Aprendizagem artesanal','conhecimentos tradicionais','Saberes e modos de fazer são aprendidos na prática e transmitidos por pessoas; as comunidades também os transformam.','assets/images/props/echo_fragment.png'),
('memory_galleries_rupture','galleries_rupture','stage_02','A pedra que canta','Construtores escolheram pedras que vibravam juntas quando o vento passava.','Técnica de construção do Vale','patrimônio material e saber-fazer','Uma estrutura é material; o conhecimento de como construí-la e mantê-la é transmitido por pessoas. As dimensões se relacionam.','assets/images/props/echo_fragment.png'),
('memory_galleries_secret','galleries_secret','stage_02','A festa escondida','Mesmo sem o salão, vizinhos repetiam o gesto de acender uma luz para iniciar a celebração.','Celebração recriada pelas pessoas','continuidade cultural','Uma prática pode continuar mesmo quando o espaço muda; quem a pratica mantém e recria seus significados.','assets/images/props/echo_fragment.png'),
('memory_galleries_bridge','galleries_bridge','stage_02','A ponte ensinada','Cada pedra tinha uma forma; o encaixe era ensinado de pessoa para pessoa.','Técnica de construção partilhada','transmissão entre gerações','A preservação envolve cuidar de bens e apoiar as pessoas e comunidades que mantêm conhecimentos e práticas.','assets/images/props/echo_fragment.png'),
('memory_galleries_last','galleries_last','stage_02','Variações da mesma história','Duas aldeias cantavam a travessia de jeitos diferentes; ambas reconheciam a história.','Tradição musical com versões locais','diversidade cultural','Uma expressão pode ter variações. Diferenças entre comunidades não tornam uma versão menos significativa.','assets/images/props/echo_fragment.png'),
('memory_tower_threshold','tower_threshold','stage_03','O retrato sem moldura','Uma família guardou o retrato porque lembrava quem acolheu os viajantes.','Lembrança familiar de acolhimento','memória e pertencimento','Lembranças familiares ajudam a construir vínculos, mas cada pessoa pode recordar o mesmo acontecimento de modo diferente.','assets/images/props/echo_fragment.png'),
('memory_tower_glass','tower_glass','stage_03','A amizade que subiu a torre','Uma amiga deixou sinais para a seguinte, e as marcas continuaram sendo cuidadas por outras gerações.','Amizade lembrada ao longo do tempo','identidade coletiva','Histórias compartilhadas conectam pessoas e podem integrar a maneira como uma comunidade entende a si mesma.','assets/images/props/echo_fragment.png'),
('memory_tower_guardian','tower_guardian','stage_03','Ninguém guarda sozinho','O guardião anotava os relatos; quem os contava decidia o que precisava ser corrigido.','Comunidade revisa seu arquivo','responsabilidade compartilhada','Preservar memória exige participação e respeito às pessoas e grupos a quem ela pertence.','assets/images/props/echo_fragment.png'),
('memory_tower_shadow','tower_shadow','stage_03','O que a sombra escondia','Um relato antigo omitia parte da festa; novas vozes completaram e também questionaram a lembrança.','Uma memória revisada por diferentes vozes','fontes e perspectivas','Nenhuma fonte conta tudo. Comparar relatos e reconhecer quem fala ajuda a perceber lacunas e perspectivas distintas.','assets/images/props/echo_fragment.png'),
('memory_tower_alcove','tower_alcove','stage_03','O nicho das ferramentas','Ferramentas gastas guardavam sinais de quem as usou e ensinou a cuidar delas.','Ferramentas e conhecimento de manutenção','patrimônio material e imaterial','Um objeto preservado e o saber ligado a seu uso podem ser entendidos em conjunto, sem reduzir um ao outro.','assets/images/props/echo_fragment.png'),
('memory_tower_memory','tower_memory','stage_03','A lembrança que mudou','O Errante compreende que tentou manter aberta a passagem, mas perdeu a própria história no processo.','A escolha do Errante','continuidade cultural','A continuidade depende de pessoas que compartilham, cuidam e recriam suas memórias no presente.','assets/images/props/echo_fragment.png'),
('memory_tower_last','tower_last','stage_03','O nome devolvido','As vozes do Vale ajudam o Errante a recuperar partes de seu nome, sem decidir por ele quem deve ser.','As três fases se encontram no Vale','pertencimento e preservação','A identidade é pessoal e também se forma nas relações; preservar memórias amplia as possibilidades de transmiti-las.','assets/images/props/echo_fragment.png')
on conflict(id) do update set collectible_id=excluded.collectible_id,stage_id=excluded.stage_id,title=excluded.title,narrative=excluded.narrative,character_or_event=excluded.character_or_event,concept=excluded.concept,explanation=excluded.explanation,illustration_asset=excluded.illustration_asset;
update public.learning_checks set prompt='A família preservou um pote rachado. Que pista pode ajudar a descobrir sua história?',options='["A marca de tinta e o relato de quem o guardou", "A cor do céu no mapa", "A quantidade de pedras na ponte"]'::jsonb,feedback_correct='Isso. Um objeto é uma pista; relacioná-lo a relatos e contexto ajuda a reconstruir a história.',feedback_incorrect='O pote e a história de quem o preservou são pistas ligadas ao passado. Tente relacioná-las.',correct_index=0 where id='check_stage_01';
update public.learning_checks set prompt='Qual par liga um bem material a um saber imaterial associado?',options='["A ponte de pedra e o conhecimento de encaixar suas pedras", "A ponte e a cor do luar", "A canção e o número de degraus"]'::jsonb,feedback_correct='Certo. A ponte é física; o saber de construí-la é transmitido pelas pessoas. As duas dimensões podem se relacionar.',feedback_incorrect='Procure um bem físico e o conhecimento praticado para construí-lo ou cuidar dele.',correct_index=0 where id='check_stage_02';
update public.learning_checks set prompt='O arquivo registra versões diferentes de uma festa. Qual atitude ajuda a preservar essas memórias?',options='["Guardar as versões, ouvir quem as conta e registrar seu contexto", "Escolher uma versão e apagar as demais", "Deixar que só o guardião decida o significado"]'::jsonb,feedback_correct='Isso. Preservar envolve participação e contexto; versões diversas podem revelar diferentes perspectivas.',feedback_incorrect='Pense em como ouvir as pessoas envolvidas e manter visíveis as diferentes perspectivas.',correct_index=0 where id='check_stage_03';

commit;
