#!/usr/bin/env python3
"""Deterministic pixel-art asset generator for ECHOES: The Awakening.

All sprites are drawn from original primitives/pixel clusters. Requires Pillow.
Run from the repository root with Python 3.10+.
"""
from __future__ import annotations

import json
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "flutter_app" / "assets" / "images"
P = {
    "void": "#080e19", "deep": "#0b111c", "navy": "#111d2b", "stone0": "#172534",
    "stone1": "#1c2b3a", "stone2": "#26394a", "slate": "#34495d", "edge": "#526b7c",
    "mist": "#526c80", "mist2": "#71879a", "pale": "#b0c3ca", "cyan0": "#367b8d",
    "cyan": "#58b6c8", "lume": "#84d9e8", "white": "#d7f4ee", "violet": "#514568",
    "moss": "#36554e", "moss2": "#63816c", "gold": "#b49a70", "shadow": "#0d1723",
}

def c(name): return P.get(name, name)
def canvas(size, color=(0, 0, 0, 0)):
    return Image.new("RGBA", size, color)
def rect(d, box, fill, outline=None): d.rectangle(box, fill=c(fill), outline=c(outline) if outline else None)
def line(d, pts, fill, width=1): d.line(pts, fill=c(fill), width=width)
def poly(d, pts, fill, outline=None): d.polygon(pts, fill=c(fill), outline=c(outline) if outline else None)
def save(im, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)

