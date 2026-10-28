#!/usr/bin/env python3
"""Gera data/levels.json — a campanha do GuardiPatas descrita como código.

Por que um gerador? As fases são DADOS (o jogo só lê o JSON), mas escrever as
coordenadas com funções auxiliares (chão, abrigo em arco, parede em tenda...) evita
erros e deixa claro *por que* cada solução funciona. Designers podem editar o JSON
direto ou ajustar aqui e rodar:

    python3 tools/make_levels.py

Cada fase traz `solution`: uma lista de traços que DEVE vencer a fase. O teste
automatizado (tests/test_levels.gd) desenha essa solução pela mesma validação do
dedo, roda a física e exige vitória; e exige DERROTA sem nenhuma linha (fase não
trivial). Convenções: tela de projeto 720x1280 (retrato), y cresce para baixo.
"""
import json
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "levels.json")

GROUND = 1000
# metade da altura de cada espécie (casa com Animal.SPECIES)
HALF_H = {"capi": 30, "brasa": 46, "pingo": 28, "lulu": 18, "tuca": 24, "nino": 22}
HALF_W = {"capi": 56, "brasa": 26, "pingo": 28, "lulu": 37, "tuca": 46, "nino": 22}


def ground(y=GROUND, x0=-400, x1=1120):
    return {"poly": [[x0, y], [x1, y], [x1, 1800], [x0, 1800]], "style": "ground"}


def block(x0, y0, x1, y1, style="ground"):
    return {"poly": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "style": style}


def animal(kind, x, floor=GROUND, flip=False):
    return {"type": kind, "pos": [x, floor - HALF_H[kind] - 1], "flip": flip}


def hive(x, y, insect="bee", count=6, interval=0.35, delay=0.3):
    return {"insect": insect, "pos": [x, y], "count": count, "interval": interval, "delay": delay}


def mound(x, insect="ant", count=6, interval=0.6, delay=0.2, floor=GROUND):
    # a base do montinho fica 20 px abaixo do centro
    return {"insect": insect, "pos": [x, floor - 20], "count": count, "interval": interval, "delay": delay}


def dome(cx, half_w, top, floor=GROUND, pad=22, apex_gap=30, steps=14):
    """Arco (abrigo) que cobre um bichinho: pernas até perto do chão + semicírculo.

    O traço começa 12 px acima do chão (a validação exige folga), cai alguns pixels
    e pousa nas duas pernas — um arco é estável, não tomba com empurrões leves.
    """
    hw = half_w + pad
    y_leg = floor - 12
    y_top = top - apex_gap
    ry = max(min(hw, (y_leg - y_top) * 0.75), 20)
    y_c = y_top + ry
    pts = [[cx - hw, y_leg]]
    if y_c < y_leg - 4:
        pts.append([cx - hw, round(y_c)])
    for i in range(1, steps):
        a = math.pi + math.pi * i / steps
        pts.append([round(cx + math.cos(a) * hw), round(y_c + math.sin(a) * ry)])
    if y_c < y_leg - 4:
        pts.append([cx + hw, round(y_c)])
    pts.append([cx + hw, y_leg])
    return pts


def dome_over(kind, x, floor=GROUND, **kw):
    top = floor - 1 - 2 * HALF_H[kind]
    return dome(x, HALF_W[kind], top, floor, **kw)


def tent(x, height=110, half_w=55, floor=GROUND):
    """Parede em "Λ": fica em pé sozinha e é íngreme demais para formigas."""
    y = floor - 12
    return [[x - half_w, y], [x - half_w * 0.5, y - height * 0.55], [x, y - height], [x + half_w * 0.5, y - height * 0.55], [x + half_w, y]]


WORLDS = [
    {"id": 1, "name": "Jardim dos Bichinhos"},
    {"id": 2, "name": "Floresta Encantada"},
    {"id": 3, "name": "Vale das Formigas"},
    {"id": 4, "name": "Lagoa Misteriosa"},
    {"id": 5, "name": "Acampamento no Quintal"},
]


def L(id_, world, name, tip, animals, nests, solution, ink=900, survive=8, stars=(0.45, 0.7), strokes=1,
      terrain=None, props=None, rocks=None, nodraw=None, teaches=""):
    return {
        "id": id_, "world": world, "name": name, "tip": tip, "teaches": teaches,
        "ink": ink, "survive": survive, "stars": list(stars), "strokes": strokes,
        "terrain": terrain if terrain is not None else [ground()],
        "rocks": rocks or [], "props": props or [], "nodraw": nodraw or [],
        "animals": animals, "nests": nests, "solution": solution,
    }


