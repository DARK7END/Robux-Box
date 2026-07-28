#!/usr/bin/env python3
"""Exports every icon size the app needs — Android launcher icons, the iOS
AppIcon set and the Play Store listing icon — by resizing the real Robux Box
artwork in tool/icon_source/. No art is drawn or generated here: if the
source image is missing, this script fails loudly instead of substituting
placeholder art.

Run: python3 tool/generate_icon.py          # Android + Play Store
     python3 tool/generate_icon.py --ios     # iOS AppIcon set (needs ios/ to exist)
"""
import json
import os
import sys
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
STORE = os.path.join(ROOT, "assets", "images")
SOURCE_ICON = os.path.join(os.path.dirname(__file__), "icon_source", "app_icon_source.jpg")

M = 1024  # master render size


def load_hero_source(size=M):
    """The real Robux Box icon artwork (a square, already-composed render)
    supplied by the team. Returns an opaque RGB image at size x size."""
    if not os.path.isfile(SOURCE_ICON):
        sys.exit(
            f"Missing {SOURCE_ICON} — put the real icon artwork there. "
            f"This script only resizes supplied art; it does not generate any."
        )
    img = Image.open(SOURCE_ICON).convert("RGB")
    w, h = img.size
    side = min(w, h)
    img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
    return img.resize((size, size), Image.LANCZOS)


def adaptive_foreground_from_source(size):
    """Adaptive-icon foreground: the supplied artwork scaled into Android's
    ~72dp safe zone (of the 108dp canvas) so launcher masks — circle,
    squircle, whatever the OEM picks — never clip into the crate or the
    wordmark, centred on transparency."""
    src = load_hero_source(round(size * 0.68))
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - src.width) // 2
    layer.paste(src, (offset, offset))
    return layer


def adaptive_background_from_source(size):
    """Adaptive-icon background: a flat fill matching the artwork's own
    near-black backdrop, so whatever a launcher mask crops away at the edges
    blends in seamlessly instead of showing a seam."""
    return Image.new("RGBA", (size, size), (9, 9, 9, 255))


def save(img, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path)


DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

# iOS AppIcon sizes (pt, scale, idiom). iOS applies its own corner mask, so the
# source must be an OPAQUE square with no alpha and no rounding.
IOS_SPECS = [
    (20, 2, "iphone"), (20, 3, "iphone"),
    (29, 2, "iphone"), (29, 3, "iphone"),
    (40, 2, "iphone"), (40, 3, "iphone"),
    (60, 2, "iphone"), (60, 3, "iphone"),
    (20, 1, "ipad"), (20, 2, "ipad"),
    (29, 1, "ipad"), (29, 2, "ipad"),
    (40, 1, "ipad"), (40, 2, "ipad"),
    (76, 1, "ipad"), (76, 2, "ipad"),
    (83.5, 2, "ipad"),
    (1024, 1, "ios-marketing"),
]


def generate_ios():
    out = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if not os.path.isdir(os.path.dirname(out)):
        print("  ios/ not generated yet — run flutter create first; skipping.")
        return
    os.makedirs(out, exist_ok=True)
    master = load_hero_source(M)
    images = []
    for (size, scale, idiom) in IOS_SPECS:
        px = round(size * scale)
        name = f"Icon-{size}@{scale}x.png"
        master.resize((px, px), Image.LANCZOS).save(os.path.join(out, name))
        images.append({
            "size": f"{size}x{size}",
            "idiom": idiom,
            "filename": name,
            "scale": f"{scale}x",
        })
    with open(os.path.join(out, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"version": 1, "author": "xcode"}},
                  f, indent=2)
    print(f"  iOS AppIcon set generated ({len(images)} sizes).")


def main():
    hero = load_hero_source(M).convert("RGBA")
    hero_round = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    mask = Image.new("L", (M, M), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, M, M], fill=255)
    hero_round.paste(hero, (0, 0), mask)

    fg = adaptive_foreground_from_source(M)    # adaptive foreground (safe zone)
    bg = adaptive_background_from_source(M)    # adaptive background (OS-masked)

    for name, mult in DENSITIES.items():
        legacy = int(48 * mult)
        adaptive = int(108 * mult)
        save(hero, f"{RES}/mipmap-{name}/ic_launcher.png", legacy)
        save(hero_round, f"{RES}/mipmap-{name}/ic_launcher_round.png", legacy)
        save(fg, f"{RES}/mipmap-{name}/ic_launcher_foreground.png", adaptive)
        save(bg, f"{RES}/mipmap-{name}/ic_launcher_background.png", adaptive)

    os.makedirs(STORE, exist_ok=True)
    hero.convert("RGB").resize((512, 512), Image.LANCZOS).save(f"{STORE}/play_store_icon.png")

    print("Android + store icons generated from supplied artwork.")


if __name__ == "__main__":
    if "--ios" in sys.argv:
        generate_ios()
    else:
        main()
