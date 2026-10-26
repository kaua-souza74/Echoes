#!/usr/bin/env python3
"""Deterministic pixel-art environment pass for ECHOES (Pillow only)."""
from pathlib import Path
import json
import math
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "flutter_app" / "assets" / "images"
S1 = OUT / "parallax" / "stage_01"
P = {
    "void": "#080f1a", "deep": "#0c1723", "deep2": "#101d2b",
    "far": "#142534", "far2": "#1b3040", "stone": "#243949",
    "stone2": "#304b5c", "edge": "#496779", "lit": "#70909b",
    "cyan0": "#387984", "cyan": "#5da9b4", "lume": "#91d8dc",
    "white": "#d0e8dc", "moss": "#29473e", "moss2": "#3c6252",
    "rust": "#645444", "gold": "#988363", "violet": "#4c465f",
    "haze": "#7595a1",
}

def rgba(v, a=255):
    if isinstance(v, tuple): return (*v[:3], a)
    v = v.lstrip("#")
    return (*tuple(int(v[i:i+2],16) for i in (0,2,4)), a)

def canvas(size=(640,360), color=(0,0,0,0)):
    return Image.new("RGBA", size, color)

def poly(d, pts, col): d.polygon(pts, fill=col)
def rect(d, box, col): d.rectangle(box, fill=col)
def line(d, pts, col, width=1): d.line(pts, fill=col, width=width)
def save(im, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)

def speckles(im, seed, count, box, colors, max_size=2):
    rng=random.Random(seed); layer=canvas(im.size); d=ImageDraw.Draw(layer)
    for _ in range(count):
        x=rng.randrange(box[0],box[2]); y=rng.randrange(box[1],box[3])
        w=rng.choice([1,1,1,max_size]); h=rng.choice([1,1,2])
        rect(d,(x,y,x+w-1,y+h-1),rng.choice(colors))
    im.alpha_composite(layer)

