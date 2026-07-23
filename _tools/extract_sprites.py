"""Extract individual sprites from the concept sheets by alpha projection slicing.

Outputs to assets/sprites/<name>/<row>_<col>.png (row-major) and also a flat
list so we can map them to names. Prints a per-sheet grid summary for verification.
"""
import os
import glob
from PIL import Image

SRC = "assets"
OUT = "assets/sprites"
ALPHA_THRESHOLD = 24
MIN_RUN = 12  # ignore tiny specks


def runs(mask):
    """Given a boolean list, return list of (start, end_exclusive) runs of True."""
    res = []
    start = None
    for i, v in enumerate(mask):
        if v and start is None:
            start = i
        elif not v and start is not None:
            res.append((start, i))
            start = None
    if start is not None:
        res.append((start, len(mask)))
    return [r for r in res if (r[1] - r[0]) >= MIN_RUN]


def slice_sheet(path):
    name = os.path.splitext(os.path.basename(path))[0]
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()
    # Row mask: any opaque pixel in the row
    alpha_cols = [[False] * w for _ in range(h)]
    row_has = [False] * h
    for y in range(h):
        rh = False
        for x in range(w):
            if px[x, y][3] > ALPHA_THRESHOLD:
                alpha_cols[y][x] = True
                rh = True
        row_has[y] = rh
    row_bands = runs(row_has)
    out_dir = os.path.join(OUT, name)
    os.makedirs(out_dir, exist_ok=True)
    summary = []
    flat = []
    for ri, (y0, y1) in enumerate(row_bands):
        # Column mask within this band
        col_has = [False] * w
        for x in range(w):
            for y in range(y0, y1):
                if alpha_cols[y][x]:
                    col_has[x] = True
                    break
        col_runs = runs(col_has)
        summary.append(len(col_runs))
        for ci, (x0, x1) in enumerate(col_runs):
            box = img.crop((x0, y0, x1, y1))
            # tighten vertically within this cell
            bb = box.getbbox()
            if bb:
                box = box.crop(bb)
            fname = os.path.join(out_dir, f"{ri}_{ci}.png")
            box.save(fname)
            flat.append(fname)
    print(f"{name}: rows={len(row_bands)} cols_per_row={summary} total={len(flat)}")
    return flat


def main():
    os.makedirs(OUT, exist_ok=True)
    sheets = [
        "enemy_asset", "lanterns_asset", "amplify_asset", "coins_and_eggs_asset",
        "chicken_coop_asset", "decorative_objects",
    ] + [f"chicken_skin{i}_asset" for i in range(1, 12)]
    for s in sheets:
        p = os.path.join(SRC, s + ".webp")
        if os.path.exists(p):
            slice_sheet(p)


if __name__ == "__main__":
    main()
