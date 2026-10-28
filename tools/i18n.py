#!/usr/bin/env python3
"""Idiomas do GuardiPatas (português é o texto-fonte; inglês e espanhol traduzidos).

    python3 tools/i18n.py extract   # lista os textos que aparecem na tela -> data/i18n/source.txt
    python3 tools/i18n.py build     # gera data/i18n/translations.csv (o Godot importa sozinho)
    python3 tools/i18n.py check     # mostra textos ainda sem tradução

As traduções ficam em tools/i18n_table.py (PT -> (EN, ES)). Chave = o texto em português,
então qualquer Label/Button com esse texto exato é traduzido automaticamente pelo Godot;
textos montados com % usam tr() antes da formatação.
"""
import csv, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIRS = ["src/ui", "src/core", "src/autoload", "src/game"]
OUT_DIR = os.path.join(ROOT, "data", "i18n")
# literais que parecem texto de tela: têm letra minúscula + espaço/pontuação/acento, ou começam com maiúscula
STR_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
SKIP_RE = re.compile(r'^(res://|user://|[a-z0-9_]+$|[a-z_]+/[a-z_/]+$|%[^ ]*$|#|[A-Z_0-9]+$)')
SKIP_FILES = {"src/core/layers.gd"}
# textos que não são traduzidos: nomes próprios, marcas, chaves internas e formatos sem palavras
IGNORE = {"%s · %s", "%s  %s", "%s %s", "%d / %d", "     Tempo %ds", "     Tinta: %s", "     Traços: %d", ": sim", ": não",
          "%d %s seguido%s!", "[x]  ", "modulate:a", "RetroNexa", "retronexa.com.br", "GuardiPatas", "RetroNexa · retronexa.com.br",
          "Label", "Button", "PanelContainer", "T12:00:00", "levels.json não encontrado", "levels.json inválido", ".wav",
          "Music", "Master", "World", "Fx", "Capitu", "Brasa", "Pingo", "Lulu", "Tuca", "Nino", "Gelinho", "Tatá", "Pompom",
          "Nuvem", "Fofa", "Tito", "Patinha", "Kiko", "Português", "English", "Español", "%s: %s"}


def looks_like_text(s):
    if len(s) < 2 or SKIP_RE.match(s):
        return False
    if re.fullmatch(r"[0-9a-fA-F]{6}", s):
        return False
    if not re.search(r"[A-Za-zÀ-ú]", s):
        return False
    return bool(re.search(r"[ À-ú!?.:]", s) or re.match(r"[A-ZÀ-Ú][a-zà-ú]", s))


def code_strings():
    out = []
    for d in SRC_DIRS:
        for dp, _, files in os.walk(os.path.join(ROOT, d)):
            for f in sorted(files):
                if not f.endswith(".gd"):
                    continue
                rel = os.path.relpath(os.path.join(dp, f), ROOT)
                if rel in SKIP_FILES:
                    continue
                for line in open(os.path.join(dp, f), encoding="utf-8"):
                    code = line.split("##")[0]
                    if code.strip().startswith("#"):
                        continue
                    if "print(" in code or "push_warning" in code or "get_setting" in code or "ProjectSettings" in code:
                        continue
                    for m in STR_RE.finditer(code):
                        s = m.group(1).encode().decode("unicode_escape").encode("latin1").decode("utf-8")
                        if looks_like_text(s):
                            out.append(s)
    return out


def data_strings():
    d = json.load(open(os.path.join(ROOT, "data", "levels.json"), encoding="utf-8"))
    out = [w["name"] for w in d["worlds"]]
    for lv in d["levels"]:
        out += [lv["name"], lv["tip"]]
    return out


def unique(seq):
    seen, res = set(), []
    for s in seq:
        if s not in seen:
            seen.add(s)
            res.append(s)
    return res


def extract():
    items = unique(data_strings() + code_strings())
    with open(os.path.join(OUT_DIR, "source.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(items) + "\n")
    print(f"{len(items)} textos em data/i18n/source.txt")
    return items


def table():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from i18n_table import T
    return T


def build():
    T = table()
    with open(os.path.join(OUT_DIR, "translations.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["keys", "pt_BR", "en", "es"])
        for pt, (en, es) in T.items():
            w.writerow([pt, pt, en, es])
    print(f"{len(T)} traduções em data/i18n/translations.csv")


def check():
    T = table()
    items = extract()
    missing = [s for s in items if s not in T and s not in IGNORE]
    for s in missing:
        print("SEM TRADUÇÃO:", repr(s))
    for pt, (en, es) in T.items():
        for name, tr in (("en", en), ("es", es)):
            if pt.count("%") != tr.count("%"):
                print(f"FORMATO DIFERENTE ({name}): {pt!r} -> {tr!r}")
    print(f"{len(missing)} sem tradução de {len(items)}")
    return len(missing)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    {"extract": extract, "build": build, "check": check}[cmd]()
