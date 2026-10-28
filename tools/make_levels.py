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


def dome_general(cx, half_w, top, y_left, y_right, pad=22, apex_gap=30, steps=14):
    """Arco com pernas em alturas diferentes (terreno inclinado). y_left/right = superfície."""
    hw = half_w + pad
    yl, yr = y_left - 12, y_right - 12
    y_top = top - apex_gap
    ry = max(min(hw, (min(yl, yr) - y_top) * 0.75), 20)
    y_c = y_top + ry
    pts = [[round(cx - hw), round(yl)]]
    if y_c < yl - 4:
        pts.append([round(cx - hw), round(y_c)])
    for i in range(1, steps):
        a = math.pi + math.pi * i / steps
        pts.append([round(cx + math.cos(a) * hw), round(y_c + math.sin(a) * ry)])
    if y_c < yr - 4:
        pts.append([round(cx + hw), round(y_c)])
    pts.append([round(cx + hw), round(yr)])
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


def stroke_len(stroke):
    return sum(math.dist(stroke[i], stroke[i + 1]) for i in range(len(stroke) - 1))


INK_RATIO = 0.55      # a solução registrada usa ~55 % da tinta
DEFAULT_STARS = (0.6, 0.8)


def L(id_, world, name, tip, animals, nests, solution, ink=None, survive=8, stars=DEFAULT_STARS, strokes=1,
      terrain=None, props=None, rocks=None, nodraw=None, teaches="", bosses=None):
    if ink is None:
        ink = int(round(sum(stroke_len(st) for st in solution) / INK_RATIO / 10.0) * 10)
    return {
        "id": id_, "world": world, "name": name, "tip": tip, "teaches": teaches,
        "ink": ink, "survive": survive, "stars": list(stars), "strokes": strokes,
        "terrain": terrain if terrain is not None else [ground()],
        "rocks": rocks or [], "props": props or [], "nodraw": nodraw or [],
        "animals": animals, "nests": nests, "bosses": bosses or [], "solution": solution,
    }


