import os, glob, sys
from PIL import Image

def montage(files, cols, cell, out, bg=(40,40,50,255)):
    rows = (len(files)+cols-1)//cols
    canvas = Image.new("RGBA",(cols*cell, rows*cell), bg)
    for i,f in enumerate(files):
        im = Image.open(f).convert("RGBA")
        im.thumbnail((cell-8,cell-8))
        r,c = divmod(i,cols)
        x = c*cell + (cell-im.width)//2
        y = r*cell + (cell-im.height)//2
        canvas.alpha_composite(im,(x,y))
    canvas.save(out)
    print(out, len(files))

def sortk(f):
    b=os.path.splitext(os.path.basename(f))[0]
    return b

chick = sorted(glob.glob("assets/sprites/chicken/*.png"), key=lambda f:int(''.join(ch for ch in os.path.basename(f) if ch.isdigit())))
montage(chick, 6, 160, "_preview/m_chicken.png")
coop = sorted(glob.glob("assets/sprites/coop/*.png"))
montage(coop, 5, 200, "_preview/m_coop.png")
ce = sorted(glob.glob("assets/sprites/coins_and_eggs_asset/*.png"))
montage(ce, 11, 90, "_preview/m_coinsegg.png")
dec = sorted(glob.glob("assets/sprites/decorative_objects/*.png"))
montage(dec, 11, 90, "_preview/m_decor.png")
amp = sorted(glob.glob("assets/sprites/amplify_asset/*.png"))
montage(amp, 5, 140, "_preview/m_amp.png")
lan = sorted(glob.glob("assets/sprites/lanterns_asset/*.png"))
montage(lan, 3, 200, "_preview/m_lantern.png")
en = sorted(glob.glob("assets/sprites/enemy_asset/*.png"))
montage(en, 5, 160, "_preview/m_enemy.png")
