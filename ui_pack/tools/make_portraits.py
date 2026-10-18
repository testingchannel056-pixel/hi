#!/usr/bin/env python3
"""Draw the layered pixel portraits for Murim Life.

Run:  python3 tools/make_portraits.py [grid]
Writes every layer twice:
  ../portraits/        512 x 512   the copies the game loads (fast on phones)
  ../portraits_1024/   1024 x 1024 full-size masters (Godot ignores this folder)

Everything is drawn on a GRID x GRID pixel canvas using coordinates from 0 to 1,
then scaled up without smoothing. GRID is the "pixel art resolution":
1024 = smooth and detailed (default), 256 = classic pixel art, 128 = chunky.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

GRID = int(sys.argv[1]) if len(sys.argv) > 1 else 1024
OUT = 1024          # size of the masters
GAME = 512          # size of the copies the game loads
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, "..", "portraits")
MASTERS = os.path.join(HERE, "..", "portraits_1024")
CX = 0.5
PX = 1.0 / GRID
YY, XX = np.mgrid[0:GRID, 0:GRID]
CHECK = (XX + YY) % 2 == 0
DISC = ((XX + 0.5) / GRID - 0.5) ** 2 + ((YY + 0.5) / GRID - 0.5) ** 2 <= 0.478 ** 2


# ------------------------------------------------------------ drawing helpers

def canvas():
    return np.zeros((GRID, GRID, 4), np.uint8)


def _mask(fn):
    im = Image.new("L", (GRID, GRID), 0)
    fn(ImageDraw.Draw(im))
    return np.array(im) > 0


def ell(cx, cy, rx, ry):
    return _mask(lambda d: d.ellipse([(cx - rx) * GRID, (cy - ry) * GRID, (cx + rx) * GRID, (cy + ry) * GRID], fill=255))


def poly(pts):
    return _mask(lambda d: d.polygon([(x * GRID, y * GRID) for x, y in pts], fill=255))


def line(pts, width):
    w = max(1, round(width * GRID))
    return _mask(lambda d: d.line([(x * GRID, y * GRID) for x, y in pts], fill=255, width=w, joint="curve"))


def smooth(m, r):
    """Round the corners of a mask."""
    im = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r * GRID))
    return np.array(im) > 127


def shift(m, dx, dy):
    out = np.zeros_like(m)
    h, w = m.shape
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    out[yd, xd] = m[ys, xs]
    return out


def erode(m, n=1):
    for _ in range(n):
        m = m & shift(m, 1, 0) & shift(m, -1, 0) & shift(m, 0, 1) & shift(m, 0, -1)
    return m


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ramp(base, shadow_tint="#3a2448", light_tint="#fff4d8"):
    """highlight, base, shadow, deep shadow, outline for one colour."""
    b, st, lt = hexc(base), hexc(shadow_tint), hexc(light_tint)
    return [mix(b, lt, 0.32), b, mix(b, st, 0.30), mix(b, st, 0.52), mix(b, hexc("#140c18"), 0.72)]


def paint(img, m, col, dither=False):
    if dither:
        m = m & CHECK
    img[m] = (*col, 255)


def part(img, m, pal, depth=0.030, light=0.016, outline=True):
    """Fill a shape and shade it as if lit from the top left."""
    hi, base, sh, deep, ol = pal
    paint(img, m, base)
    d, l = max(2, round(depth * GRID)), max(1, round(light * GRID))
    paint(img, m & ~shift(m, -d, -d), sh, dither=True)
    paint(img, m & ~shift(m, -(d * 2) // 3, -(d * 2) // 3), sh)
    paint(img, m & ~shift(m, -d // 3, -d // 3), deep)
    paint(img, m & ~shift(m, l, l), hi, dither=True)
    paint(img, m & ~shift(m, l // 2, l // 2), hi)
    if outline:
        paint(img, m & ~erode(m, max(1, GRID // 128)), ol)


def save(img, name):
    img = img.copy()
    img[~DISC] = 0
    master = Image.fromarray(img, "RGBA").resize((OUT, OUT), Image.NEAREST)
    master.save(os.path.join(MASTERS, name + ".png"), optimize=True)
    # Shrink with premultiplied alpha ("RGBa") so edges do not pick up a dark fringe.
    small = master.convert("RGBa").resize((GAME, GAME), Image.LANCZOS).convert("RGBA")
    small.save(os.path.join(DEST, name + ".png"), optimize=True)


# ------------------------------------------------------------ proportions

STAGES = {
    "child": dict(cy=0.470, rx=0.170, ry=0.178, jaw=0.68, chin=0.97, eye=1.40, eye_y=0.040, neck=0.050, sh_w=0.250, sh_y=0.735),
    "teen":  dict(cy=0.435, rx=0.164, ry=0.186, jaw=0.70, chin=0.99, eye=1.15, eye_y=0.026, neck=0.058, sh_w=0.320, sh_y=0.715),
    "adult": dict(cy=0.405, rx=0.158, ry=0.196, jaw=0.64, chin=1.04, eye=1.00, eye_y=0.016, neck=0.066, sh_w=0.390, sh_y=0.695),
    "elder": dict(cy=0.410, rx=0.156, ry=0.194, jaw=0.62, chin=1.03, eye=0.90, eye_y=0.018, neck=0.062, sh_w=0.370, sh_y=0.700),
}
SKINS = ["#f4d3b4", "#e3b48c", "#c08a60"]
HAIR = {"black": "#23212c", "brown": "#4a2f1e", "grey": "#8d8d96", "white": "#d6d6dc"}
STAGE_HAIR = {"child": ["black", "brown"], "teen": ["black", "brown"], "adult": ["black", "brown"], "elder": ["grey", "white"]}
STYLES = {"male": ["topknot", "long", "short"], "female": ["bun", "loose", "twin"]}


def geo(stage, gender):
    g = dict(STAGES[stage])
    if gender == "male" and stage != "child":
        g["jaw"] += 0.09
        g["neck"] += 0.012
    return g


def face_mask(g):
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    skull = ell(CX, cy - ry * 0.10, rx, ry * 0.92)
    jaw = poly([(CX - rx, cy - 0.02), (CX + rx, cy - 0.02), (CX + rx * 0.97, cy + ry * 0.35),
                (CX + rx * g["jaw"], cy + ry * 0.78), (CX + rx * 0.30, cy + ry * g["chin"]),
                (CX - rx * 0.30, cy + ry * g["chin"]), (CX - rx * g["jaw"], cy + ry * 0.78),
                (CX - rx * 0.97, cy + ry * 0.35)])
    return smooth(skull | jaw, 0.012)


# ------------------------------------------------------------ body (head, face, neck)

def draw_body(gender, stage, skin):
    g = geo(stage, gender)
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    img = canvas()
    pal = ramp(SKINS[skin], "#8a3a4a", "#fff0dc")
    hi, base, sh, deep, ol = pal
    female, child, elder = gender == "female", stage == "child", stage == "elder"

    # neck and the bit of chest the collar leaves open
    neck = poly([(CX - g["neck"], cy + ry * 0.5), (CX + g["neck"], cy + ry * 0.5),
                 (CX + g["neck"] * 1.25, g["sh_y"] + 0.05), (CX - g["neck"] * 1.25, g["sh_y"] + 0.05)])
    chest = ell(CX, g["sh_y"] + 0.11, g["neck"] * 2.3, 0.10)
    part(img, smooth(neck | chest, 0.006), pal, depth=0.02)
    paint(img, (neck | chest) & ell(CX + 0.01, cy + ry * 1.02, rx * 0.80, ry * 0.30), sh)       # shadow under the chin
    paint(img, (neck | chest) & ell(CX + 0.012, cy + ry * 1.10, rx * 0.85, ry * 0.30) & ~ell(CX + 0.01, cy + ry * 1.02, rx * 0.80, ry * 0.30), sh, dither=True)

    # ears
    ear_y = cy + g["eye_y"] + 0.022
    for s in (-1, 1):
        ear = ell(CX + s * rx * 0.99, ear_y, 0.024, 0.038)
        part(img, ear, pal, depth=0.012, light=0.006)
        paint(img, ell(CX + s * rx * 1.00, ear_y + 0.003, 0.009, 0.018), sh)

    face = face_mask(g)
    part(img, face, pal, depth=0.040, light=0.020)

    # eyes
    ew, eh = 0.037 * g["eye"], 0.0195 * g["eye"] * (1.15 if female else 1.0)
    ey = cy + g["eye_y"] + 0.010
    dark = hexc("#8c8c92") if elder else hexc("#2a1a18")
    lid = hexc("#2a1a18")
    for s in (-1, 1):
        ex = CX + s * rx * 0.47
        socket = ell(ex, ey - eh * 0.2, ew * 1.35, eh * 2.1) & face
        paint(img, socket & ~shift(socket, 0, max(1, GRID // 128)), sh, dither=True)            # soft shadow under the brow
        white = ell(ex, ey, ew, eh)
        paint(img, white, hexc("#fbf6ee"))
        paint(img, white & ell(ex, ey - eh * 1.1, ew * 1.2, eh), hexc("#d9d2d6"))               # lid shadow on the eyeball
        iris = ell(ex + 0.002, ey + 0.001, eh * 1.02, eh * 1.08) & white
        paint(img, iris, hexc("#5a3a26"))
        paint(img, iris & ell(ex + 0.002, ey - eh * 0.35, eh * 1.02, eh * 0.8), hexc("#3a2418"))
        paint(img, ell(ex + 0.002, ey + 0.001, eh * 0.52, eh * 0.56) & white, hexc("#120a0c"))
        paint(img, ell(ex - eh * 0.42, ey - eh * 0.40, max(PX, eh * 0.26), max(PX, eh * 0.26)), hexc("#ffffff"))
        upper = line([(ex - s * ew * 1.02, ey - eh * 0.15), (ex - s * ew * 0.5, ey - eh * 0.95), (ex, ey - eh * 1.12),
                      (ex + s * ew * 0.55, ey - eh * 0.85), (ex + s * ew * 1.05, ey - eh * 0.05)], 0.009 if female else 0.007)
        paint(img, upper, lid)
        if female:                                                                              # lash wing
            paint(img, line([(ex + s * ew * 0.9, ey - eh * 0.35), (ex + s * ew * 1.35, ey - eh * 0.85)], 0.007), lid)
        paint(img, line([(ex - s * ew * 0.6, ey + eh * 1.05), (ex + s * ew * 0.7, ey + eh * 1.0)], 0.004), sh)
        if elder:
            paint(img, line([(ex - s * ew * 0.7, ey + eh * 1.9), (ex + s * ew * 0.8, ey + eh * 1.7)], 0.004), sh)
            for k in (-0.5, 0.4):
                paint(img, line([(ex + s * ew * 1.25, ey + eh * k), (ex + s * ew * 1.65, ey + eh * (k * 2.2))], 0.004), sh)
        # brow: inner end towards the nose
        bw = (0.013 if not female else 0.007) * (1.0 if not child else 0.8)
        brow = line([(ex - s * ew * 0.95, ey - eh * (2.25 if not female else 2.45)), (ex, ey - eh * 2.95),
                     (ex + s * ew * 1.30, ey - eh * 2.30)], bw)
        paint(img, brow, dark)

    # blush
    if child or female or stage == "teen":
        for s in (-1, 1):
            paint(img, ell(CX + s * rx * 0.55, ey + eh * 3.3, 0.034, 0.017) & face, hexc("#ec9d92"), dither=True)

    # nose
    if child:
        paint(img, ell(CX + 0.004, cy + ry * 0.36, 0.008, 0.006), sh)
    else:
        paint(img, line([(CX + 0.006, cy + ry * 0.14), (CX + 0.016, cy + ry * 0.37), (CX + 0.004, cy + ry * 0.43)], 0.006), sh)
        paint(img, line([(CX - 0.014, cy + ry * 0.42), (CX + 0.012, cy + ry * 0.44)], 0.004), deep)
        paint(img, ell(CX - 0.006, cy + ry * 0.33, 0.006, 0.014), hi)

    # mouth
    my = cy + ry * (0.66 if not child else 0.62)
    mw = rx * (0.36 if not child else 0.27)
    lip = hexc("#7a3b34")
    if child:
        paint(img, line([(CX - mw, my - 0.004), (CX - mw * 0.4, my + 0.005), (CX + mw * 0.4, my + 0.005), (CX + mw, my - 0.004)], 0.006), lip)
    elif female:
        paint(img, smooth(poly([(CX - mw, my), (CX - mw * 0.35, my - 0.010), (CX, my - 0.006), (CX + mw * 0.35, my - 0.010), (CX + mw, my)]), 0.002), hexc("#b9504e"))
        paint(img, ell(CX, my + 0.006, mw * 0.72, 0.009), hexc("#d0706a"))
        paint(img, line([(CX - mw, my), (CX, my + 0.002), (CX + mw, my)], 0.004), lip)
    else:
        paint(img, line([(CX - mw, my - 0.001), (CX, my + 0.003), (CX + mw, my - 0.001)], 0.006), lip)
        paint(img, line([(CX - mw * 0.5, my + 0.016), (CX + mw * 0.5, my + 0.016)], 0.004), sh)

    if elder:
        for k in (0.50, 0.38):
            paint(img, line([(CX - rx * 0.42, cy - ry * k), (CX, cy - ry * (k + 0.03)), (CX + rx * 0.42, cy - ry * k)], 0.004), sh)
        for s in (-1, 1):
            paint(img, line([(CX + s * 0.026, cy + ry * 0.40), (CX + s * mw * 1.25, my + 0.004)], 0.004), sh)
    return img


# ------------------------------------------------------------ hair

def hair_cap(g, fringe, low):
    """Hair on top of the head. `fringe` picks the forehead cut, `low` how far down the sides it reaches."""
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    cap = ell(CX, cy - ry * 0.18, rx * 1.13, ry * 1.04)
    if fringe == "part":
        window = ell(CX - rx * 0.36, cy + ry * 0.42, rx * 0.66, ry * 1.02) | ell(CX + rx * 0.36, cy + ry * 0.42, rx * 0.66, ry * 1.02)
    elif fringe == "swept":
        window = ell(CX - rx * 0.20, cy + ry * 0.46, rx * 0.86, ry * 1.00)
    else:  # bangs
        window = ell(CX, cy + ry * 0.70, rx * 0.90, ry * 0.86)
    cap = cap & ~window & (YY / GRID < cy + ry * low)
    if fringe == "bangs":
        for k in (-0.62, -0.30, 0.02, 0.34, 0.64):
            cap = cap | poly([(CX + rx * (k - 0.16), cy - ry * 0.30), (CX + rx * (k + 0.20), cy - ry * 0.30), (CX + rx * (k + 0.04), cy - ry * 0.14)])
    return cap


def hair_shine(img, cap, g, pal):
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    band = ell(CX - rx * 0.10, cy - ry * 0.30, rx * 0.98, ry * 0.80) & ~ell(CX - rx * 0.08, cy - ry * 0.21, rx * 1.00, ry * 0.80) & cap
    paint(img, band, pal[0], dither=True)
    paint(img, erode(band, max(1, GRID // 128)), pal[0])
    for k in (-0.75, -0.45, 0.2, 0.55, 0.85):                                                    # a few strands
        paint(img, line([(CX + rx * k * 0.6, cy - ry * 1.05), (CX + rx * k, cy - ry * 0.55)], 0.004) & cap, pal[3])


def draw_hair(gender, stage, style, colour):
    g = geo(stage, gender)
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    pal = ramp(HAIR[colour], "#120a20", "#cfd6ff")
    back, front = canvas(), canvas()
    gold, red = ramp("#d8b04c"), ramp("#b53a34")

    def locks(length, width=0.030):
        for s in (-1, 1):
            m = smooth(poly([(CX + s * rx * 0.84, cy - ry * 0.40), (CX + s * rx * 1.12, cy - ry * 0.30),
                             (CX + s * rx * 1.08, cy + ry * length), (CX + s * (rx * 1.08 - width), cy + ry * (length + 0.10)),
                             (CX + s * rx * 0.90, cy + ry * 0.10)]), 0.005)
            part(front, m, pal, depth=0.014, light=0.008)

    if style == "topknot":
        cap = hair_cap(g, "swept", 0.12)
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
        knot = ell(CX, cy - ry * 1.20, 0.046, 0.052)
        part(front, knot, pal, depth=0.016)
        part(front, poly([(CX - 0.050, cy - ry * 1.03), (CX + 0.050, cy - ry * 1.03), (CX + 0.044, cy - ry * 0.96), (CX - 0.044, cy - ry * 0.96)]), red, depth=0.008, light=0.004)
    elif style == "long":
        tail = smooth(poly([(CX - rx * 1.10, cy - ry * 0.40), (CX + rx * 1.10, cy - ry * 0.40), (CX + rx * 1.32, cy + ry * 1.10),
                            (CX + rx * 1.18, 0.99), (CX - rx * 1.18, 0.99), (CX - rx * 1.32, cy + ry * 1.10)]), 0.012)
        part(back, tail, pal, depth=0.03)
        for k in (-1.0, -0.6, 0.6, 1.0):
            paint(back, line([(CX + rx * k, cy + ry * 0.3), (CX + rx * k * 1.08, 0.97)], 0.004) & tail, pal[3])
        cap = hair_cap(g, "part", 0.34)
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
        part(front, ell(CX, cy - ry * 1.14, 0.040, 0.040), pal, depth=0.014)
        part(front, poly([(CX - 0.040, cy - ry * 1.02), (CX + 0.040, cy - ry * 1.02), (CX + 0.036, cy - ry * 0.96), (CX - 0.036, cy - ry * 0.96)]), ramp("#e6e2d6"), depth=0.008, light=0.004)
    elif style == "short":
        cap = hair_cap(g, "bangs", 0.10)
        for k in (-0.95, -0.62, -0.25, 0.12, 0.50, 0.86):                                        # messy spikes
            cap = cap | poly([(CX + rx * (k - 0.26), cy - ry * 0.90), (CX + rx * (k + 0.30), cy - ry * 0.90), (CX + rx * (k * 1.10 + 0.06), cy - ry * (1.46 - abs(k) * 0.30))])
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
    elif style == "bun":
        nape = smooth(poly([(CX - rx * 1.06, cy - ry * 0.30), (CX + rx * 1.06, cy - ry * 0.30), (CX + rx * 1.02, cy + ry * 0.95), (CX - rx * 1.02, cy + ry * 0.95)]), 0.012)
        part(back, nape, pal, depth=0.03)
        cap = hair_cap(g, "part", 0.30)
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
        locks(0.62, 0.022)
        bun = ell(CX, cy - ry * 1.19, 0.070, 0.058)
        part(front, bun, pal, depth=0.02)
        paint(front, line([(CX - 0.105, cy - ry * 1.27), (CX + 0.105, cy - ry * 1.11)], 0.008), gold[1])
        part(front, ell(CX - 0.105, cy - ry * 1.27, 0.012, 0.012), gold, depth=0.006, light=0.004)
        part(front, ell(CX + 0.110, cy - ry * 1.05, 0.010, 0.016), ramp("#5fa88f"), depth=0.006, light=0.004)
    elif style == "loose":
        fall = smooth(poly([(CX - rx * 1.14, cy - ry * 0.50), (CX + rx * 1.14, cy - ry * 0.50), (CX + rx * 1.50, cy + ry * 1.30),
                            (CX + rx * 1.40, 0.99), (CX - rx * 1.40, 0.99), (CX - rx * 1.50, cy + ry * 1.30)]), 0.014)
        part(back, fall, pal, depth=0.03)
        for k in (-1.2, -0.8, 0.8, 1.2):
            paint(back, line([(CX + rx * k, cy + ry * 0.2), (CX + rx * k * 1.10, 0.97)], 0.004) & fall, pal[3])
        cap = hair_cap(g, "bangs", 0.36)
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
        locks(1.15)
        part(front, ell(CX + rx * 0.86, cy - ry * 0.62, 0.016, 0.016), ramp("#d98aa0"), depth=0.006, light=0.004)   # flower clip
    elif style == "twin":
        cap = hair_cap(g, "bangs", 0.22)
        part(front, cap, pal)
        hair_shine(front, cap, g, pal)
        for s in (-1, 1):
            part(front, ell(CX + s * rx * 0.86, cy - ry * 0.98, 0.058, 0.058), pal, depth=0.02)
            part(front, poly([(CX + s * rx * 0.62, cy - ry * 0.78), (CX + s * rx * 0.98, cy - ry * 0.70), (CX + s * rx * 0.94, cy - ry * 0.60), (CX + s * rx * 0.58, cy - ry * 0.68)]), red, depth=0.008, light=0.004)
        locks(0.50, 0.020)
    return back, front


def draw_beard(stage, colour):
    g = geo(stage, "male")
    cy, rx, ry = g["cy"], g["rx"], g["ry"]
    pal = ramp(HAIR[colour], "#120a20", "#cfd6ff")
    img = canvas()
    long = stage == "elder"
    my = cy + ry * 0.66
    tip = cy + ry * (1.75 if long else 1.12)
    bw = 0.56 if long else 0.34
    chin = smooth(poly([(CX - rx * bw, my + 0.030), (CX - rx * 0.16, my + 0.034), (CX + rx * 0.16, my + 0.034), (CX + rx * bw, my + 0.030),
                        (CX + rx * (0.30 if long else 0.40), cy + ry * 1.04), (CX, tip), (CX - rx * (0.30 if long else 0.40), cy + ry * 1.04)]), 0.008)
    part(img, chin, pal, depth=0.02)
    for k in (-0.25, 0.0, 0.25):
        paint(img, line([(CX + rx * k, my + 0.05), (CX + rx * k * 0.5, tip - 0.03)], 0.004) & chin, pal[3])
    for s in (-1, 1):                                                                            # moustache
        m = smooth(poly([(CX + s * 0.004, my - 0.022), (CX + s * rx * 0.50, my - 0.012), (CX + s * rx * (0.62 if long else 0.52), my + (0.060 if long else 0.020)),
                         (CX + s * rx * 0.36, my + 0.004), (CX + s * 0.004, my - 0.008)]), 0.003)
        part(img, m, pal, depth=0.008, light=0.004)
    return img


# ------------------------------------------------------------ outfits

OUTFITS = {
    #            cloth      trim       inner      extras
    "peasant":  ("#8a6a45", "#5f4630", "#e9dcc0", "patch"),
    "beggar":   ("#6f6a60", "#4c4840", None,      "rags"),
    "merchant": ("#2f7d6d", "#d3a94a", "#f1ead8", "coins"),
    "scholar":  ("#dfe5ea", "#2c3e5a", "#ffffff", "plain"),
    "noble":    ("#5a2d73", "#d8b04c", "#f3e9f7", "gold"),
    "martial":  ("#27344f", "#a7332e", "#d9d4c8", "guard"),
    "wanderer": ("#4a5a4c", "#2f3a31", "#cdbf9f", "scarf"),
    "disciple": ("#5f7fa3", "#eef1f4", "#ffffff", "plain"),
    "wudang":   ("#e8e8ea", "#22242c", "#ffffff", "taiji"),
    "shaolin":  ("#d98a2b", "#8c3b22", "#f1d9a0", "beads"),
    "huashan":  ("#f1eef0", "#c2527a", "#ffffff", "plum"),
    "cult":     ("#231d28", "#b5282c", "#3a0d12", "cult"),
}


def draw_outfit(name, stage):
    g = geo(stage, "female")
    cloth_c, trim_c, inner_c, extra = OUTFITS[name]
    cloth, trim = ramp(cloth_c), ramp(trim_c)
    sy, sw, nk = g["sh_y"], g["sh_w"], g["neck"]
    img = canvas()
    torso = smooth(poly([(CX - nk * 1.7, sy - 0.012), (CX + nk * 1.7, sy - 0.012), (CX + sw, sy + 0.070), (CX + sw + 0.05, 1.02),
                         (CX - sw - 0.05, 1.02), (CX - sw, sy + 0.070)]), 0.016)
    vee = poly([(CX - nk * 1.20, sy - 0.03), (CX + nk * 1.20, sy - 0.03), (CX + 0.004, sy + 0.150)])
    part(img, torso, cloth, depth=0.045, light=0.016)
    for k in (-0.72, -0.40, 0.45, 0.78):                                                         # cloth folds
        paint(img, line([(CX + sw * k, sy + 0.09), (CX + sw * k * 1.10, 1.0)], 0.005) & torso, cloth[2])
    if inner_c:
        inner = ramp(inner_c)
        part(img, poly([(CX - nk * 1.55, sy - 0.03), (CX + nk * 1.55, sy - 0.03), (CX + 0.004, sy + 0.200)]) & torso, inner, depth=0.010, light=0.004)
    img[vee] = 0                                                                                 # the open collar shows the skin layer
    band = 0.034 if name != "wudang" else 0.044
    under = line([(CX - nk * 1.50, sy - 0.020), (CX + 0.004, sy + 0.150)], band)
    over = line([(CX + nk * 1.50, sy - 0.020), (CX - 0.010, sy + 0.165), (CX - 0.090, sy + 0.330)], band)
    part(img, under & ~vee, trim, depth=0.010, light=0.005)
    part(img, over & ~poly([(CX - nk * 0.9, sy - 0.03), (CX + nk * 0.9, sy - 0.03), (CX, sy + 0.10)]), trim, depth=0.010, light=0.005)

    def dots(points, col, r=0.006):
        for x, y in points:
            paint(img, ell(x, y, r, r) & torso, col)

    if extra == "patch":
        p = poly([(CX + sw * 0.45, sy + 0.14), (CX + sw * 0.72, sy + 0.13), (CX + sw * 0.75, sy + 0.21), (CX + sw * 0.47, sy + 0.22)]) & torso
        part(img, p, ramp("#a78a5c"), depth=0.008, light=0.004)
    elif extra == "rags":
        for x, y, c in ((-0.55, 0.14, "#8a7a5a"), (0.50, 0.19, "#565a66"), (-0.30, 0.25, "#7a5a4a")):
            p = poly([(CX + sw * x, sy + y), (CX + sw * (x + 0.26), sy + y - 0.01), (CX + sw * (x + 0.28), sy + y + 0.07), (CX + sw * (x + 0.02), sy + y + 0.08)]) & torso
            part(img, p, ramp(c), depth=0.008, light=0.004)
        for k in (-0.9, -0.5, 0.3, 0.7):                                                         # torn collar
            img[poly([(CX + nk * (k - 0.2), sy - 0.03), (CX + nk * (k + 0.2), sy - 0.03), (CX + nk * k, sy + 0.035)])] = 0
    elif extra == "coins":
        dots([(CX + sw * x, sy + y) for x in (-0.75, -0.45, 0.50, 0.80) for y in (0.14, 0.21, 0.28)], trim[1])
    elif extra == "gold":
        for s in (-1, 1):
            arc = ell(CX + s * sw * 0.72, sy + 0.10, 0.060, 0.045) & ~ell(CX + s * sw * 0.72, sy + 0.115, 0.060, 0.045) & torso
            paint(img, arc, trim[1])
            dots([(CX + s * sw * x, sy + y) for x, y in ((0.50, 0.20), (0.66, 0.24), (0.82, 0.20), (0.58, 0.29), (0.76, 0.30))], trim[0], 0.005)
        part(img, ell(CX - 0.012, sy + 0.215, 0.016, 0.022), ramp("#5fa88f"), depth=0.006, light=0.004)   # jade clasp
    elif extra == "guard":
        pad = smooth(ell(CX + sw * 0.80, sy + 0.085, 0.085, 0.055) & (YY / GRID < sy + 0.13), 0.004)
        part(img, pad, ramp("#6b4a2c"), depth=0.014, light=0.008)
        dots([(CX + sw * 0.80 + dx, sy + 0.085) for dx in (-0.05, -0.02, 0.01, 0.04)], hexc("#d8c9a0"), 0.005)
    elif extra == "scarf":
        wrap = smooth(ell(CX, sy + 0.020, nk * 2.5, 0.052), 0.004)
        part(img, wrap, ramp("#b9a27a"), depth=0.016, light=0.008)
        for k in (-1.4, -0.5, 0.5, 1.4):
            paint(img, line([(CX + nk * k, sy - 0.02), (CX + nk * (k + 0.4), sy + 0.06)], 0.004) & wrap, ramp("#b9a27a")[3])
        part(img, poly([(CX + nk * 1.2, sy + 0.05), (CX + nk * 2.2, sy + 0.05), (CX + nk * 2.5, sy + 0.24), (CX + nk * 1.3, sy + 0.26)]), ramp("#b9a27a"), depth=0.012)
    elif extra == "taiji":
        x, y, r = CX + sw * 0.52, sy + 0.185, 0.034
        disc = ell(x, y, r, r) & torso
        paint(img, disc, hexc("#f4f4f6"))
        paint(img, disc & (XX / GRID > x), trim[1])
        paint(img, ell(x, y - r / 2, r / 2, r / 2), trim[1])
        paint(img, ell(x, y + r / 2, r / 2, r / 2), hexc("#f4f4f6"))
        paint(img, ell(x, y - r / 2, r / 7, r / 7), hexc("#f4f4f6"))
        paint(img, ell(x, y + r / 2, r / 7, r / 7), trim[1])
        paint(img, disc & ~erode(disc, max(1, GRID // 128)), trim[4])
    elif extra == "beads":
        sash = poly([(CX - sw * 1.0, sy + 0.06), (CX - sw * 0.55, sy + 0.02), (CX + sw * 0.55, 1.0), (CX - sw * 0.10, 1.0)]) & torso
        part(img, sash, trim, depth=0.02)
        bead = ramp("#4a2c1c")
        for i in range(13):
            a = np.pi * i / 12
            part(img, ell(CX - np.cos(a) * nk * 2.1, sy + 0.02 + np.sin(a) * 0.17, 0.013, 0.013), bead, depth=0.005, light=0.004)
    elif extra == "plum":
        for fx, fy in ((sw * 0.62, 0.15), (-sw * 0.70, 0.22), (sw * 0.40, 0.27)):
            for a in range(5):
                paint(img, ell(CX + fx + np.cos(a * 1.2566) * 0.014, sy + fy + np.sin(a * 1.2566) * 0.014, 0.009, 0.009) & torso, trim[1])
            paint(img, ell(CX + fx, sy + fy, 0.006, 0.006) & torso, hexc("#f2d36b"))
    elif extra == "cult":
        for s in (-1, 1):                                                                        # high pointed collar
            wing = poly([(CX + s * nk * 1.2, sy + 0.02), (CX + s * nk * 2.9, sy + 0.03), (CX + s * nk * 2.5, sy - 0.10)])
            part(img, wing, cloth, depth=0.012, light=0.006)
            paint(img, line([(CX + s * nk * 1.3, sy + 0.015), (CX + s * nk * 2.5, sy - 0.095)], 0.008), trim[1])
        dots([(CX + sw * x, sy + 0.16 + abs(x) * 0.05) for x in (-0.7, -0.5, 0.5, 0.7)], trim[1], 0.008)
    return img


# ------------------------------------------------------------ backdrop and frame

BACKDROPS = {"plain": "#33414a", "wudang": "#3f5d7a", "shaolin": "#7d5c2c", "huashan": "#7d4560", "cult": "#4c1a1f"}


def draw_backdrop(name):
    pal = ramp(BACKDROPS[name], "#0b1114", "#ffe9c4")
    img = canvas()
    paint(img, DISC, pal[1])
    paint(img, DISC & (YY / GRID < 0.42), pal[0], dither=True)                                   # lighter sky
    paint(img, DISC & (YY / GRID < 0.26), pal[0])
    paint(img, ell(0.70, 0.22, 0.085, 0.085), mix(pal[0], hexc("#fff4d8"), 0.55))                # sun or moon
    far = poly([(0.0, 0.62), (0.16, 0.44), (0.30, 0.58), (0.44, 0.40), (0.60, 0.56), (0.80, 0.36), (1.0, 0.60), (1.0, 1.0), (0.0, 1.0)])
    paint(img, far & DISC, pal[2])
    paint(img, far & DISC & ~shift(far, 0, max(2, GRID // 40)), pal[1], dither=True)             # mist on the ridge
    near = poly([(0.0, 0.80), (0.20, 0.64), (0.40, 0.78), (0.62, 0.66), (0.86, 0.80), (1.0, 0.72), (1.0, 1.0), (0.0, 1.0)])
    paint(img, near & DISC, pal[3])
    return img


def draw_frame():
    img = canvas()
    t = max(2, GRID // 64)
    ring = DISC & ~erode(DISC, t)
    gold = ramp("#c9a961")
    paint(img, ring, gold[1])
    paint(img, ring & ~shift(ring, 1, 1), gold[0])
    paint(img, ring & ~shift(ring, -1, -1), gold[3])
    return img


# ------------------------------------------------------------ build everything

def main():
    for folder in (DEST, MASTERS):
        os.makedirs(folder, exist_ok=True)
        for f in os.listdir(folder):
            if f.endswith(".png"):
                os.remove(os.path.join(folder, f))
    open(os.path.join(MASTERS, ".gdignore"), "w").close()      # keeps the masters out of the game build
    count = 0
    for name in BACKDROPS:
        save(draw_backdrop(name), "bg_" + name); count += 1
    save(draw_frame(), "frame"); count += 1
    for gender in STYLES:
        for stage in STAGES:
            for skin in range(len(SKINS)):
                save(draw_body(gender, stage, skin), f"body_{gender}_{stage}_{skin}"); count += 1
            for style in STYLES[gender]:
                for colour in STAGE_HAIR[stage]:
                    back, front = draw_hair(gender, stage, style, colour)
                    save(back, f"hairb_{gender}_{stage}_{style}_{colour}")
                    save(front, f"hairf_{gender}_{stage}_{style}_{colour}"); count += 2
    for stage in ("adult", "elder"):
        for colour in STAGE_HAIR[stage]:
            save(draw_beard(stage, colour), f"beard_{stage}_{colour}"); count += 1
    for name in OUTFITS:
        for stage in ("child", "teen", "adult"):
            save(draw_outfit(name, stage), f"outfit_{name}_{stage}"); count += 1
    print(f"{count} layers drawn on a {GRID}x{GRID} grid: {OUT}px masters and {GAME}px game copies")


if __name__ == "__main__":
    main()
