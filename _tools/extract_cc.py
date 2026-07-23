"""Connected-component extraction for coops (5) and chicken skins (1 best each)."""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "assets"
OUT = "assets/sprites"
ALPHA = 24


def components(path, min_area=3000):
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    mask = arr[:, :, 3] > ALPHA
    # close small gaps so a character's parts merge into one blob
    mask_d = ndimage.binary_dilation(mask, iterations=6)
    lbl, n = ndimage.label(mask_d)
    comps = []
    for i in range(1, n + 1):
        ys, xs = np.where(lbl == i)
        if len(xs) < min_area:
            continue
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        # crop from ORIGINAL image (not dilated) and tighten
        crop = img.crop((int(x0), int(y0), int(x1), int(y1)))
        bb = crop.getbbox()
        if bb:
            crop = crop.crop(bb)
        area = (x1 - x0) * (y1 - y0)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        comps.append({"img": crop, "area": area, "cx": cx, "cy": cy,
                      "w": crop.width, "h": crop.height})
    return comps


def extract_coop():
    comps = components(os.path.join(SRC, "chicken_coop_asset.webp"), min_area=8000)
    comps.sort(key=lambda c: c["area"], reverse=True)
    comps = comps[:5]
    # order by row (cy) then col (cx)
    comps.sort(key=lambda c: (round(c["cy"] / 150), c["cx"]))
    out = os.path.join(OUT, "coop")
    os.makedirs(out, exist_ok=True)
    for i, c in enumerate(comps):
        c["img"].save(os.path.join(out, f"{i}.png"))
    print("coop:", [(c["w"], c["h"]) for c in comps])


def extract_chickens():
    out = os.path.join(OUT, "chicken")
    os.makedirs(out, exist_ok=True)
    for i in range(1, 12):
        comps = components(os.path.join(SRC, f"chicken_skin{i}_asset.webp"), min_area=6000)
        if not comps:
            print(f"skin{i}: NONE")
            continue
        # pick the component with the largest area (most complete pose)
        comps.sort(key=lambda c: c["area"], reverse=True)
        best = comps[0]
        best["img"].save(os.path.join(out, f"skin{i}.png"))
        print(f"skin{i}: {best['w']}x{best['h']} (of {len(comps)} comps)")


if __name__ == "__main__":
    extract_coop()
    extract_chickens()