def draw_player(pose, frame_i, facing=1):
    """48x48, anchor (24,44). Distinct small masked wanderer, fixed foot origin."""
    im = canvas((48,48)); d=ImageDraw.Draw(im)
    bob = ([0,-1,0,1,0,-1][frame_i % 6] if pose == "idle" else
           [0,-1,-1,0,1,1,0,-1][frame_i % 8] if pose == "run" else 0)
    lean = 2 if pose == "dash" else 1 if pose == "run" else 0
    x=24+lean*facing; y=27+bob
    # trailing hood/cape silhouette
    if pose == "dash":
        poly(d,[(x-5*facing,y-4),(x-15*facing,y-1),(x-21*facing,y+1),(x-13*facing,y+4),(x-7*facing,y+4)],"cyan0")
        line(d,[(x-8*facing,y-2),(x-18*facing,y+1)],"lume")
    else:
        cape_drop = (15 + (frame_i % 2) if pose == "fall" else 15 if pose == "wall" else 13)
        poly(d,[(x-5,y-1),(x+5,y-1),(x+7,y+6),(x+5,y+cape_drop),(x,y+cape_drop+2),(x-6,y+cape_drop),(x-8,y+5)],"navy")
        poly(d,[(x-5,y+2),(x-2,y+3),(x-3,y+cape_drop),(x-6,y+cape_drop-1)],"stone2")
        line(d,[(x+5,y+4),(x+6,y+10),(x+2,y+14)],"slate")
        # hem stitching, asymmetrical little rune
        rect(d,(x-3,y+cape_drop-1,x-2,y+cape_drop),"cyan0")
    # torso and scarf
    poly(d,[(x-4,y-5),(x+4,y-5),(x+5,y+4),(x+3,y+8),(x-4,y+7),(x-5,y+2)],"stone1")
    poly(d,[(x-5,y-3),(x-1,y-6),(x+4,y-4),(x+6,y-2),(x+1,y),(x-5,y-1)],"slate")
    rect(d,(x-3,y-3,x-1,y-2),"edge")
    # hood: layered, pointed silhouette
    poly(d,[(x-7,y-5),(x-6,y-12),(x-2,y-17),(x+2,y-18),(x+7,y-14),(x+8,y-6),(x+5,y-3),(x-5,y-3)],"deep")
    poly(d,[(x-6,y-10),(x-2,y-16),(x+2,y-17),(x+6,y-13),(x+7,y-7),(x+3,y-5),(x-4,y-6)],"stone2")
    line(d,[(x-5,y-11),(x-2,y-15),(x+2,y-16)],"edge")
    # porcelain blank mask, two cyan eye slits
    poly(d,[(x-5,y-9),(x-2,y-12),(x+4,y-11),(x+6,y-8),(x+3,y-6),(x-3,y-6)],"pale")
    eye_y=y-9
    if facing >= 0:
        rect(d,(x+1,eye_y,x+3,eye_y+1),"lume"); rect(d,(x-2,eye_y+1,x-1,eye_y+1),"cyan")
    else:
        rect(d,(x-3,eye_y,x-1,eye_y+1),"lume"); rect(d,(x+2,eye_y+1,x+3,eye_y+1),"cyan")
    # Lume seed brooch
    rect(d,(x+3,y+2,x+4,y+3),"white"); rect(d,(x+3,y+4,x+3,y+4),"cyan")
    # limbs by animation, keep head/torso proportions constant
    if pose == "run":
        legs=[((-3,7),(-7,12),(-10,13)),((3,7),(6,11),(10,11)),((-3,7),(-1,12),(2,13)),((3,7),(8,10),(11,10))]
        a,b,foot=legs[frame_i%4]
        line(d,[(x+a[0],y+a[1]),(x+b[0],y+b[1]),(x+foot[0],y+foot[1])],"deep",3)
        line(d,[(x+a[0],y+a[1]),(x+b[0],y+b[1])],"slate",2)
        # opposite leg tucked
        line(d,[(x-a[0],y+7),(x-a[0]-2,y+10),(x-a[0]-1,y+11)],"deep",3)
    elif pose in ("jump","fall"):
        tuck = 1 if pose == "jump" else 3
        line(d,[(x-3,y+6),(x-6,y+9+tuck),(x-2,y+10+tuck)],"deep",3)
        line(d,[(x+3,y+6),(x+5,y+10),(x+1,y+11)],"deep",3)
        if pose == "jump":
            arm_y = -7 if frame_i == 0 else -3
            line(d,[(x+4,y-1),(x+7,y+arm_y)],"slate",2)
    elif pose == "dash":
        line(d,[(x-2*facing,y+4),(x+2*facing,y+7)],"deep",3)
        line(d,[(x-1*facing,y+4),(x+3*facing,y+7)],"slate",1)
    elif pose == "wall":
        lift = frame_i % 2
        line(d,[(x-3,y+6),(x-7-lift,y+8-lift),(x-3,y+10-lift)],"deep",3)
        line(d,[(x+3,y+6),(x+7,y+8+lift),(x+3,y+11+lift)],"deep",3)
        rect(d,(x+8,y-4+(1-lift),x+10,y+6+(1-lift)),"slate")
        for q in range(3): rect(d,(x+8,y+q*4,x+10,y+q*4),"edge")
    else:
        line(d,[(x-3,y+6),(x-4,y+12),(x-1,y+13)],"deep",3)
        line(d,[(x+3,y+6),(x+4,y+12),(x+7,y+12)],"deep",3)
        line(d,[(x-3,y+9),(x-7,y+7)],"stone2",2)
    # soft sprite-local glints (pixel-scale, no blurred halo in character sheet)
    if pose == "idle":
        spark=[(9,-15),(10,-11),(9,-6),(-8,-15),(-9,-10),(-8,-6)][frame_i%6]
        rect(d,(x+spark[0],y+spark[1],x+spark[0],y+spark[1]),"lume")
    if pose == "dash":
        for k in range(4-frame_i):
            yy=y-7+k*5
            line(d,[(x-17*facing,yy),(x-12*facing,yy)],"lume" if k==0 else "cyan0")
    return im

def player_sheets():
    specs={"idle":(6,7),"run":(8,12),"jump":(2,10),"fall":(2,8),"dash":(4,16),"wall_slide":(2,8)}
    player=OUT/"player"; player.mkdir(parents=True,exist_ok=True)
    for name,(n,fps) in specs.items():
        strip=canvas((n*48,48))
        for i in range(n):
            pose={"wall_slide":"wall"}.get(name,name)
            strip.alpha_composite(draw_player(pose,i), (i*48,0))
        save(strip,player/f"errante_{name}.png")
        # contact strip at 4x nearest for visual QA
        save(strip.resize((strip.width*4,strip.height*4),Image.Resampling.NEAREST),player/f"preview_{name}.png")
    return specs

