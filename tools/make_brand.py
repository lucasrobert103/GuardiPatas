"""Logo da RetroNexa redesenhado em alta resolução + fontes Inter recortadas para a abertura.

Uso: python3 tools/make_brand.py  (precisa de Pillow e fonttools; usa a Inter do sistema)
Gera:
  assets/brand/retronexa_logo.png      1024×1024, fundo índigo, palavra branca (fiel ao original)
  assets/brand/retronexa_logo_site.png 1024×1024, com retronexa.com.br embaixo
  assets/fonts/Inter-Bold.otf / Inter-Medium.otf  só com os caracteres latinos (~30 KB)
"""
import os
from PIL import Image, ImageDraw, ImageFont
from fontTools import subset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYS = "/usr/share/fonts/opentype/inter"
INDIGO = (78, 69, 220)
WHITE = (255, 255, 255)
BRAND = "RetroNexa"
SITE = "retronexa.com.br"
TRACKING = 0.0  # em, igual ao usado em src/ui/splash_screen.gd


def subset_font(name):
    out = os.path.join(ROOT, "assets/fonts", name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    opts = subset.Options()
    opts.layout_features = ["kern", "liga"]
    font = subset.load_font(os.path.join(SYS, name), opts)
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=list(range(0x20, 0x7F)) + list(range(0xA0, 0x100)))
    sub.subset(font)
    subset.save_font(font, out, opts)
    return out


def logo(with_site, path, size=1024, scale=4):
    S = size * scale
    im = Image.new("RGB", (S, S), INDIGO)
    d = ImageDraw.Draw(im)
    fs = int(S * 0.136)
    bold = ImageFont.truetype(os.path.join(SYS, "Inter-Bold.otf"), fs)
    track = -TRACKING * fs  # letras um pouco mais juntas, como no logo original
    box = d.textbbox((0, 0), BRAND, font=bold)
    tw = bold.getlength(BRAND) + track * (len(BRAND) - 1)
    th = box[3] - box[1]
    cy = S * (0.47 if with_site else 0.5)
    x0 = (S - tw) / 2
    for i, ch in enumerate(BRAND):
        x = x0 + bold.getlength(BRAND[:i]) + track * i
        d.text((x, cy - th / 2 - box[1]), ch, font=bold, fill=WHITE)
    if with_site:
        med = ImageFont.truetype(os.path.join(SYS, "Inter-Medium.otf"), int(S * 0.052))
        b2 = d.textbbox((0, 0), SITE, font=med)
        d.text(((S - (b2[2] - b2[0])) / 2 - b2[0], cy + th / 2 + S * 0.07 - b2[1]), SITE, font=med, fill=(225, 223, 255))
    im.resize((size, size), Image.LANCZOS).save(path, optimize=True)


if __name__ == "__main__":
    for f in ("Inter-Bold.otf", "Inter-Medium.otf"):
        print(subset_font(f), os.path.getsize(os.path.join(ROOT, "assets/fonts", f)), "bytes")
    os.makedirs(os.path.join(ROOT, "assets/brand"), exist_ok=True)
    logo(False, os.path.join(ROOT, "assets/brand/retronexa_logo.png"))
    logo(True, os.path.join(ROOT, "assets/brand/retronexa_logo_site.png"))
    print("logos ok")
