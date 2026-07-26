#!/usr/bin/env python3
"""Generates the Robux Box launcher icon set from code (no external art).

Draws a unique premium treasure chest (gold body, neon-green lock band, spilling
gold coins) on a dark green-glow background, in the app's brand palette, then
exports:
  * legacy square + round mipmaps (mdpi..xxxhdpi) for API < 26
  * adaptive foreground + background layers (108dp) for API 26+
  * a 512x512 Google Play store icon

Run: python3 tool/generate_icon.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

RES = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res")
STORE = os.path.join(os.path.dirname(__file__), "..", "assets", "images")

GREEN = (0, 255, 106)
GREEN_DEEP = (0, 163, 68)
GOLD_L = (255, 232, 150)
GOLD = (255, 216, 77)
GOLD_D = (240, 160, 0)
GOLD_DK = (150, 92, 0)
BLACK = (13, 13, 13)

M = 1024  # master render size


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def rrect(draw, box, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def background(size, rounded=True, circle=False):
    """Dark vertical gradient with a soft green radial glow."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad = Image.new("RGBA", (size, size))
    gp = grad.load()
    for y in range(size):
        t = y / size
        c = lerp((16, 28, 20), (9, 9, 9), t)
        for x in range(size):
            gp[x, y] = c + (255,)
    # green radial glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([size * 0.12, size * 0.05, size * 0.88, size * 0.8],
               fill=GREEN + (70,))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.12))
    grad = Image.alpha_composite(grad, glow)
    # mask
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    if circle:
        md.ellipse([0, 0, size, size], fill=255)
    elif rounded:
        md.rounded_rectangle([0, 0, size, size], radius=int(size * 0.22), fill=255)
    else:
        md.rectangle([0, 0, size, size], fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def draw_chest(size, scale=0.62):
    """Returns an RGBA image (size x size) with a centered treasure chest."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    w = size * scale
    h = w * 0.86
    cx = size / 2
    x0 = cx - w / 2
    y0 = size / 2 - h / 2 + h * 0.04
    r = w * 0.10

    seam = y0 + h * 0.42

    # soft drop shadow
    sh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle([x0, y0 + h * 0.1, x0 + w, y0 + h * 1.02],
                         radius=r, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(size * 0.02))
    img = Image.alpha_composite(img, sh)
    d = ImageDraw.Draw(img)

    # ---- body ----
    rrect(d, [x0, seam - r, x0 + w, y0 + h], r, fill=GOLD)
    # body shading
    ov = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    od.rounded_rectangle([x0, y0 + h * 0.78, x0 + w, y0 + h], radius=r,
                         fill=GOLD_D + (120,))
    img = Image.alpha_composite(img, ov)
    d = ImageDraw.Draw(img)

    # ---- lid (dome) ----
    lid_bottom = seam + r
    d.rounded_rectangle([x0, y0, x0 + w, lid_bottom], radius=r * 1.3, fill=GOLD_L)
    d.rectangle([x0, seam, x0 + w, lid_bottom], fill=GOLD_L)
    # lid highlight
    d.rounded_rectangle([x0 + w * 0.06, y0 + h * 0.06, x0 + w * 0.94, y0 + h * 0.2],
                        radius=r, fill=(255, 255, 255, 90))

    # ---- vertical straps ----
    for sx in (0.16, 0.84):
        bx = x0 + w * sx
        d.rounded_rectangle([bx - w * 0.05, y0, bx + w * 0.05, y0 + h],
                            radius=w * 0.03, fill=GOLD_DK)
        # rivets
        for ry in (0.12, 0.5, 0.88):
            cyr = y0 + h * ry
            d.ellipse([bx - w * 0.018, cyr - w * 0.018,
                       bx + w * 0.018, cyr + w * 0.018], fill=GOLD_L)

    # ---- green seam band ----
    d.rectangle([x0, seam - h * 0.06, x0 + w, seam + h * 0.06], fill=GREEN_DEEP)
    d.rectangle([x0, seam - h * 0.06, x0 + w, seam - h * 0.02], fill=GREEN)

    # ---- lock ----
    ls = w * 0.20
    lx0, ly0 = cx - ls / 2, seam - ls * 0.45
    d.rounded_rectangle([lx0, ly0, lx0 + ls, ly0 + ls], radius=ls * 0.22,
                        fill=GREEN, outline=GREEN_DEEP, width=int(w * 0.012))
    # keyhole
    kh = cx
    d.ellipse([kh - ls * 0.12, ly0 + ls * 0.28, kh + ls * 0.12, ly0 + ls * 0.52],
              fill=BLACK)
    d.polygon([(kh - ls * 0.09, ly0 + ls * 0.44), (kh + ls * 0.09, ly0 + ls * 0.44),
               (kh + ls * 0.05, ly0 + ls * 0.72), (kh - ls * 0.05, ly0 + ls * 0.72)],
              fill=BLACK)

    # chest outline
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=r,
                        outline=GOLD_DK, width=int(w * 0.02))

    # ---- coins spilling ----
    coin_specs = [
        (cx - w * 0.36, y0 + h * 1.02, w * 0.16),
        (cx + w * 0.30, y0 + h * 1.06, w * 0.14),
        (cx - w * 0.05, y0 + h * 1.12, w * 0.17),
        (cx + w * 0.02, y0 + h * 0.9, w * 0.10),
    ]
    for (ccx, ccy, cr) in coin_specs:
        d.ellipse([ccx - cr, ccy - cr * 0.9, ccx + cr, ccy + cr * 0.9],
                  fill=GOLD, outline=GOLD_DK, width=max(2, int(cr * 0.14)))
        d.ellipse([ccx - cr * 0.55, ccy - cr * 0.6, ccx + cr * 0.55, ccy + cr * 0.4],
                  fill=GOLD_L + (150,))
    return img


def compose_full(size, circle=False):
    bg = background(size, rounded=not circle, circle=circle)
    chest = draw_chest(size, scale=0.6)
    return Image.alpha_composite(bg, chest)


def save(img, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path)


DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def main():
    full = compose_full(M)
    rnd = compose_full(M, circle=True)
    fg = draw_chest(M, scale=0.52)          # adaptive foreground (safe zone)
    bg = background(M, rounded=False)        # adaptive background (masked by OS)

    for name, mult in DENSITIES.items():
        legacy = int(48 * mult)
        adaptive = int(108 * mult)
        save(full, f"{RES}/mipmap-{name}/ic_launcher.png", legacy)
        save(rnd, f"{RES}/mipmap-{name}/ic_launcher_round.png", legacy)
        save(fg, f"{RES}/mipmap-{name}/ic_launcher_foreground.png", adaptive)
        save(bg, f"{RES}/mipmap-{name}/ic_launcher_background.png", adaptive)

    os.makedirs(STORE, exist_ok=True)
    full.resize((512, 512), Image.LANCZOS).save(f"{STORE}/play_store_icon.png")
    print("Icon set generated.")


if __name__ == "__main__":
    main()
