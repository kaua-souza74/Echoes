"""ECHOES V2.1: authored worlds, original tiles, ambient creatures and narrative."""
from pathlib import Path
import json, math, random
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]; APP=ROOT/'flutter_app'; OUT=APP/'assets/images'

def save(im,p): p.parent.mkdir(parents=True,exist_ok=True);im.save(p,optimize=True)
def write(p,d): p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
class World:
 def __init__(self,id,title,width,height):
  self.d=dict(schema=3,id=id,title=title,version=1,width=width,height=height,solids=[],temporary_platforms=[],props=[],sections=[],narrative_triggers=[],route=[],shafts=[],ambient_actors=[],ambient_events=[],camera={'look_ahead':48,'follow_rate':7},tile_asset=f'tilesets/{id}_ruins_tiles.png')
 def ledge(self,id,x,y,w,h=64,temporary=False,route=True,target_x=None):
  r=dict(id=id,x=x,y=y,width=w,height=h)
  if temporary:r.update(break_after=1.1,recover_after=3);self.d['temporary_platforms'].append(r)
  else:self.d['solids'].append(r)
  if route:self.d['route'].append(dict(kind='landing',surface=id,**({'x':target_x} if target_x is not None else {})))
 def shaft(self,id,x,base,top,exit_id,exit_x,direction=1):
  self.ledge(id+'_left',x-80,top,32,base-top-48,route=False)
  self.ledge(id+'_right',x+80,top,32,base-top,route=False)
  self.d['route'].append(dict(kind='shaft',id=id,x=x+16,top=top,exit_surface=exit_id,exit_x=exit_x,direction=direction))
  self.d['shafts'].append(dict(id=id,left=x-48,right=x+80,top=top,bottom=base))
 def checkpoint(self,x,y,name):
  n=sum(p['type']=='checkpoint' for p in self.d['props']);self.d['props'].append(dict(type='checkpoint',id=f"{self.d['id']}_cp_{n}",x=x,y=y,label=name,order=n))
 def echo(self,id,x,y,name):self.d['props'].append(dict(type='echo',id=id,x=x,y=y,label=name))
 def story(self,id,x,y,r=100,vr=80):self.d['narrative_triggers'].append(dict(id=id,sequence=id,x=x,y=y,radius=r,vertical_radius=vr))
 def finish(self,x,y,required,sequence):
  self.d['props'].append(dict(type='checkpoint_final',id=self.d['id']+'_goal',x=x,y=y,label='Farol do Lume',order=99))
  self.d['required_echoes']=required;self.d['final_sequence']=sequence
 def section(self,name,x0,x1,y0,y1):self.d['sections'].append(dict(name=name,start=x0,end=x1,top=y0,bottom=y1))

g=World('stage_02','Galerias Quebradas',8448,2304);g.d.update(spawn=[96,1792],checkpoint_fall_limit=768)
G=[(0,1792,384),(480,1728,224),(800,1664,224),(1120,1600,256),(1472,1664,320),
 (1888,1600,224),(2208,1536,192),(2496,1472,192),(2784,1536,192),(3072,1600,224),(3296,1792,416)]
for i,(x,y,w) in enumerate(G):g.ledge(f'g{i}',x,y,w,128 if i==0 else 64,temporary=i==7,target_x=3616 if i==10 else None)
g.shaft('chain_well',3600,1792,1152,'g11',3856)
for i,(x,y,w) in enumerate([(3712,1152,320),(4128,1088,192),(4416,1024,192),(4704,960,256),(5056,1024,224),(5376,1088,224),(5696,1024,224),(6016,960,160),(6272,896,256),(6624,960,192),(6912,1024,160),(7168,960,192),(7456,896,224),(7776,960,512)],11):g.ledge(f'g{i}',x,y,w,temporary=i in [13,18,21])
for id,x,y,w in [('gb0',1408,1600,96),('gb1',1536,1536,128),('gb2',1760,1472,128),('gb3',1920,1536,96),('gb4',6368,832,96),('gb5',6528,768,128),('gb6',6752,832,128)]:g.ledge(id,x,y,w,32,route=False)
for args in [(96,1792,'Entrada das Galerias'),(1568,1664,'Passagens Suspensas'),(3616,1792,'Abismo das Correntes'),(3856,1152,'Câmara da Ruptura'),(6336,896,'A Última Travessia')]:g.checkpoint(*args)
for args in [('galleries_gate',912,1640,'O Reino Suspenso'),('galleries_wings',1824,1448,'Habitantes do Vazio'),('galleries_chain',3616,1410,'O Peso do Silêncio'),('galleries_rupture',4832,936,'A Ruptura'),('galleries_secret',6592,744,'Ferro e Raiz'),('galleries_bridge',7568,872,'A Travessia'),('galleries_last',8000,936,'O Chamado da Torre')]:g.echo(*args)
for a in [('Entrada das Galerias',0,1792,0,2304),('Passagens Suspensas',1792,3296,0,2304),('Abismo das Correntes',3296,4080,1200,2304),('Câmara da Ruptura',3296,5696,0,1200),('A Última Travessia',5696,8448,0,2304)]:g.section(*a)
g.story('g_entry',120,1792);g.story('g_wings',1568,1664);g.story('g_depth',3616,1792,90);g.story('g_rupture',4832,960)
g.finish(8160,960,['galleries_rupture'],'g_exit')
g.d['ambient_events']=[dict(id='colossus',kind='crossing',sprite='colossus',x=3296,y=800,width=700,height=1200,duration=28)]
g.d['ambient_actors']=[dict(sprite='moth',x=130,y=100,factor=.12,opacity=.5),dict(sprite='crawler',x=490,y=220,factor=.32,opacity=.6)]
g.d['layers']=[dict(asset='parallax/stage_02/'+n,parallax=f,parallax_y=fy) for n,f,fy in [('01_petroil_void.png',.035,.015),('02_suspended_galleries.png',.18,.07),('03_chains_and_windbreaks.png',.47,.14),('04_wind_haze.png',.68,.20)]]

