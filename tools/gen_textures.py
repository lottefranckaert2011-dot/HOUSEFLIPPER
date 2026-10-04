#!/usr/bin/env python3
"""Generates the game's self-made, tileable textures into assets/textures/.

Run from the repo root:  python3 tools/gen_textures.py
Requires Pillow and numpy.
"""

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
S = 512
rng = random.Random(42)
np_rng = np.random.default_rng(42)


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def tile_noise(size, scale, octaves=4):
    """Tileable value noise in [0,1]."""
    out = np.zeros((size, size))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cells = max(1, int(scale * (2**o)))
        grid = np_rng.random((cells, cells))
        grid = np.vstack([grid, grid[:1]])
        grid = np.hstack([grid, grid[:, :1]])
        img = Image.fromarray((grid * 255).astype(np.uint8)).resize(
            (size + size // cells, size + size // cells), Image.BICUBIC
        )
        arr = np.asarray(img, dtype=float)[:size, :size] / 255.0
        out += arr * amp
        total += amp
        amp *= 0.5
    return out / total


def apply_noise(img, strength, scale=8):
    arr = np.asarray(img.convert("RGB"), dtype=float)
    n = (tile_noise(img.width, scale) - 0.5) * 2 * strength
    arr = np.clip(arr + n[..., None], 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


def draw_wrapped(draw_fn, size):
    """Calls draw_fn(dx, dy) for the 9 wrap offsets so shapes tile seamlessly."""
    for dx in (-size, 0, size):
        for dy in (-size, 0, size):
            draw_fn(dx, dy)


# --- Wallpapers -----------------------------------------------------------------


def wallpaper_floral():
    img = Image.new("RGBA", (S, S), hexc("#e9dfc6"))
    d = ImageDraw.Draw(img)
    spots = []
    for row in range(4):
        for col in range(4):
            x = col * S / 4 + (S / 8 if row % 2 else 0)
            y = row * S / 4
            spots.append((x, y, rng.choice(["#8aa37a", "#7d93a6", "#9fb08a"])))

    for x, y, c in spots:
        def flower(dx, dy, x=x, y=y, c=c):
            cx, cy = x + dx, y + dy
            for i in range(6):
                a = i * math.pi / 3
                px, py = cx + math.cos(a) * 22, cy + math.sin(a) * 22
                d.ellipse([px - 16, py - 16, px + 16, py + 16], fill=hexc(c))
            d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=hexc("#d8c98f"))
            # leaves
            for a in (0.8, 3.9):
                lx, ly = cx + math.cos(a) * 52, cy + math.sin(a) * 52
                d.ellipse([lx - 18, ly - 8, lx + 18, ly + 8], fill=hexc("#a9b48d"))
        draw_wrapped(flower, S)
    save(apply_noise(img, 10), "wallpaper_floral")


def wallpaper_leaf():
    img = Image.new("RGBA", (S, S), hexc("#cfccc6"))
    d = ImageDraw.Draw(img)
    for row in range(4):
        for col in range(4):
            x = col * S / 4 + (S / 8 if row % 2 else 0)
            y = row * S / 4 + S / 8

            def leaf(dx, dy, x=x, y=y):
                cx, cy = x + dx, y + dy
                d.ellipse([cx - 26, cy - 50, cx + 26, cy + 50], fill=hexc("#5f6b78"))
                d.ellipse([cx - 20, cy - 43, cx + 20, cy + 43], fill=hexc("#253248"))
                d.line([cx, cy - 40, cx, cy + 40], fill=hexc("#7a8899"), width=3)
            draw_wrapped(leaf, S)
    save(apply_noise(img, 6), "wallpaper_leaf")


def wallpaper_stripes():
    img = Image.new("RGBA", (S, S), hexc("#f1e6d2"))
    d = ImageDraw.Draw(img)
    for i in range(8):
        x = i * S / 8
        d.rectangle([x, 0, x + S / 16, S], fill=hexc("#c97b6b"))
        d.rectangle([x + S / 16 + 6, 0, x + S / 16 + 9, S], fill=hexc("#d9a89a"))
    save(apply_noise(img, 6), "wallpaper_stripes")


def wallpaper_dots():
    img = Image.new("RGBA", (S, S), hexc("#dfeee9"))
    d = ImageDraw.Draw(img)
    for row in range(8):
        for col in range(8):
            x = col * S / 8 + (S / 16 if row % 2 else 0)
            y = row * S / 8 + S / 16

            def dot(dx, dy, x=x, y=y):
                d.ellipse([x + dx - 9, y + dy - 9, x + dx + 9, y + dy + 9], fill=hexc("#5aa59a"))
            draw_wrapped(dot, S)
    save(apply_noise(img, 5), "wallpaper_dots")


def wallpaper_brick():
    img = Image.new("RGBA", (S, S), hexc("#d8d2c8"))
    d = ImageDraw.Draw(img)
    bh, bw = S // 8, S // 4
    for row in range(8):
        off = bw // 2 if row % 2 else 0
        for col in range(-1, 5):
            x = col * bw + off
            y = row * bh
            shade = rng.randint(-18, 18)
            base = (164 + shade, 84 + shade // 2, 62 + shade // 2, 255)
            d.rectangle([x + 3, y + 3, x + bw - 3, y + bh - 3], fill=base)
    save(apply_noise(img, 14, 16), "wallpaper_brick")


# --- Floors ---------------------------------------------------------------------


def floor_wood():
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    rows = 8
    ph = S // rows
    for r in range(rows):
        off = rng.randint(0, S)
        for k in range(3):
            x0 = (off + k * S // 2) % S
            tone = rng.randint(-20, 20)
            col = (176 + tone, 122 + tone, 78 + tone // 2)
            for dx in (-S, 0):
                d.rectangle([x0 + dx, r * ph, x0 + dx + S // 2, r * ph + ph], fill=col)
                d.line([x0 + dx, r * ph, x0 + dx, r * ph + ph], fill=(110, 72, 44), width=2)
        d.line([0, r * ph, S, r * ph], fill=(110, 72, 44), width=3)
    arr = np.asarray(img, dtype=float)
    grain = tile_noise(S, 2, 3)
    grain = np.sin(np.linspace(0, 60 * math.pi, S)[None, :] + grain * 12) * 8
    arr = np.clip(arr + grain[..., None], 0, 255)
    save(apply_noise(Image.fromarray(arr.astype(np.uint8)), 8, 16), "floor_wood")


def floor_carpet_grey():
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    n = 4
    t = S // n
    for r in range(n):
        for c in range(n):
            tone = rng.choice([92, 118, 140, 104])
            d.rectangle([c * t, r * t, c * t + t, r * t + t], fill=(tone, tone, tone + 4))
            for k in range(0, t, 6):
                if (r + c) % 2:
                    d.line([c * t + k, r * t, c * t + k, r * t + t], fill=(tone - 18,) * 3, width=2)
                else:
                    d.line([c * t, r * t + k, c * t + t, r * t + k], fill=(tone - 18,) * 3, width=2)
    arr = np.asarray(img, dtype=float) + (np_rng.random((S, S, 1)) - 0.5) * 30
    save(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)), "floor_carpet_grey")


def floor_carpet_old():
    img = Image.new("RGB", (S, S), (128, 102, 74))
    d = ImageDraw.Draw(img)
    t = S // 8
    for r in range(8):
        for c in range(8):
            for k in range(3, t, 9):
                if (r + c) % 2:
                    d.line([c * t + k, r * t, c * t + k, r * t + t], fill=(104, 82, 58), width=4)
                else:
                    d.line([c * t, r * t + k, c * t + t, r * t + k], fill=(104, 82, 58), width=4)
    arr = np.asarray(img, dtype=float) + (np_rng.random((S, S, 1)) - 0.5) * 26
    save(apply_noise(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)), 18, 4), "floor_carpet_old")


def tiles(name, base, grout, n, var=10):
    img = Image.new("RGB", (S, S), grout)
    d = ImageDraw.Draw(img)
    t = S // n
    for r in range(n):
        for c in range(n):
            tone = rng.randint(-var, var)
            col = tuple(max(0, min(255, v + tone)) for v in base)
            d.rectangle([c * t + 3, r * t + 3, c * t + t - 3, r * t + t - 3], fill=col)
    save(apply_noise(img, 8, 12), name)


def floor_checker():
    img = Image.new("RGB", (S, S), (60, 60, 60))
    d = ImageDraw.Draw(img)
    n = 8
    t = S // n
    for r in range(n):
        for c in range(n):
            col = (235, 233, 228) if (r + c) % 2 else (40, 42, 46)
            d.rectangle([c * t + 1, r * t + 1, c * t + t - 1, r * t + t - 1], fill=col)
    save(apply_noise(img, 5, 12), "floor_checker")


def floor_marble():
    n = tile_noise(S, 3, 5)
    veins = np.clip(np.abs(np.sin(n * 14)) * 5, 0, 1) ** 0.6
    shade = 236 - (1 - veins) * 60
    arr = np.stack([shade, shade - 2, shade - 6], axis=-1)
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for i in range(0, S + 1, S // 2):
        d.line([i, 0, i, S], fill=(180, 178, 172), width=2)
        d.line([0, i, S, i], fill=(180, 178, 172), width=2)
    save(img, "floor_marble")


# --- Exterior -------------------------------------------------------------------


def grass():
    base = tile_noise(S, 6, 5)
    arr = np.stack([60 + base * 40, 128 + base * 60, 42 + base * 25], axis=-1)
    arr += (np_rng.random((S, S, 1)) - 0.5) * 40
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for _ in range(2500):
        x, y = rng.randrange(S), rng.randrange(S)
        g = rng.randint(120, 200)
        d.line([x, y, x + rng.randint(-2, 2), y - rng.randint(3, 8)], fill=(50, g, 40))
    save(img, "grass")


def siding():
    img = Image.new("RGB", (S, S), (226, 205, 160))
    d = ImageDraw.Draw(img)
    n = 16
    h = S // n
    for i in range(n):
        y = i * h
        for k in range(h):
            v = int(-14 * (k / h))
            d.line([0, y + k, S, y + k], fill=(226 + v, 205 + v, 160 + v))
        d.line([0, y + h - 2, S, y + h - 2], fill=(170, 150, 110), width=2)
    save(apply_noise(img, 5, 16), "siding")


def roof():
    img = Image.new("RGB", (S, S), (120, 124, 128))
    d = ImageDraw.Draw(img)
    rows, cols = 16, 8
    h, w = S // rows, S // cols
    for r in range(rows):
        off = w // 2 if r % 2 else 0
        for c in range(-1, cols + 1):
            tone = rng.randint(-25, 25)
            x = c * w + off
            d.rectangle([x + 1, r * h + 1, x + w - 1, r * h + h - 1], fill=(150 + tone, 152 + tone, 156 + tone))
        d.line([0, r * h, S, r * h], fill=(80, 82, 86), width=3)
    save(apply_noise(img, 10, 16), "roof")


def concrete():
    n = tile_noise(S, 8, 5)
    arr = 190 + (n - 0.5) * 40 + (np_rng.random((S, S)) - 0.5) * 18
    img = Image.fromarray(np.clip(np.stack([arr, arr, arr - 4], -1), 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.line([0, 0, S, 0], fill=(130, 130, 128), width=4)
    d.line([0, 0, 0, S], fill=(130, 130, 128), width=4)
    save(img, "concrete")


def wood_deck():
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    n = 8
    w = S // n
    for i in range(n):
        tone = rng.randint(-15, 15)
        d.rectangle([i * w, 0, i * w + w, S], fill=(196 + tone, 160 + tone, 120 + tone))
        d.line([i * w, 0, i * w, S], fill=(120, 90, 60), width=4)
    arr = np.asarray(img, dtype=float)
    grain = np.sin(np.linspace(0, 40 * math.pi, S)[:, None] + tile_noise(S, 2, 3) * 10) * 7
    arr = np.clip(arr + grain[..., None], 0, 255)
    save(Image.fromarray(arr.astype(np.uint8)), "wood_deck")


# --- Dirt / props ---------------------------------------------------------------


def dirt(name, color, blobs, soft):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    mask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(mask)
    for _ in range(blobs):
        r = rng.randint(20, 90)
        x = rng.randint(140, S - 140)
        y = rng.randint(140, S - 140)
        d.ellipse([x - r, y - r, x + r, y + r], fill=rng.randint(120, 230))
    for _ in range(blobs * 8):
        r = rng.randint(3, 14)
        a = rng.random() * math.tau
        dist = rng.randint(60, 220)
        x, y = S / 2 + math.cos(a) * dist, S / 2 + math.sin(a) * dist
        d.ellipse([x - r, y - r, x + r, y + r], fill=rng.randint(90, 200))
    mask = mask.filter(ImageFilter.GaussianBlur(soft))
    n = tile_noise(S, 10, 4)
    m = np.asarray(mask, dtype=float) * (0.55 + n * 0.6)
    # fade at the edges so the quad border never shows
    yy, xx = np.mgrid[0:S, 0:S]
    edge = np.clip((S / 2 - np.hypot(xx - S / 2, yy - S / 2)) / 40, 0, 1)
    m = np.clip(m * edge, 0, 255)
    rgb = np.zeros((S, S, 3)) + np.array(color[:3])
    rgb += (n[..., None] - 0.5) * 40
    img = Image.fromarray(np.dstack([np.clip(rgb, 0, 255), m]).astype(np.uint8), "RGBA")
    save(img.resize((256, 256), Image.LANCZOS), name)


def pizza_box():
    img = Image.new("RGB", (256, 256), (222, 170, 118))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 251, 251], outline=(190, 140, 92), width=4)
    d.ellipse([58, 58, 198, 198], outline=(214, 92, 50), width=8)
    for i in range(8):
        a = i * math.pi / 4
        d.line([128, 128, 128 + math.cos(a) * 66, 128 + math.sin(a) * 66], fill=(214, 92, 50), width=5)
    for x, y in [(100, 100), (150, 110), (120, 160), (160, 150), (95, 140)]:
        d.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(214, 92, 50))
    save(apply_noise(img, 8, 8), "pizza_box")


def crack():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(3):
        x, y = 128, 128
        a = rng.random() * math.tau
        for _ in range(14):
            a += rng.uniform(-0.7, 0.7)
            nx, ny = x + math.cos(a) * 9, y + math.sin(a) * 9
            d.line([x, y, nx, ny], fill=(50, 40, 32, 230), width=3)
            x, y = nx, ny
    save(img, "crack")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    wallpaper_floral()
    wallpaper_leaf()
    wallpaper_stripes()
    wallpaper_dots()
    wallpaper_brick()
    floor_wood()
    floor_carpet_grey()
    floor_carpet_old()
    tiles("floor_tiles_beige", (176, 154, 130), (214, 204, 190), 4)
    tiles("wall_tiles_beige", (190, 168, 144), (226, 218, 206), 4, 6)
    tiles("wall_tiles_white", (232, 234, 236), (190, 194, 198), 8, 4)
    floor_checker()
    floor_marble()
    grass()
    siding()
    roof()
    concrete()
    wood_deck()
    dirt("dirt_floor", (74, 56, 36), 7, 14)
    dirt("dirt_wall", (58, 52, 30), 5, 10)
    pizza_box()
    crack()
