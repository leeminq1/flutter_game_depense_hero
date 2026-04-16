"""
Remove black backgrounds from environment sprites.
Pixels where R, G, B are all below the threshold become transparent.
"""
import os
from PIL import Image

ASSETS_ROOT = os.path.join(os.path.dirname(__file__), "assets", "sprites", "environment")
# Any pixel with R<thresh AND G<thresh AND B<thresh becomes transparent
THRESHOLD = 30

def remove_black_bg(path: str) -> bool:
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    changed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r < THRESHOLD and g < THRESHOLD and b < THRESHOLD:
                pixels[x, y] = (r, g, b, 0)
                changed += 1
    if changed:
        img.save(path)
    return changed > 0


def main():
    targets = []
    for root, _dirs, files in os.walk(ASSETS_ROOT):
        for fname in files:
            if fname.lower().endswith(".png"):
                targets.append(os.path.join(root, fname))

    print(f"Processing {len(targets)} environment sprites...")
    fixed = 0
    for path in sorted(targets):
        rel = os.path.relpath(path, os.path.dirname(__file__))
        if remove_black_bg(path):
            print(f"  fixed: {rel}")
            fixed += 1
        else:
            print(f"  ok:    {rel}")
    print(f"\nDone — {fixed}/{len(targets)} files updated.")


if __name__ == "__main__":
    main()