t=World('stage_03','Torre do Eco',2560,5632);t.d.update(spawn=[384,5376],checkpoint_fall_limit=640)
T=[(256,5376,512),(864,5312,224),(1184,5248,224),(1504,5184,256),(1856,5120,480)]
for i,(x,y,w) in enumerate(T):t.ledge(f't{i}',x,y,w,128 if i==0 else 64,target_x=2216 if i==4 else None)
t.shaft('lower_lancet',2192,5120,4480,'t5',1984,-1)
T2=[(1856,4480,256),(1536,4416,224),(1216,4352,224),(896,4288,224),(576,4224,224),(256,4160,224),(128,4096,64),(0,4032,64),(128,3968,64),(288,3904,224),(608,3840,224),(928,3776,224),(1248,3712,224),(1568,3648,224),(1888,3584,480)]
for i,(x,y,w) in enumerate(T2,5):t.ledge(f't{i}',x,y,w,32 if w==64 else 64,temporary=i in [7,15],target_x=2216 if i==19 else None)
t.shaft('broken_stair',2192,3584,2944,'t20',1984,-1)
T3=[(1856,2944,256),(1536,2880,224),(1216,2816,224),(896,2752,224),(576,2688,224),(256,2624,224),(128,2560,64),(0,2496,64),(128,2432,64),(288,2368,224),(608,2304,224),(928,2240,320),(1344,2176,224),(1664,2112,224),(1984,2048,384)]
for i,(x,y,w) in enumerate(T3,20):t.ledge(f't{i}',x,y,w,32 if w==64 else 64,temporary=i==23,target_x=2216 if i==34 else None)
t.shaft('memory_lancet',2192,2048,1536,'t35',1984,-1)
T4=[(1856,1536,256),(1536,1472,224),(1216,1408,224),(896,1344,224),(576,1280,224),(256,1216,224),(128,1152,64),(0,1088,64),(128,1024,64),(288,960,224),(608,896,224),(928,832,224),(1248,768,512)]
for i,(x,y,w) in enumerate(T4,35):t.ledge(f't{i}',x,y,w,32 if w==64 else 64,temporary=i==37)
for id,x,y,w in [('tb0',2400,4416,160),('tb1',2400,2880,160),('tb2',160,2688,64)]:t.ledge(id,x,y,w,32,route=False)
for a in [(384,5376,'Base da Torre'),(1984,4480,'Salão dos Fragmentos'),(1984,2944,'Escadaria Partida'),(1088,2240,'Câmara das Memórias'),(1984,1536,'O Último Eco')]:t.checkpoint(*a)
for a in [('tower_threshold',1296,5224,'O Limiar'),('tower_glass',2480,4392,'Vidro Vivo'),('tower_guardian',1616,3624,'Os Guardiões'),('tower_shadow',2480,2856,'A Voz Ausente'),('tower_alcove',192,2664,'O Nome Riscado'),('tower_memory',1088,2216,'A Memória Alterada'),('tower_last',1440,744,'O Último Eco')]:t.echo(*a)
for name,y0,y1 in [('Base da Torre',4481,5632),('Salão dos Fragmentos',2945,4481),('Escadaria Partida',2369,2945),('Câmara das Memórias',1537,2369),('O Último Eco',0,1537)]:t.section(name,0,2560,y0,y1)
t.story('t_base',416,5376);t.story('t_fragments',1984,4480);t.story('t_guardians',1984,2944);t.story('t_memory',1088,2240)
t.finish(1632,768,['tower_memory','tower_last'],'t_final')
t.d['ambient_events']=[dict(id='revelation',kind='light',sprite='spirit',x=1248,y=600,width=512,height=300,duration=30)]
t.d['ambient_actors']=[dict(sprite='spirit',x=170,y=115,factor=.08,opacity=.58),dict(sprite='spirit',x=510,y=230,factor=.24,opacity=.4)]
t.d['layers']=[dict(asset='parallax/stage_03/'+n,parallax=f,parallax_y=fy) for n,f,fy in [('01_indigo_aperture.png',.025,.035),('02_echo_tower.png',.11,.12),('03_shattered_lancets.png',.32,.24),('04_silver_mist.png',.55,.34)]]
write(APP/'assets/levels/stage_02.json',g.d);write(APP/'assets/levels/stage_03.json',t.d)

