-- READ ONLY. Run as the responsible project owner before applying the migration.
-- Existing objects must be reconciled; IF NOT EXISTS does not validate shape.
select table_name,column_name,data_type,is_nullable
from information_schema.columns
where table_schema='public' and table_name in (
  'profiles','stages','collectibles','memory_entries','learning_checks',
  'user_learning_checks','achievements','user_stages','score_ledger',
  'stage_runs','personal_bests','user_collectibles','user_achievements',
  'user_memories','dialogue_progress','player_settings'
)
order by table_name,ordinal_position;

select schemaname,tablename,policyname,roles,cmd,qual,with_check
from pg_policies where schemaname='public' order by tablename,policyname;

select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) arguments,
  p.prosecdef security_definer,p.proconfig,p.proacl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname like 'echoes_%')
   or (n.nspname='private' and p.proname in ('record_stage_run','record_dialogues','answer_learning_check','start_stage','collect_echo','player_state','leaderboard','echoes_bootstrap','create_echoes_profile'))
order by 1,2;
