#!/usr/bin/env python3
"""Exports every icon size the app needs — Android launcher icons, the iOS
AppIcon set and the Play Store listing icon — from the real Robux Box artwork
in tool/icon_source/, plus the splash-screen hero graphic and the animated
splash's separate crate/coin sprites (generated from code, since no
coins-free, wordmark-free cutout of the supplied artwork exists).

If tool/icon_source/app_icon_source.jpg is ever missing, the launcher-icon
family falls back to a code-drawn emblem (dark angular loot-crate, glowing
green neon seams, hexagonal "R$" badge, gold-and-green R$ coins spilling out,
inside a neon-green rounded-square frame) so the script never hard-fails.

Run: python3 tool/generate_icon.py          # Android + Play Store + splash hero
     python3 tool/generate_icon.py --ios     # iOS AppIcon set (needs ios/ to exist)
"""
import json
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
STORE = os.path.join(ROOT, "assets", "images")
SOURCE_ICON = os.path.join(os.path.dirname(__file__), "icon_source", "app_icon_source.jpg")

# ---- brand palette --------------------------------------------------------
GREEN = (0, 255, 106)
GREEN_BRIGHT = (120, 255, 180)
GREEN_DEEP = (0, 163, 68)
GREEN_DARK = (0, 60, 32)
GOLD_L = (255, 232, 150)
GOLD = (255, 216, 77)
GOLD_D = (240, 160, 0)
GOLD_DK = (140, 86, 0)
INK = (7, 9, 8)
CRATE_HI = (72, 80, 76)
CRATE_LO = (30, 33, 32)
CRATE_EDGE = (4, 5, 5)
CRATE_RIM = (140, 176, 156)
WHITE = (255, 255, 255)

M = 1024  # master render size

FONT_PATH = os.path.join(os.path.dirname(__file__), "fonts", "Outfit-Bold.ttf")


def font(size):
    try:
        return ImageFont.truetype(FONT_PATH, size)
    except OSError:
        return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def centered_text(draw, cx, cy, text, fnt, fill):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), text, font=fnt, fill=fill)


def hex_points(cx, cy, r, rotation=0.0):
    return [
        (cx + r * math.cos(rotation + i * math.pi / 3),
         cy + r * math.sin(rotation + i * math.pi / 3))
        for i in range(6)
    ]


def glow_layer(size, draw_fn, blur):
    """Renders draw_fn onto a blank RGBA canvas then Gaussian-blurs it, giving a
    cheap neon glow (used for seams, borders and the badge halo)."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    return layer.filter(ImageFilter.GaussianBlur(blur))


# ---------------------------------------------------------------------------
# Backgrounds
# ---------------------------------------------------------------------------
def plain_background(size, rounded=True, circle=False):
    """Dark vertical gradient with a soft green radial glow (adaptive-icon bg /
    legacy icon base)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad = Image.new("RGBA", (size, size))
    gp = grad.load()
    for y in range(size):
        t = y / size
        c = lerp((14, 24, 18), (8, 8, 8), t)
        for x in range(size):
            gp[x, y] = c + (255,)
    glow = glow_layer(size, lambda d: d.ellipse(
        [size * 0.12, size * 0.05, size * 0.88, size * 0.8], fill=GREEN + (65,)),
        size * 0.12)
    grad = Image.alpha_composite(grad, glow)
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