dialogue_path=APP/'assets/narrative/dialogues.json';d=json.loads(dialogue_path.read_text(encoding='utf-8'))
new={
'g_entry':('Memória da Galeria',['O reino não terminava na pedra. Erguemos estas pontes para escutar o que havia do outro lado.','Depois do Silêncio, continuaram suspensas. Como uma pergunta sem resposta.']),
'g_wings':('Eco das Asas',['Elas chegaram quando nossas vozes desapareceram. Nunca atacaram os faróis.','Talvez estejam esperando que voltemos a acendê-los.']),
'g_depth':('O Vigia das Correntes',['Não faça ruído por medo. Aquele que cruza o abismo conhece o som dos seus passos.','Ele viu você partir… E guardou este caminho.']),
'g_rupture':('Memória da Ruptura',['Esse impulso não rompe o ar. Por um instante, você atravessa o lugar onde uma lembrança deveria estar.','A primeira fenda tinha a forma da sua mão.']),
'g_exit':('Eco da Travessia',['A Torre ainda responde aos guardiões. Foi por isso que ela chamou você.','Quando chegar ao alto, pergunte o que pediram que você esquecesse.']),
't_base':('A Voz da Torre',['Você voltou com o mesmo silêncio. Mas ele já não pesa como antes.','Suba. Há uma memória que não consegui apagar.']),
't_fragments':('Memória do Vidro',['Cada janela guardava uma vida. Os guardiões não possuíam o Lume: davam abrigo a ele.','Quando a luz se partiu, alguém escolheu quais vidas ainda seriam lembradas.']),
't_guardians':('Voz dos Guardiões',['Você estava entre nós. Reconheço a centelha sob o seu manto.','A ordem era fechar a câmara. Você abriu a porta.']),
't_memory':('A Memória Alterada',['Queriam preservar o reino retirando dele toda dor. O Lume também teria levado o amor, os nomes, as despedidas.','Você quebrou o selo para impedir o esquecimento. Mas a luz não voltou inteira.','Sua própria memória foi o preço de manter aberta uma passagem.']),
't_final':('O Último Eco',['O mundo não esqueceu você por acaso. Foi a promessa que fez à luz: ninguém carregaria sozinho a lembrança daquela noite.','Eu guardei um fragmento do seu nome. Ainda não sei se ele pode ser devolvido.','Leve os outros de volta ao vale. Desta vez, escolha o que merece ser lembrado.'])}
for key,(speaker,lines) in new.items():d[key]=dict(speaker=speaker,lines=lines)
write(dialogue_path,d)