def campaign():
    lv = []
    # ------------------------------------------------------------ Mundo 1
    lv.append(L("1-1", 1, "Oi, Capitu!",
                "Desenhe um abrigo sobre a Capitu. Os insetos saem quando você solta o dedo!",
                [animal("capi", 360)], [hive(600, 360, count=5)],
                [dome_over("capi", 360)], survive=6,
                teaches="Desenhar, soltar e a linha cair com peso."))
    lv.append(L("1-2", 1, "Zumbido em Dobro",
                "Abelhas dos dois lados! Um abrigo fechado protege de todas as direções.",
                [animal("capi", 360)], [hive(120, 380, count=4), hive(600, 380, count=4, delay=0.8)],
                [dome_over("capi", 360)], survive=8,
                teaches="Ameaças de várias direções."))
    lv.append(L("1-3", 1, "Brasa, a Curiosa",
                "A Brasa tem orelhas altas: capriche na altura do abrigo!",
                [animal("brasa", 380)], [hive(130, 340, count=6)],
                [dome_over("brasa", 380)], survive=8,
                teaches="Bichinhos têm tamanhos diferentes."))
    lv.append(L("1-4", 1, "Fila de Formigas",
                "Formigas andam pelo chão e sobem degraus baixos, mas não paredes íngremes.",
                [animal("capi", 520)], [mound(110, count=6, interval=0.7)],
                [tent(320)], survive=10,
                teaches="Inseto andarilho; parede em vez de teto."))
    lv.append(L("1-5", 1, "Bolinha de Espinhos",
                "O Pingo é tímido. Abelhas e formigas querem um abraço... não deixe!",
                [animal("pingo", 400)], [hive(620, 360, count=4), mound(90, count=4, interval=0.8)],
                [dome_over("pingo", 400)], survive=9,
                teaches="Dois tipos de inseto ao mesmo tempo."))
    lv.append(L("1-6", 1, "Lá no Alto",
                "O Nino mora no galho. O abrigo precisa caber em cima dele!",
                [animal("nino", 360, floor=720)], [hive(610, 330, count=6)],
                [dome_over("nino", 360, floor=720)], survive=8,
                terrain=[ground(), block(230, 720, 490, 760, "wood")],
                teaches="Precisão: a linha tem que pousar numa plataforma estreita."))
    # ------------------------------------------------------------ Mundo 2
    lv.append(L("2-1", 2, "Zizi, o Mosquito",
                "Mosquitos passam por qualquer fresta. Feche bem o abrigo!",
                [animal("capi", 360)], [hive(580, 340, insect="mosquito", count=7, interval=0.3)],
                [dome_over("capi", 360)], survive=8,
                teaches="Inseto pequeno que procura brechas."))
    lv.append(L("2-2", 2, "Luz da Lanterna",
                "As mariposas amam a luz. Quando a lanterna apagar, elas vêm atrás da Brasa!",
                [animal("brasa", 470)], [hive(620, 330, insect="moth", count=5, interval=0.4)],
                [dome_over("brasa", 470)], survive=10,
                props=[{"type": "lamp", "pos": [170, 620], "duration": 4}],
                teaches="Atração por luz e tempo visível."))
    lv.append(L("2-3", 2, "Dois Amigos",
                "Capitu e Nino são inseparáveis. Um abrigo grande para os dois!",
                [animal("capi", 300), animal("nino", 430)], [hive(620, 340, count=7)],
                [dome(352, 126, 1000 - 61 - 4)], survive=8,
                teaches="Vários bichinhos."))
    lv.append(L("2-4", 2, "Caixa Amiga",
                "Use a caixa como parede: assim você gasta menos tinta!",
                [animal("capi", 330)], [hive(620, 360, count=6)],
                [dome_over("capi", 330)], survive=8,
                props=[{"type": "crate", "pos": [490, 960], "size": [80, 80]}],
                teaches="Objetos físicos ajudam (e economizam tinta)."))
    lv.append(L("2-5", 2, "Duas Linhas",
                "Aqui você tem DOIS traços. Depois do primeiro, toque em Pronto ou desenhe o segundo.",
                [animal("capi", 180), animal("pingo", 560)], [hive(360, 330, count=8, interval=0.3)],
                [dome_over("capi", 180), dome_over("pingo", 560)], survive=9, strokes=2,
                rocks=[{"pos": [370, 1000], "r": 46}],
                teaches="Mais de um traço."))
    lv.append(L("2-6", 2, "Zona Proibida",
                "Não dá para desenhar na área listrada. Faça um abrigo baixinho!",
                [animal("brasa", 360)], [hive(130, 330, count=4), hive(600, 330, count=4, delay=0.6)],
                [dome_over("brasa", 360, apex_gap=24)], survive=9,
                nodraw=[[230, 640, 260, 210]],
                teaches="Espaço limitado para desenhar."))
    # ------------------------------------------------------------ Mundo 3
    lv.append(L("3-1", 3, "Bolota Teimosa",
                "Besouros empurram linhas leves! Um abrigo maior é mais pesado.",
                [animal("capi", 500)], [mound(90, insect="beetle", count=2, interval=2.5)],
                [dome_over("capi", 500, pad=30)], survive=11,
                teaches="Inseto que empurra; peso da linha."))
    gap = [ground(x0=-400, x1=300), ground(x0=420, x1=1120)]
    lv.append(L("3-2", 3, "Ponte Sobre o Nada",
                "Formigas não pulam buracos. Não faça ponte: proteja só das abelhas!",
                [animal("capi", 570)], [mound(110, count=8, interval=0.5), hive(620, 340, count=4, delay=1.0)],
                [dome_over("capi", 570)], survive=10, terrain=gap,
                teaches="Abismos param andarilhos."))
    # rampa de 15° terminando num laguinho
    slope = {"poly": [[-400, 880], [200, 880], [560, 976], [560, 1060], [760, 1060], [760, 976], [1120, 976], [1120, 1800], [-400, 1800]], "style": "ground"}
    sy = lambda x: 880 + (x - 200) * 96 / 360
    px = 337.5
    py = 914.7 - 29 * 0.966 - 0.5
    lv.append(L("3-3", 3, "Ladeira do Pingo",
                "O Pingo é redondo e ROLA! Segure ele antes que caia na água.",
                [{"type": "pingo", "pos": [px, round(py, 1)], "flip": False}], [hive(620, 340, count=5, delay=0.8)],
                [dome_general(px, 28, py - 28, sy(px - 50), sy(px + 50))], survive=9,
                terrain=[slope], props=[{"type": "water", "rect": [560, 990, 200, 70]}],
                teaches="Física do bichinho (rolar)."))
    lv.append(L("3-4", 3, "Elevador de Folha",
                "A plataforma vai descer e subir. Faça o abrigo EM CIMA dela!",
                [animal("nino", 360, floor=760)], [hive(620, 330, count=6)],
                [dome_over("nino", 360, floor=760)], survive=9,
                props=[{"type": "platform", "rect": [260, 760, 200, 24], "travel": [0, 140], "period": 4}],
                teaches="Objetos móveis."))
    lv.append(L("3-5", 3, "Roque-Roque",
                "Cupins roem madeira! Não confie só nas caixas.",
                [animal("capi", 480)], [mound(80, insect="termite", count=3, interval=0.8), mound(150, count=4, interval=0.8, delay=1.5)],
                [dome_over("capi", 480)], survive=12,
                props=[{"type": "crate", "pos": [330, 965], "size": [70, 70]}, {"type": "crate", "pos": [330, 894], "size": [70, 70]}],
                teaches="Barreiras frágeis."))
    lv.append(L("3-6", 3, "Formigueiro Gigante",
                "Formigas dos dois lados e um besouro. Hora de um abrigo caprichado!",
                [animal("capi", 360)], [mound(70, count=8, interval=0.5), mound(650, count=6, interval=0.6, delay=0.5), mound(130, insect="beetle", count=1, delay=1.0)],
                [dome_over("capi", 360, pad=30)], survive=12,
                teaches="Revisão do mundo."))
    # ------------------------------------------------------------ Mundo 4
    pond = [{"poly": [[-400, 1000], [200, 1000], [200, 1080], [520, 1080], [520, 1000], [1120, 1000], [1120, 1800], [-400, 1800]], "style": "ground"}]
    pond_water = {"type": "water", "rect": [200, 1000, 320, 80]}
    island = block(290, 980, 430, 1080, "stone")
    lv.append(L("4-1", 4, "Bolhas da Lulu",
                "Formigas não nadam: a água protege a Lulu delas. Mas e as abelhas?",
                [animal("lulu", 360, floor=980)], [mound(70, count=5, interval=0.6), mound(650, count=5, interval=0.6), hive(600, 330, count=5, delay=1.2)],
                [dome_over("lulu", 360, floor=980)], survive=10,
                terrain=pond + [island], props=[pond_water],
                teaches="Água leva os insetos embora."))
    lv.append(L("4-2", 4, "Vovó Tuca",
                "O casco da Tuca aguenta UMA picadinha. A segunda, não!",
                [animal("tuca", 380)], [hive(110, 340, count=6)],
                [dome_over("tuca", 380)], survive=9,
                teaches="Casco: uma chance extra."))
    lv.append(L("4-3", 4, "Faísca!",
                "Vespas avisam com um \"!\" e investem em linha reta. Abrigo firme no chão!",
                [animal("brasa", 430)], [hive(110, 330, insect="wasp", count=2, interval=1.5)],
                [dome_over("brasa", 430, pad=28)], survive=9,
                teaches="Investida telegrafada."))
    moat = [{"poly": [[-400, 1000], [220, 1000], [220, 1070], [380, 1070], [380, 1000], [1120, 1000], [1120, 1800], [-400, 1800]], "style": "ground"}]
    lv.append(L("4-4", 4, "Fosso Protetor",
                "O fosso cuida das formigas. Você cuida das abelhas!",
                [animal("capi", 570)], [mound(80, count=10, interval=0.4), hive(620, 330, count=5, delay=1.0)],
                [dome_over("capi", 570)], survive=10,
                terrain=moat, props=[{"type": "water", "rect": [220, 1000, 160, 70]}],
                teaches="Usar o cenário a favor."))
    lv.append(L("4-5", 4, "Lagarta Gulosa",
                "Lagartas sobem paredes! Só um abrigo fechado segura todo mundo.",
                [animal("capi", 500)], [mound(90, insect="caterpillar", count=2, interval=1.5), mound(150, count=5, interval=0.6)],
                [dome_over("capi", 500)], survive=13,
                teaches="Inseto que escala a linha."))
    lv.append(L("4-6", 4, "Ilhas Amigas",
                "Três amigos, três traços. A água ajuda: use a tinta com sabedoria!",
                [animal("brasa", 100), animal("lulu", 360, floor=980), animal("tuca", 625)],
                [hive(360, 300, insect="mosquito", count=6, interval=0.4), hive(640, 330, insect="wasp", count=1, delay=2.0)],
                [dome_over("brasa", 100), dome_over("lulu", 360, floor=980), dome_over("tuca", 625)],
                survive=10, strokes=3,
                terrain=pond + [island], props=[pond_water],
                teaches="Vários bichinhos e traços."))
    # ------------------------------------------------------------ Mundo 5
    lv.append(L("5-1", 5, "Noite de Lanternas",
                "As mariposas vão para a lanterna que ficar acesa por último. Quem está em perigo?",
                [animal("capi", 170), animal("nino", 560)], [hive(360, 330, insect="moth", count=6, interval=0.4)],
                [dome_over("nino", 560)], survive=11,
                props=[{"type": "lamp", "pos": [150, 650], "duration": 3}, {"type": "lamp", "pos": [570, 640], "duration": 7}],
                teaches="Iscas de luz e tempo."))
    lv.append(L("5-2", 5, "Fogueira de Brinquedo",
                "Caixas soltas e um besouro empurrando tudo. Proteja a Capitu!",
                [animal("capi", 360)], [mound(70, insect="beetle", count=1, delay=0.5), hive(620, 330, count=5, delay=1.0)],
                [dome_over("capi", 360, pad=26)], survive=11,
                props=[{"type": "crate", "pos": [180, 970], "size": [60, 60]}, {"type": "crate", "pos": [560, 970], "size": [60, 60]}],
                teaches="Objetos + empurrão."))
    lv.append(L("5-3", 5, "Carrossel de Tábua",
                "A tábua vai passear para os lados. O abrigo precisa ir junto!",
                [animal("brasa", 290, floor=800)], [hive(620, 330, count=6), hive(110, 330, count=3, delay=1.2)],
                [dome_over("brasa", 290, floor=800)], survive=10,
                props=[{"type": "platform", "rect": [180, 800, 220, 24], "travel": [160, 0], "period": 5}],
                teaches="Plataforma horizontal."))
    lean = [[422, 846], [386, 846], [340, 856], [290, 872], [250, 898], [222, 935], [208, 988]]
    lv.append(L("5-4", 5, "Pouca Tinta",
                "Quase nada de tinta! Aproveite o bloco de pedra como parede.",
                [animal("capi", 300)], [hive(100, 330, insect="mosquito", count=6, interval=0.35)],
                [lean], survive=9,
                terrain=[ground(), block(400, 860, 470, 1000, "stone")],
                teaches="Economia extrema; meia-água."))
    lv.append(L("5-5", 5, "Todos Juntos",
                "A turma toda acampou! Três traços: agrupe os amigos de dois em dois.",
                [animal("capi", 100), animal("nino", 186), animal("brasa", 300), animal("pingo", 370), animal("tuca", 520), animal("lulu", 630)],
                [hive(360, 290, count=8, interval=0.3), hive(600, 330, insect="mosquito", count=5, interval=0.4, delay=0.8)],
                [dome(126, 82, 939), dome(336, 62, 907), dome(570.5, 96.5, 951)],
                survive=12, strokes=3,
                teaches="Revisão geral."))
    lv.append(L("5-6", 5, "Rainha Zumbina",
                "A Rainha sopra rajadas de vento! Encoste o abrigo nas pedras para ele não sair voando.",
                [animal("capi", 360)], [hive(90, 320, count=6, interval=1.2, delay=0.5), hive(630, 320, count=6, interval=1.2, delay=1.1)],
                [dome_over("capi", 360)], survive=14,
                rocks=[{"pos": [230, 1000], "r": 30}, {"pos": [490, 1000], "r": 30}],
                bosses=[{"pos": [360, 330], "sway": 180}],
                teaches="Chefão sem violência."))
    # ajustes finos de tinta/estrelas onde a fase pede outra lógica
    for lvl in lv:
        if lvl["id"] == "2-4":
            # o arco completo dá 2★; usar a caixa como parede (meia-água) dá 3★
            lvl["stars"] = [0.42, 0.8]
        if lvl["id"] == "5-4":
            # "Pouca Tinta": quase não sobra — só a meia-água apoiada no bloco cabe
            lvl["ink"] = int(round(stroke_len(lvl["solution"][0]) / 0.82 / 10.0) * 10)
            lvl["stars"] = [0.9, 0.97]
    return lv


if __name__ == "__main__":
    levels = campaign()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "worlds": WORLDS, "levels": levels}, f, ensure_ascii=False, indent=1)
    print(f"{len(levels)} fases gravadas em {os.path.relpath(OUT)}")