def backgrounds():
    par=OUT/"parallax"/"stage_01"; par.mkdir(parents=True,exist_ok=True)
    W,H=640,360
    rng=random.Random(1401)
    # distant void / stratified mist sky
    sky=canvas((W,H)); d=ImageDraw.Draw(sky)
    for y in range(H):
        t=y/H; col=(8+int(8*t),14+int(13*t),25+int(17*t),255); line(d,[(0,y),(W,y)],col)
    for i in range(12):
        x=rng.randrange(-80,W+80); y=rng.randrange(75,280); rx=rng.randrange(45,130); ry=rng.randrange(8,24)
        for k in range(5,0,-1):
            box=(x-rx*k//4,y-ry*k//4,x+rx*k//4,y+ry*k//4)
            d.ellipse(box,fill=(47,72,91,7+k*2))
    for i in range(65):
        x=rng.randrange(W); y=rng.randrange(25,H); d.point((x,y),fill=(75,121,145,rng.randrange(20,55)))
    save(sky,par/"01_sky_mist.png")
    # remote cliff architecture: giant broken arch and vertical cutouts
    far=canvas((W,H)); d=ImageDraw.Draw(far)
    poly(d,[(0,180),(42,161),(78,168),(111,127),(153,119),(172,143),(196,145),(210,90),(249,67),(279,87),(304,137),(335,148),(359,100),(399,78),(427,90),(450,156),(486,144),(517,104),(554,92),(588,128),(640,116),(640,360),(0,360)],"#111f30")
    # enormous arch aperture
    d.arc((202,80,407,294),180,360,fill=c("#24384c"),width=12); d.arc((214,91,395,277),180,360,fill=c("#1b2b3e"),width=5)
    for x in [54,145,480,574]:
        rect(d,(x,166,x+17,338),"#17283a"); rect(d,(x-4,166,x+21,173),"#273a4d")
        for yy in range(184,322,22): line(d,[(x,yy),(x+16,yy)],"#22364a")
    rng=random.Random(9)
    for i in range(140):
        x=rng.randrange(W); y=rng.randrange(100,345)
        if rng.random()<.7: rect(d,(x,y,x+rng.randrange(1,7),y+rng.randrange(1,4)),rng.choice(["#1b2e40","#22364a","#2a4053"]))
    save(far,par/"02_far_architecture.png")
    # mid architecture and suspended bridge, alpha overlays
    mid=canvas((W,H)); d=ImageDraw.Draw(mid)
    # rear pillars and carved lintels
    for x,w,h in [(62,40,170),(204,34,205),(405,44,190),(552,32,151)]:
        y=H-h; poly(d,[(x,y+8),(x+8,y),(x+w-5,y+2),(x+w,y+13),(x+w-1,H),(x,H)],"#223647")
        rect(d,(x-6,y+7,x+w+5,y+13),"#3b5364"); rect(d,(x+4,y+26,x+w-5,y+28),"#2d4354")
        for yy in range(y+39,H,29):
            rect(d,(x+5,yy,x+w-6,yy+1),"#344c5e")
            rect(d,(x+9,yy+5,x+10,yy+10),"#1a2938")
    # bridges and ribbed arch gallery
    poly(d,[(0,248),(112,241),(198,251),(257,243),(371,252),(461,240),(640,249),(640,263),(0,263)],"#293d50")
    line(d,[(0,248),(112,241),(198,251),(257,243),(371,252),(461,240),(640,249)],"#607788",2)
    for x in range(18,640,48):
        line(d,[(x,263),(x+12,283),(x+43,286)],"#24394a",2)
    # wall niche silhouettes
    d.arc((272,136,365,270),180,360,fill=c("#40596b"),width=4)
    save(mid,par/"03_mid_architecture.png")
    # foreground decor is alpha only, hanging chains, roots and small stones
    near=canvas((W,H)); d=ImageDraw.Draw(near)
    for x,ln in [(28,116),(570,143),(612,89)]:
        for j in range(0,ln,6):
            xx=x+(j//6%2); rect(d,(xx,0+j,xx+1,j+3),"#70838c")
        d.ellipse((x-3,ln-1,x+5,ln+9),fill=c("#304657"),outline=c("#758c91"))
    # roots from top edges
    for sx,sgn in [(108,1),(510,-1),(634,-1)]:
        pts=[(sx,0),(sx+sgn*2,22),(sx+sgn*7,43),(sx+sgn*5,65),(sx+sgn*13,83)]
        line(d,pts,"#314944",3); line(d,[(sx,0),(sx+sgn*1,19),(sx+sgn*5,35)],"#58705d",1)
        for k in range(3):
            xx=sx+sgn*(11+k*4); yy=47+k*12
            poly(d,[(xx,yy),(xx+sgn*8,yy+3),(xx+sgn*2,yy+8)],"#486652")
    # lower frame silhouette, never overlaps gameplay plane center
    poly(d,[(0,337),(49,326),(82,337),(118,331),(157,341),(190,338),(215,360),(0,360)],"#111d27")
    poly(d,[(640,332),(601,320),(575,331),(545,328),(511,344),(486,342),(469,360),(640,360)],"#111d27")
    save(near,par/"04_near_decor.png")
    # room composite for review only, native 640x360
    near=Image.open(par/"04_near_decor.png").convert("RGBA")
    comp=sky.copy(); comp.alpha_composite(far); comp.alpha_composite(mid); comp.alpha_composite(near)
    save(comp,par/"awakening_backdrop_preview.png")

def tileset():
    out=canvas((256,160)); d=ImageDraw.Draw(out); rng=random.Random(76)
    # atlas: 8 columns x 5 rows, 32x32 tile cells: modular blocks and surface variants
    for tid in range(40):
        ox=(tid%8)*32; oy=(tid//8)*32
        if tid < 8: # solid worn blocks
            rect(d,(ox,oy,ox+31,oy+31),"stone1")
            rect(d,(ox,oy,ox+31,oy+3),"slate")
            line(d,[(ox,oy+5),(ox+31,oy+5)],"edge")
            for xx,yy in [(5,12),(20,9),(12,25),(27,22)]:
                rect(d,(ox+xx,oy+yy,ox+xx+1,oy+yy+1),rng.choice(["stone2","slate","#182735"]))
            # distinct mortar positions keyed by tile
            line(d,[(ox+(tid*7)%24,oy+6),(ox+(tid*7)%24,oy+14)],"#142331")
            line(d,[(ox+((tid*11+9)%25),oy+15),(ox+((tid*11+9)%25),oy+31)],"#142331")
        elif tid < 16: # top ledges / chipped corners
            rect(d,(ox,oy+5,ox+31,oy+31),"stone1"); rect(d,(ox,oy,ox+31,oy+7),"slate")
            line(d,[(ox,oy+2),(ox+31,oy+2)],"edge")
            for k in range(5):
                x=ox+(tid*3+k*7)%30; rect(d,(x,oy+8,x+1,oy+10),"stone2")
            for k in range(4): rect(d,(ox+k*9+1,oy+27,ox+k*9+4,oy+28),"#40586a")
        elif tid < 24: # cracked / relief masonry
            rect(d,(ox,oy,ox+31,oy+31),"stone0")
            line(d,[(ox+3,oy+1),(ox+14,oy+1),(ox+18,oy+10),(ox+11,oy+16),(ox+14,oy+23),(ox+8,oy+31)],"slate",2)
            line(d,[(ox+21,oy+4),(ox+27,oy+10),(ox+22,oy+17)],"#3d5366")
            for k in range(4): rect(d,(ox+(k*13+tid)%30,oy+(k*9+5)%30,ox+(k*13+tid)%30+1,oy+(k*9+5)%30+1),"edge")
        elif tid < 32: # mossy masonry
            rect(d,(ox,oy,ox+31,oy+31),"stone1")
            for k in range(11):
                x=ox+rng.randrange(32); y=oy+rng.randrange(32)
                rect(d,(x,y,x+rng.randrange(1,4),y+rng.randrange(1,3)),rng.choice(["moss","moss2","#29473f"]))
            rect(d,(ox,oy,ox+31,oy+2),"slate")
        else: # trim, rune lintel, floor inset
            rect(d,(ox,oy,ox+31,oy+31),"stone0")
            rect(d,(ox+3,oy+4,ox+28,oy+27),"stone1", "slate")
            rect(d,(ox+7,oy+8,ox+24,oy+23),"#192a38")
            if tid%2:
                poly(d,[(ox+15,oy+10),(ox+20,oy+16),(ox+15,oy+22),(ox+10,oy+16)],"cyan0")
                rect(d,(ox+14,oy+14,ox+16,oy+18),"lume")
            else: line(d,[(ox+7,oy+17),(ox+14,oy+17),(ox+17,oy+11),(ox+23,oy+11)],"gold")
    save(out,OUT/"tilesets"/"stage_01_ruins_tiles.png")
    # palette indexed table and tile labels
    meta={"tile_size":[32,32],"columns":8,"rows":5,"tiles":[{"id":i,"atlas_xy":[i%8,i//8],"role":["block","top","relief","moss","trim"][i//8]} for i in range(40)]}
    (OUT/"tilesets").mkdir(parents=True,exist_ok=True)
    (OUT/"tilesets"/"stage_01_ruins_tiles.json").write_text(json.dumps(meta,indent=2),encoding="utf-8")

def props_and_fx():
    props=OUT/"props"; props.mkdir(parents=True,exist_ok=True)
    # checkpoint: layered carved lantern obelisk with 4 animation frames
    strip=canvas((4*48,64))
    for i in range(4):
        fr=canvas((48,64)); d=ImageDraw.Draw(fr); pulse=[0,1,2,1][i]
        # base feet and stepped body
        poly(d,[(10,57),(14,51),(34,51),(38,57),(35,61),(13,61)],"stone0")
        rect(d,(14,37,34,52),"stone1"); rect(d,(12,34,36,39),"slate"); rect(d,(15,29,33,34),"edge")
        poly(d,[(17,31),(17,17),(24,8),(31,17),(31,31)],"#192b3b", "slate")
        line(d,[(18,17),(24,10),(30,17)],"edge")
        # luminous glass core; brightness and halo pulse
        d.ellipse((19-pulse,17-pulse,29+pulse,31+pulse),fill=(52,182,200,28+12*pulse))
        poly(d,[(23,17),(27,21),(26,27),(23,30),(21,25),(21,20)],"cyan")
        rect(d,(23,18,24,25),"white"); rect(d,(24,26,25,28),"lume")
        line(d,[(20,43),(28,43),(28,47),(21,47),(21,50)],"gold")
        # chipped corner engravings
        rect(d,(16,39,17,40),"edge"); rect(d,(31,48,32,49),"#40586a")
        sparks=[(11,25),(35,25),(32,12),(13,12)]
        sx,sy=sparks[i]; rect(d,(sx,sy,sx+1,sy+1),"white")
        strip.alpha_composite(fr,(i*48,0))
    save(strip,props/"checkpoint_lume.png")
    # echo shard pickups: four distinct crystal frames
    echo=canvas((4*32,32))
    for i in range(4):
        fr=canvas((32,32)); d=ImageDraw.Draw(fr); bob=[0,-1,-2,-1][i]
        d.ellipse((7,7+bob,25,25+bob),fill=(88,182,200,24+i*6))
        poly(d,[(15,3+bob),(22,10+bob),(21,20+bob),(16,27+bob),(10,19+bob),(9,10+bob)],"cyan0")
        poly(d,[(15,5+bob),(19,10+bob),(18,18+bob),(15,23+bob),(12,17+bob),(12,10+bob)],"lume")
        line(d,[(14,7+bob),(16,12+bob),(15,17+bob)],"white")
        rect(d,(22,8+bob,23,9+bob),"white")
        sparkle=[(7,14),(23,13),(20,24),(8,20)][i]
        rect(d,(sparkle[0],sparkle[1],sparkle[0],sparkle[1]),"white")
        echo.alpha_composite(fr,(i*32,0))
    save(echo,props/"echo_fragment.png")
    # decorative freestanding column and small hanging root cluster
    col=canvas((64,96)); d=ImageDraw.Draw(col)
    poly(d,[(12,92),(16,85),(47,85),(53,92),(50,95),(14,95)],"stone0")
    rect(d,(19,24,45,86),"stone1"); rect(d,(16,21,48,28),"slate"); rect(d,(14,16,50,22),"edge")
    rect(d,(22,31,25,80),"stone2"); rect(d,(39,32,42,78),"#172635")
    for y in (42,62): line(d,[(26,y),(39,y+4)],"slate")
    poly(d,[(31,35),(36,41),(31,47),(27,41)],"#315e69"); rect(d,(30,40,32,42),"lume")
    for x,y in [(17,72),(45,55),(20,37)]: rect(d,(x,y,x+2,y+2),"moss2")
    save(col,props/"carved_column.png")
    # dash trail, dust, glow and echo collect, each is a genuine multi-frame strip
    fx=OUT/"effects"; fx.mkdir(parents=True,exist_ok=True)
    def sheet(name, frames, size, painter):
        strip=canvas((frames*size[0],size[1]))
        for i in range(frames): strip.alpha_composite(painter(i),(i*size[0],0))
        save(strip,fx/f"{name}.png")
        return strip
    def trail(i):
        im=canvas((64,32)); d=ImageDraw.Draw(im)
        n=4-i
        for k in range(n):
            y=7+k*5; x=5+k*7+i*2
            line(d,[(x,y),(x+18+k*2,y)],(75,190,208,max(35,165-i*28-k*18)),1+(k==0))
        for x,y in [(11,5),(24,24),(38,8)][:max(1,3-i//2)]: rect(d,(x+i*2,y,x+1+i*2,y+1),(190,244,238,max(30,180-i*38)))
        return im
    sheet("dash_trail",5,(64,32),trail)
    def dust(i):
        im=canvas((32,24)); d=ImageDraw.Draw(im)
        clusters=[[(11,16,3,2),(17,13,2,2)],[(7,13,3,2),(16,15,3,2),(22,11,2,1)],[(5,11,2,1),(13,9,3,2),(23,13,2,1)],[(3,9,2,1),(12,7,2,1),(25,10,1,1)]]
        for j,(x,y,w,h) in enumerate(clusters[i]): rect(d,(x,y,x+w,y+h),["#718694","#9aaeb1","#536d7c"][j%3])
        return im
    sheet("dust_puff",4,(32,24),dust)
    def glow(i):
        im=canvas((64,64)); d=ImageDraw.Draw(im); r=[10,13,16,13][i]
        for q in range(5,0,-1):
            rr=r*q//3; alpha=8+q*5
            d.ellipse((32-rr,32-rr,32+rr,32+rr),fill=(70,186,204,alpha))
        d.ellipse((27,27,37,37),fill=(132,217,232,140)); d.ellipse((29,28,34,34),fill=(215,245,239,220))
        d.point((23,21),fill=(215,245,239,190)); d.point((40,37),fill=(132,217,232,170))
        spark=[(22,34),(34,22),(42,29),(28,43)][i]
        d.point(spark,fill=(215,245,239,210))
        return im
    sheet("lume_glow",4,(64,64),glow)
    def collect(i):
        im=canvas((64,64)); d=ImageDraw.Draw(im); r=8+i*4
        d.ellipse((32-r,32-r,32+r,32+r),outline=(120,222,232,max(20,190-i*42)),width=2)
        for k in range(max(1,8-i*2)):
            a=math.tau*k/max(1,8-i*2)+i*.35; dist=12+i*3
            x=round(32+math.cos(a)*dist); y=round(32+math.sin(a)*dist)
            rect(d,(x-1,y-1,x+1,y+1),(205,246,232,max(35,220-i*42)))
        d.ellipse((28,28,36,36),fill=(132,217,232,max(25,210-i*48)))
        return im
    sheet("echo_collect",5,(64,64),collect)

def level_preview():
    # A 20-second authored microsegment preview with room for platform traversal.
    W,H=1280,512; bg=Image.open(OUT/"parallax"/"stage_01"/"01_sky_mist.png").convert("RGBA").resize((W,H),Image.Resampling.NEAREST)
    for name in ["02_far_architecture.png","03_mid_architecture.png"]:
        lay=Image.open(OUT/"parallax"/"stage_01"/name).convert("RGBA").resize((W,H),Image.Resampling.NEAREST); bg.alpha_composite(lay)
    d=ImageDraw.Draw(bg)
    # platform silhouettes with lit chipped rims
    def platform(x,y,w,h=44):
        rect(d,(x,y,x+w,y+h),"stone1"); rect(d,(x,y,x+w,y+5),"slate"); line(d,[(x,y+1),(x+w,y+1)],"edge",2)
        for xx in range(x+9,x+w-4,31):
            rect(d,(xx,y+15,xx+9,y+16),"stone2"); rect(d,(xx+17,y+29,xx+19,y+31),"#516878")
    platform(0,398,347,100); platform(452,348,186,70); platform(733,297,158,55); platform(1000,247,280,85)
    # column stacks on world edge
    for x,y in [(327,343),(620,296),(872,248),(1126,190)]:
        rect(d,(x,y,x+25,400),"stone0"); rect(d,(x-6,y-5,x+31,y+4),"slate")
        for yy in range(y+13,395,21): rect(d,(x+5,yy,x+20,yy+1),"#40586a")
    # checkpoint lantern and collectible crystal
    for x,y in [(91,334),(1083,183)]:
        d.ellipse((x-33,y-42,x+33,y+24),fill=(66,181,200,24)); rect(d,(x-9,y-2,x+9,y+42),"stone1")
        poly(d,[(x-7,y),(x,y-22),(x+7,y),(x+7,y+12),(x-7,y+12)],"cyan0"); rect(d,(x-2,y-15,x+1,y+4),"white")
    poly(d,[(828,238),(841,251),(839,270),(831,278),(822,268),(820,251)],"lume")
    # mist pools and ground debris
    for x in range(24,1280,71):
        if x%2: rect(d,(x,488,x+2,490),"moss2")
    near=Image.open(OUT/"parallax"/"stage_01"/"04_near_decor.png").convert("RGBA").resize((W,H),Image.Resampling.NEAREST)
    bg.alpha_composite(near)
    # exported for level layout reference, deliberately no baked player
    save(bg,OUT/"parallax"/"stage_01"/"awakening_microlevel_preview.png")
    layout={"name":"O Despertar — trecho 01","unit":"32px tile","tile_size":32,"canvas_tiles":[40,16],"layers":[
        {"name":"sky","asset":"parallax/stage_01/01_sky_mist.png","parallax":0.06},
        {"name":"far","asset":"parallax/stage_01/02_far_architecture.png","parallax":0.18},
        {"name":"mid","asset":"parallax/stage_01/03_mid_architecture.png","parallax":0.42},
        {"name":"near","asset":"parallax/stage_01/04_near_decor.png","parallax":0.72},
        {"name":"world","asset":"tilesets/stage_01_ruins_tiles.png","parallax":1.0}],
        "platforms":[[0,12,11,4],[14,10,6,2],[22,8,5,2],[31,6,9,3]],
        "props":[{"type":"checkpoint","asset":"props/checkpoint_lume.png","tile_xy":[3,10]},
                  {"type":"echo","asset":"props/echo_fragment.png","tile_xy":[26,7]},
                  {"type":"checkpoint_final","asset":"props/checkpoint_lume.png","tile_xy":[34,4]}],
        "note":"Reference layout only; tile collision and spawn transforms are authored by the gameplay integrator."}
    dest=OUT/"levels"; dest.mkdir(parents=True,exist_ok=True); (dest/"stage_01_awakening_layout.json").write_text(json.dumps(layout,indent=2),encoding="utf-8")

def main():
    specs=player_sheets(); backgrounds(); tileset(); props_and_fx(); level_preview()
    print(json.dumps({"output":str(OUT),"animations":specs,"status":"generated"},indent=2))

if __name__ == "__main__": main()
