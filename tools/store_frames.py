#!/usr/bin/env python3
"""Monta as capturas da Play Store (1080×1920) com legenda, a partir das capturas reais do jogo.

    python3 tools/store_frames.py PASTA_DAS_CAPTURAS   # PASTA/pt_BR, PASTA/en, PASTA/es
Saída: store/screenshots/<idioma>/01.png ... 07.png
As capturas vêm de tests/screenshots.tscn com --resolution 1080x1920 (ver docs/15).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = "/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf"
W, H = 1080, 1920
SHOTS = [
    ("fase_1-1_hint", ("Desenhe para proteger os bichinhos!", "Draw to protect the critters!", "¡Dibuja para proteger a los animalitos!"), "#4aa3ff"),
    ("fase_7-4_solve_2.5", ("8 mundos e 63 fases de estratégia", "8 worlds and 63 strategy levels", "8 mundos y 63 niveles de estrategia"), "#ff8a3d"),
    ("fase_6-11_solve_1.6", ("Chefões fofos, nada de violência", "Cute bosses, zero violence", "Jefes tiernos, cero violencia"), "#7a8fd6"),
    ("fase_8-11_solve_3.0", ("Física de verdade: a linha tem peso", "Real physics: every line has weight", "Física real: la línea tiene peso"), "#1f7aa8"),
    ("05_desafio", ("Um desafio novo todo dia", "A new challenge every day", "Un desafío nuevo cada día"), "#ffb340"),
    ("09_editor", ("Crie as suas próprias fases", "Create your own levels", "Crea tus propios niveles"), "#9b6fe0"),
    ("06_casinha", ("14 bichinhos para cuidar", "14 critters to care for", "14 animalitos para cuidar"), "#5cc46a"),
]
LANGS = [("pt_BR", 0, "pt"), ("en", 1, "en"), ("es", 2, "es")]


def wrap(draw, text, font, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=font) <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def frame(src, caption, color):
    bg = Image.new("RGB", (W, H), color)
    # degradê suave de cima para baixo
    top = Image.new("RGB", (W, H), "#ffffff")
    mask = Image.linear_gradient("L").resize((W, H)).point(lambda v: int((255 - v) * 0.22))
    bg = Image.composite(top, bg, mask)
    d = ImageDraw.Draw(bg)
    font = ImageFont.truetype(FONT, 76)
    lines = wrap(d, caption, font, W - 120)
    y = 70
    for ln in lines:
        tw = d.textlength(ln, font=font)
        d.text(((W - tw) / 2, y), ln, font=font, fill="white", stroke_width=8, stroke_fill="#3a2b3c")
        y += 96
    shot = Image.open(src).convert("RGB")
    sw = int(W * 0.80)
    sh = int(shot.height * sw / shot.width)
    avail = H - y - 60
    if sh > avail:
        sh = avail
        sw = int(shot.width * sh / shot.height)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    x0, y0 = (W - sw) // 2, y + 30
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((x0 + 10, y0 + 18, x0 + sw + 10, y0 + sh + 18), 46, fill=110)
    bg.paste(Image.new("RGB", (W, H), "#2a1f2c"), (0, 0), shadow.filter(ImageFilter.GaussianBlur(18)))
    m = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw - 1, sh - 1), 40, fill=255)
    border = Image.new("RGB", (sw + 16, sh + 16), "#3a2b3c")
    bm = Image.new("L", (sw + 16, sh + 16), 0)
    ImageDraw.Draw(bm).rounded_rectangle((0, 0, sw + 15, sh + 15), 48, fill=255)
    bg.paste(border, (x0 - 8, y0 - 8), bm)
    bg.paste(shot, (x0, y0), m)
    return bg


def main(base):
    for lang, idx, short in LANGS:
        out = os.path.join(ROOT, "store", "screenshots", short)
        os.makedirs(out, exist_ok=True)
        for i, (name, caps, color) in enumerate(SHOTS):
            src = os.path.join(base, lang, name + ".png")
            frame(src, caps[idx], color).save(os.path.join(out, "%02d.png" % (i + 1)), optimize=True)
        print("capturas", short, "ok")


if __name__ == "__main__":
    main(sys.argv[1])
