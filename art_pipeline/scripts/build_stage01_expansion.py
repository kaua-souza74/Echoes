"""Authored five-section map and original transparent narrative crystal."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
APP=ROOT/'flutter_app'
# Each row is an authored landing, not procedural obstacle repetition.
# The first four landings preserve the original vertical slice.
route=[
 (0,384,352,128),(448,320,192,64),(704,256,160,64),(992,192,288,96),
 (1376,256,256,96),(1728,320,224,64),(2048,256,192,64),(2336,192,256,96),
 (2688,256,192,64),(2976,320,320,96),(3392,384,224,96),
 (3712,448,256,64),(4064,384,192,64),(4352,320,192,64),(4640,256,256,96),
 (4992,320,192,64),(5280,384,256,64),(5632,448,320,96),
 (6048,512,320,96),(6464,448,192,64),(6752,384,224,64),(7072,320,320,96),
 (7488,384,224,64),(7808,448,384,96),
 (8288,384,192,64),(8576,320,192,64),(8864,256,256,96),
 (9216,320,224,64),(9536,384,224,96),(9856,320,192,64),
 (10144,256,224,64),(10464,192,256,96),(10816,256,224,64),(11136,320,512,128),
]
# Optional upper branches reconnect to the main route and reward exploration.
branches=[(1344,192,96,32),(2912,256,96,32),(5216,320,96,32),(7744,384,96,32),(9472,320,96,32),
 (1440,128,128,32),(1664,64,128,32),(1888,128,128,32),
 (3008,192,128,32),(3232,128,128,32),(3456,192,128,32),
 (5312,256,128,32),(5536,192,128,32),(5760,256,128,32),
 (7840,320,128,32),(8064,256,128,32),(8288,256,128,32),
 (9568,256,128,32),(9792,192,128,32),(10016,128,128,32)]
sections=[
 ('O Primeiro Suspiro',0,1376,'intro'),
 ('Ruínas Silenciosas',1376,3712,'ruins'),
 ('A Ponte Esquecida',3712,6048,'bridge'),
 ('O Coração Adormecido',6048,8288,'heart'),
 ('A Passagem',8288,11776,'passage')]
props=[]
for order,(x,y,label) in enumerate([(120,384,'Primeira Centelha'),(1432,256,'Ruínas Silenciosas'),(3768,448,'Ponte Esquecida'),(6104,512,'Coração Adormecido'),(8344,384,'A Passagem')]):
 props.append(dict(type='checkpoint',id=f'checkpoint_{order}',x=x,y=y,label=label,order=order))
for code,x,y,label in [('echo_01',848,240,'Primeira Voz'),('echo_roots',1728,40,'Raízes do Silêncio'),('echo_bridge',3296,104,'Pedra Suspensa'),('echo_depths',5600,168,'Sob a Ponte'),('echo_heart',7232,296,'O Coração'),('echo_secret',8128,232,'Um Nome Esquecido'),('echo_return',10080,104,'A Promessa')]:
 props.append(dict(type='echo',id=code,x=x,y=y,label=label))
props.append(dict(type='checkpoint_final',id='goal',x=11552,y=320,label='A Passagem',order=5))
layers=json.loads((APP/'assets/images/levels/stage_01_awakening_layout.json').read_text(encoding='utf-8'))['layers']
data=dict(schema=2,id='stage_01',title='O Despertar',version=2,width=11776,height=1024,spawn=[64,384],
 layers=[x for x in layers if x['name']!='world'],solids=route+branches,props=props,
 required_echoes=['echo_heart'],sections=[dict(name=n,start=a,end=b,motif=m) for n,a,b,m in sections],
 main_route=list(range(len(route))),branches=list(range(len(route),len(route)+len(branches))),
 narrative_triggers=[dict(id='awakening',x=120,y=384,radius=90,sequence='awakening'),dict(id='bridge',x=3840,y=448,radius=320,vertical_radius=400,sequence='bridge'),dict(id='heart',x=7232,y=320,radius=70,sequence='heart'),dict(id='passage',x=11472,y=320,radius=64,sequence='passage')])
dest=APP/'assets/levels';dest.mkdir(parents=True,exist_ok=True)
(dest/'stage_01.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
dialogues={
 'awakening':dict(speaker='Eco Desconhecido',lines=['Devagar… A pedra ainda se lembra do seu peso.','Havia vozes nestas galerias. Agora, só a luz encontra o caminho.','Se ouvir o próprio nome, não o deixe desaparecer.']),
 'bridge':dict(speaker='Memória da Ponte',lines=['Esta ponte carregava mais que passos. Cada pedra guardava uma despedida.','Você atravessou aqui antes. Eu reconheço a maneira como hesita.']),
 'heart':dict(speaker='Coração do Lume',lines=['Não foi a escuridão que nos calou. Alguém pediu ao Lume que esquecesse.','Você guardava a porta quando as vozes se partiram.','Não sei se tentou nos salvar… Só lembro que ficou.']),
 'passage':dict(speaker='Eco Desconhecido',lines=['As correntes além desta passagem ainda se movem.','Leve esta lembrança. O que dorme nas Galerias sabe quem você foi.'])}
dest=APP/'assets/narrative';dest.mkdir(parents=True,exist_ok=True)
existing_dialogues=json.loads((dest/'dialogues.json').read_text(encoding='utf-8')) if (dest/'dialogues.json').exists() else {}
existing_dialogues.update(dialogues)
(dest/'dialogues.json').write_text(json.dumps(existing_dialogues,ensure_ascii=False,indent=2),encoding='utf-8')
# Faceted crystal portrait: genuine RGBA, pixel clusters, no backdrop rectangle.
im=Image.new('RGBA',(128,160));d=ImageDraw.Draw(im)
for r,a in [(58,3),(48,5),(39,8),(30,13)]:d.ellipse((64-r,77-r,64+r,77+r),fill=(80,180,195,a))
d.polygon([(62,12),(87,42),(94,83),(76,128),(62,145),(41,119),(31,75),(43,35)],fill='#24495e')
d.polygon([(62,15),(67,63),(49,91),(43,39)],fill='#86c9d1')
d.polygon([(65,18),(86,44),(80,76),(67,63)],fill='#cee8df')
d.polygon([(67,64),(80,76),(75,124),(63,143),(57,103)],fill='#5fadb9')
d.polygon([(43,40),(49,91),(41,116),(33,74)],fill='#43899d')
d.polygon([(50,94),(57,104),(63,141),(44,118)],fill='#91d8d7')
d.line([(62,22),(66,63),(56,91)],fill='#e4f2e7',width=2)
d.polygon([(18,60),(25,46),(29,66),(24,83)],fill='#5b9daf')
d.polygon([(102,87),(112,72),(109,106),(101,114)],fill='#5b9daf')
for x,y in [(23,32),(101,38),(15,109),(91,138),(43,12)]:d.rectangle((x,y,x+1,y+1),fill='#b4dcd5')
dest=APP/'assets/images/narrative';dest.mkdir(parents=True,exist_ok=True)
im.save(dest/'memory_portrait.png')
print(f'Authored {len(route)} main landings, {len(branches)} optional landings, {len(props)} props, 4 dialogue sequences.')