def atlas(stage,pal,style):
 im=Image.new('RGBA',(256,160));dr=ImageDraw.Draw(im);rng=random.Random(style+701)
 dark,stone,edge,accent=pal
 for tid in range(40):
  x=(tid%8)*32;y=(tid//8)*32
  dr.rectangle((x,y,x+31,y+31),fill=stone)
  dr.line((x,y+3,x+31,y+3),fill=edge,width=2)
  if style==2:
   dr.rectangle((x+2,y+8,x+29,y+29),outline=dark)
   for sx in [5,26]:
    for sy in [10,25]:dr.rectangle((x+sx,y+sy,x+sx+1,y+sy+1),fill=accent)
   if tid//8==2:dr.line([(x+4,y+28),(x+16,y+12),(x+27,y+28)],fill=edge,width=2)
   if tid//8==4:
    for off in range(3):dr.line((x+7+off*7,y+11,x+7+off*7,y+24),fill=accent)
  else:
   dr.line((x+3,y+7,x+3,y+28),fill=edge)
   dr.line((x+28,y+7,x+28,y+28),fill=dark)
   if tid//8 in [2,4]:
    dr.polygon([(x+16,y+9),(x+23,y+18),(x+16,y+27),(x+9,y+18)],outline=accent)
    dr.line((x+16,y+13,x+16,y+22),fill=edge)
   else:
    dr.line((x+8,y+12,x+23,y+12),fill=dark)
    dr.line((x+10,y+24,x+21,y+24),fill=accent)
  # Clustered wear, inset masonry and hand-cut fractures keep repeated cells legible.
  for band in range(3):
   yy=y+9+band*8
   if style==3:
    seam=x+(10 if (band+tid)%2 else 22)
    dr.line((x+4,yy,x+27,yy),fill=dark)
    dr.line((seam,yy,seam,yy+6),fill=dark)
    dr.line((x+5,yy+1,x+12,yy+1),fill=edge)
   else:
    rx=x+rng.randrange(4,24)
    dr.line((rx,yy,rx+3,yy+1),fill=dark)
    dr.point((rx,yy+2),fill=accent)
  if tid%3==0:
   cx=x+18+tid%5
   dr.line([(cx,y+5),(cx-3,y+11),(cx+1,y+15),(cx-2,y+21)],fill=dark)
   dr.point((cx-2,y+11),fill=edge)
  for chip in range(3):
   cx=x+2+rng.randrange(28)
   dr.line((cx,y+4,cx+1,y+4),fill=dark)
  for _ in range(6):
   px=x+rng.randrange(2,29);py=y+rng.randrange(7,30);dr.point((px,py),fill=edge if _%3 else dark)
 save(im,OUT/f'tilesets/{stage}_ruins_tiles.png')
 write(OUT/f'tilesets/{stage}_ruins_tiles.json',dict(tile_size=[32,32],columns=8,rows=5,style='riveted_iron' if style==2 else 'lancet_stone'))
atlas('stage_02',('#12282e','#29454a','#5d7976','#9d8b65'),2)
atlas('stage_03',('#181e37','#343c58','#7d94a7','#a89772'),3)

for stage,col in [('stage_02',(86,143,142)),('stage_03',(127,160,190))]:
 im=Image.new('RGBA',(640,360));dr=ImageDraw.Draw(im)
 for k in range(6):
  y=120+k*36;x=(k*113)%640
  dr.polygon([(x-60,y),(x+80,y-8),(x+202,y+4),(x+62,y+11)],fill=(*col,8+k%3*4))
 if stage=='stage_03':
  for x in [84,310,541]:dr.polygon([(x,0),(x+3,0),(x+37,310),(x+20,310)],fill=(*col,15))
 save(im,OUT/f'parallax/{stage}'/('04_wind_haze.png' if stage=='stage_02' else '04_silver_mist.png'))

# Original background entities; animation is intentionally contemplative.
for name,w,h in [('crawler',80,40),('spirit',64,80),('colossus',320,144)]:
 sheet=Image.new('RGBA',(w*4,h))
 for i in range(4):
  fr=Image.new('RGBA',(w,h));dr=ImageDraw.Draw(fr);s=[0,1,0,-1][i]
  if name=='crawler':
   dr.polygon([(10,22),(25,13),(49,12),(66,20),(50,27),(22,29)],fill='#29434a')
   for j in range(5):dr.line([(18+j*9,24),(15+j*9+s,33),(9+j*9+s,35)],fill='#456366',width=2)
   dr.rectangle((54,18,56,19),fill='#99b6a1')
  elif name=='spirit':
   dr.polygon([(31,7),(44,26),(40,47),(32,69),(23,48),(20,28)],fill=(80,116,152,130))
   dr.polygon([(32,13),(36,31),(32,52),(28,32)],fill=(146,206,211,210))
   dr.polygon([(10,31+s),(16,23+s),(17,38+s),(13,44+s)],fill=(104,153,185,150))
   dr.polygon([(50,44-s),(55,37-s),(54,54-s),(49,61-s)],fill=(104,153,185,150))
   dr.line((31,20,32,39),fill='#d4e6da',width=1)
  else:
   dr.polygon([(18,72),(60,36),(116,24),(165,38),(206,24),(263,41),(303,67),(273,88),(224,100),(173,94),(128,110),(75,99)],fill='#1f3943')
   dr.polygon([(43,63),(88,21+s*3),(135,14),(158,31),(111,42),(78,69)],fill='#304d56')
   dr.polygon([(164,50),(217,13-s*3),(261,24),(285,52),(240,46),(210,65)],fill='#304d56')
   for j in range(8):
    x=71+j*24;dr.line([(x,87),(x-12+s*3,112),(x-20+s*4,128-j%3*4)],fill='#35545c',width=3)
   for x,y in [(265,60),(272,61)]:dr.rectangle((x,y,x+2,y+1),fill='#9bbaa8')
   dr.line([(63,72),(118,58),(172,69),(223,60)],fill='#45636a',width=2)
  sheet.alpha_composite(fr,(i*w,0))
 save(sheet,OUT/f'background_creatures/worlds/{name}.png')
print('Worlds built:',[(w.d['id'],len(w.d['solids']),len(w.d['temporary_platforms']),len(w.d['props'])) for w in [g,t]])