def campaign():
    lv = []
    # ------------------------------------------------------------ Mundo 1
    lv.append(L("1-1", 1, "Oi, Capitu!",
                "Desenhe um abrigo sobre a Capitu. Os insetos saem quando você solta o dedo!",
                [animal("capi", 360)], [hive(600, 360, count=5)],
                [dome_over("capi", 360)], ink=900, survive=6, stars=(0.5, 0.75),
                teaches="Desenhar, soltar e a linha cair com peso."))
    lv.append(L("1-2", 1, "Zumbido em Dobro",
                "Abelhas dos dois lados! Um abrigo fechado protege de todas as direções.",
                [animal("capi", 360)], [hive(120, 380, count=4), hive(600, 380, count=4, delay=0.8)],
                [dome_over("capi", 360)], ink=850, survive=8, stars=(0.5, 0.75),
                teaches="Ameaças de várias direções."))
    lv.append(L("1-3", 1, "Brasa, a Curiosa",
                "A Brasa tem orelhas altas: capriche na altura do abrigo!",
                [animal("brasa", 380)], [hive(130, 340, count=6)],
                [dome_over("brasa", 380)], ink=850, survive=8, stars=(0.5, 0.75),
                teaches="Bichinhos têm tamanhos diferentes."))
    lv.append(L("1-4", 1, "Fila de Formigas",
                "Formigas andam pelo chão e sobem degraus baixos, mas não paredes íngremes.",
                [animal("capi", 520)], [mound(110, count=6, interval=0.7)],
                [tent(320)], ink=600, survive=10, stars=(0.45, 0.7),
                teaches="Inseto andarilho; parede em vez de teto."))
    lv.append(L("1-5", 1, "Bolinha de Espinhos",
                "O Pingo é tímido. Abelhas e formigas querem um abraço... não deixe!",
                [animal("pingo", 400)], [hive(620, 360, count=4), mound(90, count=4, interval=0.8)],
                [dome_over("pingo", 400)], ink=800, survive=9, stars=(0.45, 0.7),
                teaches="Dois tipos de inseto ao mesmo tempo."))
    lv.append(L("1-6", 1, "Lá no Alto",
                "O Nino mora no galho. O abrigo precisa caber em cima dele!",
                [animal("nino", 360, floor=720)], [hive(610, 330, count=6)],
                [dome_over("nino", 360, floor=720)], ink=700, survive=8, stars=(0.45, 0.7),
                terrain=[ground(), block(230, 720, 490, 760, "wood")],
                teaches="Precisão: a linha tem que pousar numa plataforma estreita."))
    # ------------------------------------------------------------ Mundo 2
    lv.append(L("2-1", 2, "Zizi, o Mosquito",
                "Mosquitos passam por qualquer fresta. Feche bem o abrigo!",
                [animal("capi", 360)], [hive(580, 340, insect="mosquito", count=7, interval=0.3)],
                [dome_over("capi", 360)], ink=900, survive=8, stars=(0.5, 0.75),
                teaches="Inseto pequeno que procura brechas."))
    lv.append(L("2-2", 2, "Luz da Lanterna",
                "As mariposas amam a luz. Quando a lanterna apagar, elas vêm atrás da Brasa!",
                [animal("brasa", 470)], [hive(620, 330, insect="moth", count=5, interval=0.4)],
                [dome_over("brasa", 470)], ink=850, survive=10, stars=(0.5, 0.75),
                props=[{"type": "lamp", "pos": [170, 620], "duration": 4}],
                teaches="Atração por luz e tempo visível."))
    lv.append(L("2-3", 2, "Dois Amigos",
                "Capitu e Nino são inseparáveis. Um abrigo grande para os dois!",
                [animal("capi", 300), animal("nino", 430)], [hive(620, 340, count=7)],
                [dome(352, 126, 1000 - 61 - 4)], ink=1100, survive=8, stars=(0.5, 0.75),
                teaches="Vários bichinhos."))
    lv.append(L("2-4", 2, "Caixa Amiga",
                "Use a caixa como parede: assim você gasta menos tinta!",
                [animal("capi", 330)], [hive(620, 360, count=6)],
                [dome_over("capi", 330)], ink=850, survive=8, stars=(0.42, 0.7),
                props=[{"type": "crate", "pos": [490, 960], "size": [80, 80]}],
                teaches="Objetos físicos ajudam (e economizam tinta)."))
    lv.append(L("2-5", 2, "Duas Linhas",
                "Aqui você tem DOIS traços. Depois do primeiro, toque em Pronto ou desenhe o segundo.",
                [animal("capi", 180), animal("pingo", 560)], [hive(360, 330, count=8, interval=0.3)],
                [dome_over("capi", 180), dome_over("pingo", 560)], ink=1200, survive=9, stars=(0.5, 0.75), strokes=2,
                rocks=[{"pos": [370, 1000], "r": 46}],
                teaches="Mais de um traço."))
    lv.append(L("2-6", 2, "Zona Proibida",
                "Não dá para desenhar na área listrada. Faça um abrigo baixinho!",
                [animal("brasa", 360)], [hive(130, 330, count=4), hive(600, 330, count=4, delay=0.6)],
                [dome_over("brasa", 360, apex_gap=24)], ink=850, survive=9, stars=(0.5, 0.75),
                nodraw=[[230, 640, 260, 210]],
                teaches="Espaço limitado para desenhar."))
    return lv


if __name__ == "__main__":
    levels = campaign()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "worlds": WORLDS, "levels": levels}, f, ensure_ascii=False, indent=1)
    print(f"{len(levels)} fases gravadas em {os.path.relpath(OUT)}")
