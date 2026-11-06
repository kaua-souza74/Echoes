import { PGlite } from '@electric-sql/pglite';
import { readFile, writeFile } from 'node:fs/promises';
import assert from 'node:assert/strict';

// Local PostgreSQL fixtures only. This is not a test against Supabase Auth.
const db = new PGlite();
const passed=[];
const check=(name,fn)=>async()=>{await fn();passed.push(name);console.log(`PASS ${name}`);};
const sql=async(query,args=[]) => (await db.query(query,args)).rows;
const scalar=async(query,args=[])=>Object.values((await sql(query,args))[0])[0];
const A='10000000-0000-4000-8000-000000000001',B='10000000-0000-4000-8000-000000000002';
const run=(n)=>`20000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
async function user(uid){await db.exec('reset role');await sql("select set_config('request.jwt.claim.sub',$1,false)",[uid]);await db.exec('set role authenticated');}
async function age(id){await db.exec('reset role');await sql("update public.stage_runs set started_at=clock_timestamp()-interval '5 minutes' where id=$1",[id]);}
async function begin(uid,n,stage='stage_01',mode='story',version=stage==='stage_01'?2:1){await user(uid);await sql('select public.echoes_start_stage($1,$2,$3,$4)',[run(n),stage,version,mode]);}
async function finish(uid,n,{stage='stage_01',version=stage==='stage_01'?2:1,mode='story',duration=60000,deaths=0,completed=true,echoes=['echo_heart']}={}){
  await age(run(n));await user(uid);
  return scalar('select public.echoes_record_stage_run($1,$2,$3,$4,$5,$6,$7,$8)',[run(n),stage,version,mode,duration,deaths,completed,echoes]);
}
const state=()=>scalar('select public.echoes_player_state()');
try{
  await db.exec(`create role anon nologin;create role authenticated nologin;create schema auth;
    create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;`);
  await db.exec(await readFile(new URL('../ECHOES_V2.2_FULL_SETUP.sql',import.meta.url),'utf8'));
  passed.push('complete SQL bundle executes on PostgreSQL');
  await check('catalog keeps all 21 authored collectible IDs',async()=>{
    const catalog=JSON.parse(await readFile(new URL('../../flutter_app/assets/narrative/memory_catalog.json',import.meta.url),'utf8'));
    assert.deepEqual((await sql('select id from public.collectibles order by id')).map(v=>v.id),catalog.entries.map(e=>e.collectible_id).sort());
    assert.equal(Number(await scalar('select count(*) from public.memory_entries')),21);
  })();
  await sql('insert into auth.users(id,email,raw_user_meta_data) values($1,$2,$3),($4,$5,$6)',[A,'a@example.test',{nickname:'Voz A'},B,'b@example.test',{nickname:'Voz B'}]);
  await check('all player tables enable RLS',async()=>assert.equal(Number(await scalar("select count(*) from pg_tables where schemaname='public' and not rowsecurity")),0))();
  await check('independent bootstrap profiles',async()=>{await user(A);assert.equal((await state()).points,0);assert.equal((await state()).nickname,'Voz A');await user(B);assert.equal((await state()).nickname,'Voz B');assert.deepEqual((await state()).stages,{stage_01:'available'});})();
  await check('locked chapters and wrong map versions rejected',async()=>{await user(B);await assert.rejects(sql('select public.echoes_start_stage($1,$2,1,$3)',[run(99),'stage_02','story']));await assert.rejects(sql('select public.echoes_start_stage($1,$2,99,$3)',[run(98),'stage_01','story']));})();
  await begin(A,1);
  await check('first Echo awards once and unlocks memory/achievement',async()=>{await sql('select public.echoes_collect_echo($1,$2)',[run(1),'echo_01']);await sql('select public.echoes_collect_echo($1,$2)',[run(1),'echo_01']);const p=await state();assert.equal(p.points,10);assert.deepEqual(p.memories,['memory_echo_01']);assert.ok(p.achievements.find(a=>a.id==='first_echo').unlocked_at);})();
  await check('arbitrary ledger and achievement writes forbidden',async()=>{await assert.rejects(sql("insert into public.score_ledger(user_id,source_type,source_id,points) values($1,'stage_first_clear','fake',999999)",[A]));await assert.rejects(sql("insert into public.user_achievements values($1,'last_echo',now())",[A]));})();
  await check('completion requires essential Echo and plausible duration',async()=>{await assert.rejects(finish(A,1,{echoes:[]}));await assert.rejects(finish(A,1,{duration:1}));})();
  await check('completion awards exactly stage reward plus unique Ecos',async()=>{await finish(A,1,{echoes:['echo_01','echo_heart']});const p=await state();assert.equal(p.points,120);assert.equal(p.stages.stage_01,'completed');assert.equal(p.stages.stage_02,'available');assert.ok(p.achievements.find(a=>a.id==='no_falls').unlocked_at);})();
  await check('duplicate submission and replay cannot farm points',async()=>{await finish(A,1,{echoes:['echo_01','echo_heart']});await begin(A,2);await finish(A,2);assert.equal((await state()).points,120);})();
  await check('speedrun best keeps fastest and earliest tied run',async()=>{await begin(A,3,'stage_01','speedrun');await finish(A,3,{mode:'speedrun',duration:50000});await begin(A,4,'stage_01','speedrun');await finish(A,4,{mode:'speedrun',duration:60000});await begin(A,5,'stage_01','speedrun');await finish(A,5,{mode:'speedrun',duration:50000});const p=await state();assert.equal(p.bests[0].duration_ms,50000);assert.equal(p.bests[0].run_id,run(3));})();
  await check('incomplete attempt is excluded from personal bests',async()=>{await begin(A,6,'stage_01','speedrun');await finish(A,6,{mode:'speedrun',completed:false,duration:30000,echoes:[]});assert.equal((await state()).bests[0].duration_ms,50000);})();
  await check('cross-account private rows and writes are denied',async()=>{await user(B);assert.equal((await state()).points,0);assert.equal(Number(await scalar('select count(*) from public.user_collectibles where user_id=$1',[A])),0);assert.equal((await sql('update public.player_settings set text_scale=1.5 where user_id=$1 returning user_id',[A])).length,0);await assert.rejects(sql('select public.echoes_collect_echo($1,$2)',[run(1),'echo_secret']));})();
  await begin(B,7);await finish(B,7,{duration:70000,echoes:['echo_01','echo_heart']});
  await check('ranking uses real aggregate totals, stable ties, and no emails',async()=>{const rows=await sql("select * from public.echoes_leaderboard('points','stage_01')");assert.equal(rows.length,2);assert.equal(rows[0].player_id,A);assert.equal(rows[0].result,120);assert.equal(Object.keys(rows[0]).includes('email'),false);})();
  await check('combined ranking requires all three current versions',async()=>{assert.equal((await sql("select * from public.echoes_leaderboard('combined','stage_01')")).length,0);await begin(A,8,'stage_02','speedrun');await finish(A,8,{stage:'stage_02',mode:'speedrun',echoes:['galleries_rupture']});await begin(A,9,'stage_03','speedrun');await finish(A,9,{stage:'stage_03',mode:'speedrun',duration:70000,echoes:['tower_memory','tower_last']});const rows=await sql("select * from public.echoes_leaderboard('combined','stage_01')");assert.equal(rows.length,1);assert.equal(rows[0].result,180000);})();
  await check('learning feedback persists per account',async()=>{const answer=await scalar("select public.echoes_answer_learning_check('check_stage_02',0::smallint)");assert.equal(answer.correct,true);assert.ok((await state()).learning_checks.includes('check_stage_02'));assert.ok((await state()).achievements.find(a=>a.id==='heritage_guardian').unlocked_at);})();
  await check('settings persist and remain independent',async()=>{await sql('update public.player_settings set text_scale=1.3,show_timer=false where user_id=$1',[A]);await user(B);assert.equal((await state()).settings.text_scale,1);await user(A);assert.equal((await state()).settings.text_scale,1.3);})();
  await check('client runs remain explicitly unverified',async()=>assert.equal(Number(await scalar('select count(*) from public.stage_runs where verified')),0))();
  await check('anonymous RPC and private view access forbidden',async()=>{await db.exec('reset role;set role anon');await assert.rejects(sql('select public.echoes_player_state()'));await assert.rejects(sql('select * from public.public_leaderboard'));})();
  const report={engine:'PGlite PostgreSQL; simulated auth.uid and two local users',remoteSupabaseValidated:false,passed:passed.length,checks:passed};
  await writeFile(new URL('report.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
  console.log(`All ${passed.length} PostgreSQL checks passed.`);
}catch(error){console.error(error.message);process.exitCode=1;}finally{await db.close();}