def hex_texture(size, cx, cy, spread, count=10, seed=7):
    """A handful of faint hexagon outlines scattered behind the emblem."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rnd = [((seed * (i + 1) * 37) % 100) / 100 for i in range(count * 3)]
    for i in range(count):
        ang = rnd[i * 3] * 2 * math.pi
        dist = (0.25 + rnd[i * 3 + 1] * 0.75) * spread
        hx, hy = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
        hr = size * (0.05 + rnd[i * 3 + 2] * 0.05)
        d.polygon(hex_points(hx, hy, hr, rotation=math.pi / 6),
                  outline=GREEN + (26,), width=max(1, int(size * 0.0025)))
    return layer


def sparkles(size, cx, cy, spread, count=9, seed=3):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rnd = [((seed * (i + 1) * 53) % 100) / 100 for i in range(count * 4)]
    for i in range(count):
        ang = rnd[i * 4] * 2 * math.pi
        dist = rnd[i * 4 + 1] * spread
        sx, sy = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
        sr = size * (0.006 + rnd[i * 4 + 2] * 0.012)
        alpha = int(90 + rnd[i * 4 + 3] * 140)
        col = (GOLD_L if i % 2 == 0 else GREEN_BRIGHT) + (alpha,)
        d.line([sx - sr * 2, sy, sx + sr * 2, sy], fill=col, width=max(1, int(sr * 0.5)))
        d.line([sx, sy - sr * 2, sx, sy + sr * 2], fill=col, width=max(1, int(sr * 0.5)))
        d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=col)
    return layer


# ---------------------------------------------------------------------------
# The crate + coins emblem
# ---------------------------------------------------------------------------
def draw_coin(size, fill=True):
    """One coin sprite (unrotated), transparent background: gold beveled ring
    around a green face with a bold 'R$' mark."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    r = size * 0.46
    # outer gold ring with a directional bevel (light top-left, dark bottom-right)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD_DK)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=GOLD_L, width=max(2, int(r * 0.05)))
    ring_w = r * 0.16
    d.ellipse([cx - r + ring_w, cy - r + ring_w, cx + r - ring_w, cy + r - ring_w],
              fill=GREEN_DARK)
    # bevel highlight arc (top-left) and shadow arc (bottom-right) on the ring
    hi = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)
    hd.arc([cx - r, cy - r, cx + r, cy + r], 200, 340, fill=GOLD_L + (200,), width=int(ring_w))
    hd.arc([cx - r, cy - r, cx + r, cy + r], 20, 160, fill=GOLD_DK + (200,), width=int(ring_w))
    img = Image.alpha_composite(img, hi)
    d = ImageDraw.Draw(img)
    # green face with a subtle highlight
    fr = r - ring_w
    d.ellipse([cx - fr, cy - fr, cx + fr, cy + fr], fill=GREEN_DEEP)
    d.ellipse([cx - fr, cy - fr * 1.05, cx + fr, cy + fr * 0.3], fill=GREEN + (55,))
    d.ellipse([cx - fr, cy - fr, cx + fr, cy + fr], outline=INK + (140,), width=max(1, int(fr * 0.04)))
    centered_text(d, cx, cy + fr * 0.03, "R$", font(int(fr * 1.15)), GOLD_L)
    return img


def paste_rotated(base, sprite, cx, cy, angle):
    rot = sprite.rotate(angle, expand=True, resample=Image.BICUBIC)
    base.alpha_composite(rot, (int(cx - rot.width / 2), int(cy - rot.height / 2)))