def stage1_layers():
    # Deep void: restrained mineral bands, distant luminous vents and suspended dust.
    im=canvas((640,360)); d=ImageDraw.Draw(im)
    for y in range(360):
        t=y/359
        c=(8+int(7*t),15+int(12*t),26+int(17*t),255)
        line(d,[(0,y),(639,y)],c)
    # Far cavern shelves form a broad, quiet basin, keeping the center readable.
    poly(d,[(0,141),(42,127),(76,132),(112,110),(153,118),(187,98),(225,110),(272,91),(319,110),(369,95),(405,119),(451,105),(490,127),(530,104),(569,119),(608,100),(639,112),(639,244),(0,244)],P["deep"])
    poly(d,[(0,175),(55,158),(93,166),(139,143),(177,157),(222,138),(263,150),(313,129),(355,148),(400,136),(445,159),(486,143),(534,166),(577,145),(639,163),(639,255),(0,255)],P["deep2"])
    speckles(im,104,94,(0,36,640,214),[(62,103,126,55),(105,142,154,50),(46,78,101,80)],1)
    d=ImageDraw.Draw(im)
    # Narrow Lume seep in the distant rock; square-edged bands instead of blur.
    glow=canvas((640,360)); gd=ImageDraw.Draw(glow)
    for x,y in [(104,182),(536,155),(322,112)]:
        rect(gd,(x-1,y,x+1,y+16),(49,118,129,30)); rect(gd,(x,y+3,x,y+8),(105,190,194,65))
    im.alpha_composite(glow)
    save(im,S1/"01_sky_mist.png")

    # Far architecture: an enormous fractured ring nested inside eroded cavern walls.
    im=canvas(); d=ImageDraw.Draw(im)
    poly(d,[(0,158),(40,139),(78,149),(113,101),(160,89),(189,109),(217,80),(258,67),(289,84),(320,122),(347,107),(381,71),(419,62),(454,88),(476,133),(512,115),(547,86),(582,94),(613,132),(639,119),(639,360),(0,360)],P["deep2"])
    # Ring mass and inner cutout, deliberately asymmetrical and broken at its crown.
    poly(d,[(157,194),(171,129),(205,82),(252,56),(307,49),(359,64),(399,101),(426,153),(439,213),(414,213),(405,158),(377,117),(346,91),(307,80),(267,86),(227,105),(198,139),(186,195)],P["far"])
    poly(d,[(190,197),(202,144),(231,111),(267,94),(305,89),(344,101),(373,126),(396,162),(405,202),(389,202),(378,165),(354,139),(327,121),(299,116),(270,121),(242,139),(220,162),(213,200)],P["deep"])
    # Missing stones at the arch summit and stepped masonry seams.
    poly(d,[(238,78),(254,66),(270,61),(270,75),(255,83)],P["deep2"])
    poly(d,[(368,81),(385,92),(397,107),(383,111),(371,101)],P["deep2"])
    for x,y,w in [(36,172,49),(82,151,31),(469,161,45),(547,148,51),(605,171,33)]:
        rect(d,(x,y,x+w,y+188),P["far"]); rect(d,(x-5,y-4,x+w+5,y+5),P["stone"])
        rect(d,(x-2,y-7,x+w+2,y-4),P["edge"])
        for yy in range(y+19,350,27):
            rect(d,(x+6,yy,x+w-6,yy+1),P["stone2"])
            if (yy//27)%2: rect(d,(x+9,yy+2,x+10,yy+6),P["deep2"])
    # A far bridge disappears into the arch; broken ends sell scale.
    rect(d,(0,217,184,224),P["far"]); rect(d,(405,211,639,219),P["far"])
    for x in range(14,174,28): rect(d,(x,218,x+12,220),P["stone2"])
    for x in range(430,632,31): rect(d,(x,212,x+15,214),P["stone2"])
    # tiny distant watcher, a clear pair of eyes with a tapered mantle silhouette.
    poly(d,[(311,173),(317,165),(324,165),(330,172),(327,184),(323,190),(320,182),(316,190),(313,182)],(14,31,42,245))
    rect(d,(316,171,317,172),(117,205,207,180)); rect(d,(323,171,324,172),(117,205,207,180))
    speckles(im,108,50,(0,195,640,350),[(73,112,129,110),(52,91,110,130)],2)
    save(im,S1/"02_far_architecture.png")

    # Mid architecture: cutaway galleries, lintels, stone niches and small Lume marks.
    im=canvas(); d=ImageDraw.Draw(im)
    # high broken gallery, with a readable empty central passage
    poly(d,[(0,193),(24,180),(46,184),(65,152),(88,146),(109,165),(126,153),(147,157),(163,191),(163,360),(0,360)],(22,39,53,235))
    poly(d,[(478,189),(500,159),(527,151),(549,170),(570,143),(595,150),(615,173),(639,159),(639,360),(478,360)],(22,39,53,235))
    # Bridge fragments frame the playable center rather than crossing it.
    for x,y,w in [(0,221,125),(161,246,89),(396,234,92),(530,216,110)]:
        rect(d,(x,y,x+w,y+10),(34,57,72,230)); rect(d,(x,y,x+w,y+2),(78,107,119,180))
        for k in range(5):
            xx=x+8+k*max(10,w//5)
            if xx<x+w-4: rect(d,(xx,y+6,xx+5,y+8),(20,38,51,230))
    # Pier stacks with differentiated capitals and carved runes.
    for x,y,h in [(42,182,138),(116,207,151),(171,239,121),(442,226,133),(512,185,173),(586,204,154)]:
        rect(d,(x,y,x+22,y+h),(30,51,66,245)); rect(d,(x-5,y-5,x+27,y+3),(55,78,91,245))
        rect(d,(x-2,y-8,x+24,y-5),(94,120,128,210))
        for yy in range(y+14,y+h-5,24):
            line(d,[(x+4,yy),(x+17,yy+2),(x+17,yy+4)],(73,99,109,210))
        if x in (116,512):
            poly(d,[(x+11,y+40),(x+16,y+47),(x+11,y+54),(x+6,y+47)],(51,101,109,220))
            rect(d,(x+10,y+45,x+12,y+48),(127,202,199,200))
    # recessed door shapes and carved horizontal stone courses
    for x,y,w,h in [(198,195,49,63),(357,180,58,79),(273,204,43,48)]:
        rect(d,(x-5,y-5,x+w+5,y+h+7),(21,39,53,245)); rect(d,(x,y,x+w,y+h),(13,28,41,245))
        line(d,[(x+4,y+h-3),(x+4,y+17),(x+w//2,y+4),(x+w-4,y+17),(x+w-4,y+h-3)],(64,92,104,220),2)
        for k in range(3): rect(d,(x+7+k*11,y+h-10,x+10+k*11,y+h-8),(68,100,108,180))
    speckles(im,209,80,(0,190,640,355),[(85,131,137,125),(54,99,111,150),(60,102,77,160)],2)
    save(im,S1/"03_mid_architecture.png")

    # Near decor: roots, a hanging chain, broken framing stones, and moss kept at margins.
    im=canvas(); d=ImageDraw.Draw(im)
    # Stalactite edge clusters leave the center-top and player silhouette unobstructed.
    for x,sgn,drop in [(12,1,72),(76,1,44),(573,-1,62),(628,-1,88)]:
        line(d,[(x,0),(x+sgn*2,15),(x+sgn*7,29),(x+sgn*5,drop)],(28,54,53,245),3)
        line(d,[(x,0),(x+sgn*2,14),(x+sgn*6,26)],(74,103,76,205),1)
        for k in range(3):
            yy=26+k*11; xx=x+sgn*(8+k*3)
            poly(d,[(xx,yy),(xx+sgn*9,yy+3),(xx+sgn*2,yy+8)],(42,70,54,230))
    # Chain descending on the far right; alternating links are still readable at native size.
    for y in range(12,144,12):
        rect(d,(596,y,598,y+6),(79,103,105,225)); rect(d,(594,y+5,600,y+7),(43,65,74,240))
    # lower rock shoulders frame the level without masking platform edges.
    poly(d,[(0,300),(21,288),(43,293),(62,278),(91,290),(106,311),(132,323),(158,360),(0,360)],(14,29,39,250))
    poly(d,[(640,297),(620,283),(602,291),(582,277),(558,294),(542,318),(517,331),(495,360),(640,360)],(14,29,39,250))
    for x,y in [(24,306),(42,316),(86,320),(548,312),(584,300),(609,319)]:
        poly(d,[(x,y),(x+5,y-6),(x+10,y),(x+8,y+4),(x+2,y+4)],P["moss"])
        rect(d,(x+3,y-2,x+4,y-1),P["moss2"])
    save(im,S1/"04_near_decor.png")

    # Gentle atmospheric bands: hard clusters, low alpha, independently scrollable.
    im=canvas(); d=ImageDraw.Draw(im)
    for x,y,w in [(54,254,140),(213,278,105),(376,247,166),(482,290,120),(-28,311,116)]:
        for q,a in [(3,7),(2,12),(1,18)]:
            yy=y+q*3
            d.ellipse((x-q*11,yy-q*2,x+w+q*11,yy+q*2),fill=(94,129,145,a))
        for k in range(8):
            xx=x+8+k*max(1,w//8); yy=y+(k%3)*4
            rect(d,(xx,yy,xx+5,yy),(106,150,158,22+(k%3)*5))
    save(im,S1/"05_breathing_fog.png")

    # Sparse shafts make distant Lume feel spatial, never washing out platform edges.
    im=canvas(); d=ImageDraw.Draw(im)
    for x,top,bottom in [(132,16,226),(332,6,180),(512,28,236)]:
        poly(d,[(x-2,top),(x+2,top),(x+25,bottom),(x+14,bottom+3)],(92,162,172,11))
        rect(d,(x,top+8,x,bottom),(147,205,204,20))
        for y in range(top+15,bottom,31): rect(d,(x+4,y,x+5,y+1),(174,221,213,48))
    save(im,S1/"06_lume_shafts.png")

    # Updated, backward-compatible layer manifest: original four assets keep their names.
    layout_path=OUT/"levels"/"stage_01_awakening_layout.json"
    layout=json.loads(layout_path.read_text(encoding="utf-8"))
    layout["layers"]=[
        {"name":"sky","asset":"parallax/stage_01/01_sky_mist.png","parallax":0.035},
        {"name":"far","asset":"parallax/stage_01/02_far_architecture.png","parallax":0.14},
        {"name":"mid","asset":"parallax/stage_01/03_mid_architecture.png","parallax":0.34},
        {"name":"near","asset":"parallax/stage_01/04_near_decor.png","parallax":0.58},
        {"name":"fog","asset":"parallax/stage_01/05_breathing_fog.png","parallax":0.79},
        {"name":"shafts","asset":"parallax/stage_01/06_lume_shafts.png","parallax":0.18},
        {"name":"world","asset":"tilesets/stage_01_ruins_tiles.png","parallax":1.0},
    ]
    layout["art_pass"]="2.0 — camadas de profundidade, névoa e feixes de Lume; colisões preservadas"
    layout_path.write_text(json.dumps(layout,ensure_ascii=False,indent=2),encoding="utf-8")

    # Contact composite, exactly at the virtual resolution used by Flame.
    comp=Image.open(S1/"01_sky_mist.png").convert("RGBA")
    for n in ["02_far_architecture.png","03_mid_architecture.png","04_near_decor.png","05_breathing_fog.png","06_lume_shafts.png"]:
        comp.alpha_composite(Image.open(S1/n).convert("RGBA"))
    save(comp,S1/"awakening_backdrop_preview.png")

    # Wide audit board uses the actual stage platforms and the new art layers.
    board=canvas((1280,512),rgba(P["void"]))
    for name in ["01_sky_mist.png","02_far_architecture.png","03_mid_architecture.png","04_near_decor.png","05_breathing_fog.png","06_lume_shafts.png"]:
        tile=Image.open(S1/name).convert("RGBA")
        board.alpha_composite(tile,(0,0)); board.alpha_composite(tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(640,0))
    d=ImageDraw.Draw(board)
    atlas=Image.open(OUT/"tilesets"/"stage_01_ruins_tiles.png").convert("RGBA")
    def platform(x,y,w,h,seed):
        for xx in range(x,x+w,32):
            col=min(7,seed%8); seed+=1
            d.rectangle((xx,y,min(x+w-1,xx+31),y+h-1),fill=rgba(P["stone"]))
            cap=atlas.crop((col*32,32,(col+1)*32,64))
            board.alpha_composite(cap,(xx,y))
            for yy in range(y+32,y+h,32):
                block=atlas.crop(((seed%8)*32,0,((seed%8)+1)*32,32))
                board.alpha_composite(block,(xx,yy)); seed+=1
    platform(0,384,352,128,5); platform(448,320,192,64,1)
    platform(704,256,160,64,4); platform(992,192,288,96,2)
    for x,y in [(326,338),(617,277),(850,215),(1128,150)]:
        # Small decorative pilasters sit behind platform edges, outside the run lane.
        rect(d,(x,y,x+16,y+69),rgba(P["deep2"])); rect(d,(x-4,y-4,x+20,y+3),rgba(P["stone2"]))
        for yy in range(y+13,y+65,16): rect(d,(x+4,yy,x+12,yy+1),rgba(P["edge"]))
    # Quiet checkpoint and Eco markers retain their approved recognizable shapes.
    for x,y in [(120,344),(1112,149)]:
        rect(d,(x-8,y-22,x+8,y+19),rgba(P["stone"])); poly(d,[(x-6,y-18),(x,y-31),(x+6,y-18),(x+6,y-7),(x-6,y-7)],rgba(P["cyan0"]))
        rect(d,(x-1,y-20,x+1,y-10),rgba(P["white"]))
    poly(d,[(848,221),(856,232),(854,250),(849,255),(842,249),(840,233)],rgba(P["lume"]))
    save(board,S1/"awakening_microlevel_preview.png")

def creature_sheets():
    out=OUT/"background_creatures"/"stage_01"; out.mkdir(parents=True,exist_ok=True)
    # The Veil Moth: compact wing silhouettes, warm eye fleck, low contrast by design.
    strip=canvas((4*64,48));
    for i in range(4):
        fr=canvas((64,48)); d=ImageDraw.Draw(fr); flap=[0,2,4,2][i]
        poly(d,[(31,22),(23,17-flap),(12,12-flap),(16,23),(23,27)],(39,65,78,235))
        poly(d,[(33,22),(41,17-flap),(52,12-flap),(48,23),(41,27)],(39,65,78,235))
        line(d,[(23,22),(31,18),(33,27),(40,22)],(75,111,121,235),2)
        poly(d,[(29,19),(32,15),(35,19),(34,29),(30,29)],(24,44,56,250))
        rect(d,(31,19,32,20),(151,218,215,220))
        for x in (17,47): rect(d,(x,14-flap,x+2,15-flap),(91,132,133,155))
        strip.alpha_composite(fr,(i*64,0))
    save(strip,out/"veil_moth.png")
    # The Listener: a distant, contemplative hanging form, four subtly breathing frames.
    strip=canvas((4*80,64))
    for i in range(4):
        fr=canvas((80,64)); d=ImageDraw.Draw(fr); sway=[0,1,0,-1][i]
        line(d,[(40,0),(40,7)],(68,91,99,175),1)
        poly(d,[(37,7),(29,12),(24,25),(28,34),(31,32),(32,46),(36,42),(38,57),(41,62),(44,50),(48,43),(49,34),(55,28),(52,18),(46,10)],(25,46,59,250))
        poly(d,[(32+sway,16),(27+sway,27),(31+sway,37),(35,31)],(42,70,81,245))
        poly(d,[(45+sway,15),(52+sway,26),(48+sway,36),(43+sway,31)],(42,70,81,245))
        # Only two tiny eye pixels read at distance; no hostile face or attack pose.
        rect(d,(35,20,36,21),(151,218,215,220 if i!=2 else 130))
        rect(d,(43,20,44,21),(151,218,215,220 if i!=2 else 130))
        for k in range(3):
            xx=34+k*6; line(d,[(xx,38),(xx-2,47+k%2*4)],(48,75,84,220),1)
        strip.alpha_composite(fr,(i*80,0))
    save(strip,out/"the_listener.png")

def future_studies():
    # Three-layer reusable base studies, each 640x360 and matching the virtual camera.
    base=OUT/"parallax"; rng=random.Random(221)
    # Stage 02: open, windy galleries, broken spans and rusted chain falls.
    ddir=base/"stage_02"; ddir.mkdir(parents=True,exist_ok=True)
    sky=canvas((640,360)); d=ImageDraw.Draw(sky)
    for y in range(360):
        t=y/360; line(d,[(0,y),(639,y)],(8+int(5*t),18+int(8*t),28+int(10*t),255))
    poly(d,[(0,160),(56,125),(110,145),(172,95),(239,112),(288,76),(348,105),(418,72),(493,118),(559,92),(639,137),(639,360),(0,360)],"#111f2c")
    vents=canvas((640,360)); vd=ImageDraw.Draw(vents)
    for x,y in [(84,164),(258,131),(456,148),(574,122)]:
        rect(vd,(x,y,x+2,y+33),(83,139,145,55)); rect(vd,(x-3,y+28,x+4,y+30),(122,158,150,70))
    sky.alpha_composite(vents)
    speckles(sky,33,90,(0,15,640,250),[(103,143,153,45),(56,112,126,65)],1)
    save(sky,ddir/"01_petroil_void.png")
    far=canvas(); d=ImageDraw.Draw(far)
    # tall bridge pylons recede into a great vertical shaft
    for x,y,h,w in [(-12,102,258,62),(106,69,291,47),(220,119,241,54),(372,84,276,49),(508,110,250,65),(625,76,284,55)]:
        rect(d,(x,y,x+w,y+h),(24,42,54,235)); rect(d,(x-7,y-6,x+w+7,y+3),(45,65,73,245))
        for yy in range(y+24,y+h,31):
            rect(d,(x+5,yy,x+w-5,yy+2),(51,73,80,210))
            if yy%2: rect(d,(x+10,yy+7,x+12,yy+11),(112,103,75,130))
    # staggered broken bridges, no single continuous platform silhouette
    for x,y,w in [(0,194,142),(196,168,115),(355,206,126),(510,179,130)]:
        rect(d,(x,y,x+w,y+8),(33,53,62,245)); rect(d,(x,y,x+w-10,y+2),(95,103,93,210))
        for xx in range(x+12,x+w-5,24): rect(d,(xx,y+4,xx+8,y+6),(15,30,40,240))
    save(far,ddir/"02_suspended_galleries.png")
    near=canvas(); d=ImageDraw.Draw(near)
    for x in [35,161,477,588]:
        for y in range(8,196,12):
            rect(d,(x,y,x+2,y+6),(77,91,85,210)); rect(d,(x-2,y+5,x+4,y+7),(39,53,55,230))
        poly(d,[(x-15,252),(x-5,235),(x+4,243),(x+16,231),(x+22,270),(x+13,291),(x-9,286)],(15,31,39,245))
    for x,y in [(113,226),(143,238),(515,218),(548,231)]:
        poly(d,[(x,y),(x+3,y-8),(x+7,y),(x+5,y+5)],(73,100,71,220))
    save(near,ddir/"03_chains_and_windbreaks.png")
    comp=sky.copy(); comp.alpha_composite(far); comp.alpha_composite(near); save(comp,ddir/"stage_02_visual_study.png")

    # Stage 03: sacred vertical tower, broken glass, silver-cyan light and worn gold.
    ddir=base/"stage_03"; ddir.mkdir(parents=True,exist_ok=True)
    sky=canvas((640,360)); d=ImageDraw.Draw(sky)
    for y in range(360):
        t=y/359; line(d,[(0,y),(639,y)],(10+int(7*t),14+int(6*t),31+int(14*t),255))
    # stacked mist shelves rise toward a pale aperture
    shelves=canvas((640,360)); sd=ImageDraw.Draw(shelves)
    for y,x0,x1,a in [(218,68,570,19),(180,110,535,17),(141,174,481,15),(101,230,430,13)]:
        rect(sd,(x0,y,x1,y+4),(114,132,164,a)); rect(sd,(x0+22,y+7,x1-33,y+8),(155,165,180,a+5))
    sky.alpha_composite(shelves)
    poly(d,[(0,254),(55,236),(96,246),(155,217),(202,229),(251,194),(294,205),(337,189),(389,223),(446,205),(508,232),(570,212),(639,245),(639,360),(0,360)],"#151c31")
    speckles(sky,77,84,(0,12,640,254),[(134,151,180,55),(94,112,149,55)],1)
    save(sky,ddir/"01_indigo_aperture.png")
    far=canvas(); d=ImageDraw.Draw(far)
    # rising central tower with seven receding ribs, opening at the top
    poly(d,[(190,360),(204,239),(224,171),(251,111),(281,69),(311,34),(333,70),(361,116),(383,177),(404,243),(423,360)],(28,34,53,245))
    poly(d,[(247,360),(257,245),(274,174),(292,110),(313,75),(334,112),(354,179),(369,247),(379,360)],(17,26,44,250))
    for x,y,h in [(55,164,196),(126,119,241),(449,124,236),(530,171,189)]:
        rect(d,(x,y,x+23,y+h),(25,34,52,240)); rect(d,(x-6,y-7,x+29,y+2),(52,57,74,240))
        for yy in range(y+20,y+h,28): line(d,[(x+5,yy),(x+18,yy+5)],(75,81,99,200),1)
    # tall lancet frames flank the tower; panes are voids, not bright bars.
    for x in [235,390]:
        poly(d,[(x,300),(x,159),(x+19,114),(x+38,159),(x+38,300)],(54,60,79,230))
        poly(d,[(x+7,285),(x+7,164),(x+19,135),(x+31,164),(x+31,285)],(17,29,48,255))
        rect(d,(x+18,152,x+20,277),(116,175,183,75))
    # worn gold icon in the crown
    poly(d,[(311,69),(326,51),(341,69),(326,92)],(128,111,81,185))
    poly(d,[(319,69),(326,61),(333,69),(326,80)],(129,195,199,180))
    save(far,ddir/"02_echo_tower.png")
    glass=canvas(); d=ImageDraw.Draw(glass)
    # foreground shards as fractured, low-alpha stained glass at outer edges.
    for x,sgn in [(10,1),(72,1),(572,-1),(631,-1)]:
        poly(d,[(x,0),(x+sgn*24,0),(x+sgn*21,53),(x+sgn*7,86),(x+sgn*14,123),(x+sgn*3,157),(x,139)],(62,87,117,150))
        poly(d,[(x+sgn*5,12),(x+sgn*17,8),(x+sgn*15,49),(x+sgn*5,75)],(94,144,162,105))
        line(d,[(x,0),(x+sgn*8,39),(x+sgn*4,83),(x+sgn*14,119)],(155,174,173,190),1)
    # floating symbolic fragments, sparse and confined away from central gameplay lane
    for x,y in [(121,90),(528,102),(82,202),(566,196)]:
        poly(d,[(x,y-7),(x+5,y),(x,y+8),(x-4,y)],(111,169,180,125))
        rect(d,(x,y-2,x,y+2),(191,211,194,165))
    save(glass,ddir/"03_shattered_lancets.png")
    comp=sky.copy(); comp.alpha_composite(far); comp.alpha_composite(glass); save(comp,ddir/"stage_03_visual_study.png")

def main():
    stage1_layers(); creature_sheets(); future_studies()
    print("Art Pass 2 assets generated:")
    for path in sorted(OUT.rglob("*.png")):
        if "preview" in path.name or "background_creatures" in str(path) or "stage_0" in str(path):
            try:
                with Image.open(path) as im: print(f"{path.relative_to(OUT)} {im.width}x{im.height}")
            except Exception: pass

if __name__ == "__main__": main()
