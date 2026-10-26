"""Validate generated asset dimensions/frames and make a review contact sheet."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "flutter_app" / "assets" / "images"
REVIEW = ROOT / "art_pipeline" / "asset_review_contact.png"

STRIPS = {
    "player/errante_idle.png": (6,48,48), "player/errante_run.png": (8,48,48),
    "player/errante_jump.png": (2,48,48), "player/errante_fall.png": (2,48,48),
    "player/errante_dash.png": (4,48,48), "player/errante_wall_slide.png": (2,48,48),
    "props/checkpoint_lume.png": (4,48,64), "props/echo_fragment.png": (4,32,32),
    "effects/dash_trail.png": (5,64,32), "effects/dust_puff.png": (4,32,24),
    "effects/lume_glow.png": (4,64,64), "effects/echo_collect.png": (5,64,64),
}

def check_strip(path, count, fw, fh):
    im=Image.open(path).convert("RGBA")
    assert im.size==(count*fw,fh), f"{path}: {im.size}, expected {(count*fw,fh)}"
    signatures=[]
    for index in range(count):
        frame=im.crop((index*fw,0,(index+1)*fw,fh))
        assert frame.getchannel("A").getbbox(), f"{path}: empty frame {index}"
        signatures.append(frame.tobytes())
    assert len(set(signatures))==count, f"{path}: duplicate frames"
    return im

def main():
    strips=[]
    for rel,spec in STRIPS.items():
        im=check_strip(ASSETS/rel,*spec)
        strips.append((rel,im))
    # Add composition and atlas in the same inspectable board.
    for rel in ["parallax/stage_01/awakening_microlevel_preview.png", "tilesets/stage_01_ruins_tiles.png", "props/carved_column.png"]:
        strips.append((rel,Image.open(ASSETS/rel).convert("RGBA")))
    scale=3
    rows=[]
    for label,im in strips:
        if im.width>1000:
            im.thumbnail((1200,420),Image.Resampling.NEAREST)
        elif im.width<400:
            im=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST)
        rows.append((label,im))
    row_h=max(im.height+24 for _,im in rows)
    board=Image.new("RGBA",(1200,row_h*len(rows)),(15,21,30,255)); draw=ImageDraw.Draw(board)
    y=0
    for label,im in rows:
        draw.text((6,y+4),label,fill=(225,239,239,255))
        board.alpha_composite(im,(6,y+22)); y+=row_h
    REVIEW.parent.mkdir(parents=True,exist_ok=True)
    board.save(REVIEW,optimize=True)
    print(f"Validated {len(STRIPS)} sprite strips; review board: {REVIEW} ({board.width}x{board.height})")

if __name__=="__main__": main()