def draw_crate(size, scale=0.6, coins=True):
    """A dark angular loot-crate with glowing green seams and a hex R$ badge,
    with coins spilling out the top. Transparent background.

    `coins=False` renders the crate + badge alone (no coins baked in) — used
    for the splash screen, where the coins are separate, independently
    animated Flutter widgets instead of static pixels."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = size / 2
    w = size * scale
    h = w * 0.82
    x0, x1 = cx - w / 2, cx + w / 2
    y0 = size / 2 - h / 2 + h * 0.10
    y1 = y0 + h
    r = w * 0.07
    seam = y0 + h * 0.36

    # drop shadow
    sh = glow_layer(size, lambda d: d.rounded_rectangle(
        [x0, y0 + h * 0.08, x1, y1 + h * 0.05], radius=r, fill=(0, 0, 0, 170)),
        size * 0.018)
    img = Image.alpha_composite(img, sh)

    # ---- lower body ----
    body = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle([x0, seam - r, x1, y1], radius=r, fill=CRATE_LO)
    # bottom shading
    bd.rounded_rectangle([x0, y1 - h * 0.16, x1, y1], radius=r, fill=CRATE_EDGE + (160,))
    img = Image.alpha_composite(img, body)

    # ---- lid ----
    lid = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lid)
    ld.rounded_rectangle([x0, y0, x1, seam + r], radius=r * 1.2, fill=CRATE_HI)
    ld.rounded_rectangle([x0 + w * 0.05, y0 + h * 0.05, x1 - w * 0.05, y0 + h * 0.16],
                         radius=r * 0.6, fill=(255, 255, 255, 30))
    img = Image.alpha_composite(img, lid)
    d = ImageDraw.Draw(img)

    # ---- glowing seam band (lid/body join) ----
    seam_glow = glow_layer(size, lambda dd: dd.rectangle(
        [x0, seam - h * 0.05, x1, seam + h * 0.05], fill=GREEN + (180,)), size * 0.012)
    img = Image.alpha_composite(img, seam_glow)
    d = ImageDraw.Draw(img)
    d.rectangle([x0, seam - h * 0.018, x1, seam + h * 0.018], fill=GREEN_BRIGHT)

    # ---- crisp rim outline so the crate reads as a distinct object ----
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, outline=CRATE_RIM, width=max(2, int(w * 0.010)))

    # ---- hexagon R$ badge ----
    hr = w * 0.24
    hy = seam + h * 0.06
    badge_glow = glow_layer(size, lambda dd: dd.polygon(
        hex_points(cx, hy, hr * 1.15, rotation=math.pi / 6), fill=GREEN + (150,)),
        size * 0.02)
    img = Image.alpha_composite(img, badge_glow)
    d = ImageDraw.Draw(img)
    d.polygon(hex_points(cx, hy, hr, rotation=math.pi / 6), fill=INK,
              outline=GREEN_BRIGHT, width=max(3, int(w * 0.016)))
    d.polygon(hex_points(cx, hy, hr * 0.86, rotation=math.pi / 6),
              outline=GREEN_DEEP + (150,), width=max(1, int(w * 0.006)))
    centered_text(d, cx, hy + hr * 0.02, "R$", font(int(hr * 1.05)), GREEN_BRIGHT)

    # ---- coins spilling out the top ----
    if coins:
        # (dx, dy) are fractions of (w, h) from the crate centre/top; kept
        # shallow so even the highest coin's radius stays inside the frame.
        coin_specs = [
            (-0.34, -0.16, 0.105, -16),
            (0.30, -0.18, 0.095, 18),
            (-0.05, -0.24, 0.100, -4),
            (0.15, -0.08, 0.078, 14),
            (-0.20, -0.01, 0.072, -22),
        ]
        for (dx, dy, rr, rot) in coin_specs:
            r_px = int(size * rr)
            coin = draw_coin(r_px * 2)
            paste_rotated(img, coin, cx + w * dx, y0 + h * dy, rot)

    return img


def compose_emblem(size):
    """Crate + coins only, transparent background — used for the Android
    adaptive-icon foreground layer. Scaled down from the hero's 0.58 because
    adaptive launchers crop roughly the outer third of the foreground canvas
    (the "safe zone"), so the art must not extend that far out."""
    return draw_crate(size, scale=0.46)


def compose_hero(size, square_corners=False):
    """The full branded emblem: dark rounded-square backdrop, green radial
    glow, faint hex texture, a glowing neon border frame, sparkles, and the
    crate+coins centered inside. This is the one true "logo" — used for the
    legacy Android icon, the Play Store icon, the iOS AppIcon and the splash
    screen hero graphic.
    """
    cx = cy = size / 2
    img = plain_background(size, rounded=not square_corners, circle=False)
    img = Image.alpha_composite(img, hex_texture(size, cx, cy, size * 0.42))
    img = Image.alpha_composite(img, sparkles(size, cx, cy, size * 0.40))
    img = Image.alpha_composite(img, draw_crate(size, scale=0.58))

    # neon border frame, inset so OS/store corner-masking never clips it badly
    inset = size * 0.045
    radius = size * 0.20
    width = max(3, int(size * 0.012))
    border_glow = glow_layer(size, lambda d: d.rounded_rectangle(
        [inset, inset, size - inset, size - inset], radius=radius,
        outline=GREEN + (220,), width=width * 3), size * 0.016)
    img = Image.alpha_composite(img, border_glow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([inset, inset, size - inset, size - inset], radius=radius,
                        outline=GREEN_BRIGHT, width=width)
    return img


def load_hero_source(size=M):
    """The real Robux Box icon artwork (a square, already-composed render)
    supplied by the team, in place of the code-drawn emblem. Returns an
    opaque RGB image at size x size. Falls back to the procedural emblem if
    the source file isn't present."""
    if not os.path.isfile(SOURCE_ICON):
        print(f"  (no supplied icon art at {SOURCE_ICON} — falling back to procedural emblem)")
        return compose_hero(size, square_corners=True).convert("RGB")
    img = Image.open(SOURCE_ICON).convert("RGB")
    w, h = img.size
    side = min(w, h)
    img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
    return img.resize((size, size), Image.LANCZOS)


def adaptive_foreground_from_source(size):
    """Adaptive-icon foreground: the supplied artwork scaled into Android's
    ~72dp safe zone (of the 108dp canvas) so launcher masks — circle, squircle,
    whatever the OEM picks — never clip into the crate or the wordmark,
    centred on transparency."""
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


def _ios_square():
    """Opaque, square (no rounding, no alpha) master for iOS."""
    return load_hero_source(M)


def generate_ios():
    out = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if not os.path.isdir(os.path.dirname(out)):
        print("  ios/ not generated yet — run flutter create first; skipping.")
        return
    os.makedirs(out, exist_ok=True)
    master = _ios_square()
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

    # Splash-screen hero and the animated splash's separate crate/coin sprites
    # stay procedurally generated: the supplied artwork is a single flattened
    # composition (coins + wordmark baked in) with no separable crate-only
    # cutout, so it can't feed the splash's independently animated pieces.
    splash = compose_hero(768)
    splash.save(f"{STORE}/splash_logo.png")

    badge = draw_crate(900, scale=0.66, coins=False)
    badge.save(f"{STORE}/crate_badge.png")
    coin_sprite = draw_coin(320)
    coin_sprite.save(f"{STORE}/coin.png")

    print("Android + store icons generated from supplied artwork; splash assets generated procedurally.")


if __name__ == "__main__":
    if "--ios" in sys.argv:
        generate_ios()
    else:
        main()
