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
HALF_H = {"capi": 30, "brasa": 46, "pingo": 28, "lulu": 18, "tuca": 24, "nino": 22,
          "gelinho": 36, "tata": 24, "pompom": 42, "nuvem": 32, "fofa": 24, "tito": 24, "patinha": 22, "kiko": 38}
HALF_W = {"capi": 56, "brasa": 26, "pingo": 28, "lulu": 37, "tuca": 46, "nino": 22,
          "gelinho": 22, "tata": 24, "pompom": 22, "nuvem": 32, "fofa": 50, "tito": 24, "patinha": 22, "kiko": 24}


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


def hole(x, insect="ant", count=4, interval=0.7, delay=0.4, floor=GROUND):
    """Buraco no chão: insetos saem dele, a não ser que uma linha esteja em cima."""
    return {"insect": insect, "pos": [x, floor], "count": count, "interval": interval, "delay": delay, "hole": True}


def holes_beside(kind, x, gap=30, **kw):
    """Dois buracos a `gap` px da borda do bichinho: onde as pernas de um abrigo justo pousam."""
    hw = HALF_W[kind]
    return [hole(x - hw - gap, **kw), hole(x + hw + gap, **kw)]


def coral(x, y, insect="jellyfish", count=4, interval=0.8, delay=0.4):
    return {"insect": insect, "pos": [x, y], "count": count, "interval": interval, "delay": delay}


def wide_dome(animals, pad=50, apex_gap=40, floor=GROUND):
    """O "círculo ingênuo": um abrigo folgado em volta de todos os bichinhos."""
    x0 = min(a["pos"][0] - HALF_W[a["type"]] for a in animals)
    x1 = max(a["pos"][0] + HALF_W[a["type"]] for a in animals)
    top = min(a["pos"][1] - HALF_H[a["type"]] for a in animals)
    return dome((x0 + x1) / 2, (x1 - x0) / 2, top, floor, pad=pad, apex_gap=apex_gap)


def slide(points, steps=6):
    """Rampa suave (para Tinta Firme): interpola os pontos de controle."""
    out = []
    for i in range(len(points) - 1):
        a, b = points[i], points[i + 1]
        for k in range(steps):
            t = k / steps
            out.append([round(a[0] + (b[0] - a[0]) * t, 1), round(a[1] + (b[1] - a[1]) * t, 1)])
    out.append(points[-1])
    return out


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
    {"id": 6, "name": "Montanha Gelada"},
    {"id": 7, "name": "Praia do Sol"},
    {"id": 8, "name": "Fundo do Mar"},
]


def stroke_len(stroke):
    return sum(math.dist(stroke[i], stroke[i + 1]) for i in range(len(stroke) - 1))


INK_RATIO = 0.55      # a solução registrada usa ~55 % da tinta
DEFAULT_STARS = (0.6, 0.8)


def L(id_, world, name, tip, animals, nests, solution, ink=None, survive=8, stars=DEFAULT_STARS, strokes=1,
      terrain=None, props=None, rocks=None, nodraw=None, teaches="", bosses=None, **extra):
    """extra: winds, goal, ink_mode, underwater, naive (traços "ingênuos" que DEVEM perder)."""
    if ink is None:
        ink = int(round(sum(stroke_len(st) for st in solution) / INK_RATIO / 10.0) * 10)
    return {
        "id": id_, "world": world, "name": name, "tip": tip, "teaches": teaches,
        "ink": ink, "survive": survive, "stars": list(stars), "strokes": strokes,
        "terrain": terrain if terrain is not None else [ground()],
        "rocks": rocks or [], "props": props or [], "nodraw": nodraw or [],
        "animals": animals, "nests": nests, "bosses": bosses or [], "solution": solution,
        **extra,
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
    lv.extend(new_worlds())
    # ajustes finos de tinta/estrelas onde a fase pede outra lógica
    for lvl in lv:
        if lvl["id"] == "2-4":
            # o arco completo dá 2★; usar a caixa como parede (meia-água) dá 3★
            lvl["stars"] = [0.42, 0.8]
        if lvl["id"] in ("6-9", "7-7", "8-5"):
            # tinta curtinha: só a solução "esperta" cabe; o arco completo (ingênuo) não
            sol = stroke_len(lvl["solution"][0])
            naive = sum(stroke_len(st) for st in lvl.get("naive", [])) or sol * 2
            lvl["ink"] = int(min(sol / 0.85, naive * 0.9))
            assert lvl["ink"] > sol * 1.03, lvl["id"]
            lvl["stars"] = [0.94, 0.99]
        if lvl["id"] == "5-4":
            # "Pouca Tinta": quase não sobra — só a meia-água apoiada no bloco cabe
            lvl["ink"] = int(round(stroke_len(lvl["solution"][0]) / 0.82 / 10.0) * 10)
            lvl["stars"] = [0.9, 0.97]
    return lv


def new_worlds():
    lv = []
    # ============================================================ Mundo 6 — Montanha Gelada
    lv.append(L("6-1", 6, "Olá, Gelinho!",
                "O Gelinho chegou escorregando da montanha. Proteja ele das abelhas!",
                [animal("gelinho", 360)], [hive(600, 340, count=5)],
                [dome_over("gelinho", 360)], survive=7,
                teaches="Novo bichinho; cenário de neve."))
    nv = animal("nuvem", 360)
    lv.append(L("6-2", 6, "Buracos na Neve",
                "Formigas vão sair dos BURACOS! Desenhe com as pontas da linha EM CIMA deles para tampar.",
                [nv], holes_beside("nuvem", 360, count=3, interval=0.8) + [hive(610, 330, count=4, delay=1.0)],
                [dome_over("nuvem", 360, pad=30)], survive=9,
                naive=[wide_dome([nv])],
                teaches="Tampar buracos com a própria linha (um círculo folgado deixa os buracos dentro!)."))
    lv.append(L("6-3", 6, "Grilos Pulões",
                "Grilos pulam por cima de paredes! Só um abrigo com teto segura.",
                [animal("kiko", 470)], [hole(110, insect="cricket", count=4, interval=1.0, delay=0.3)],
                [dome_over("kiko", 470)], survive=11,
                naive=[tent(320, height=120)],
                teaches="Inseto que pula: parede não basta."))
    # Tatá rola pela rampa de Tinta Firme até a toca
    plateau = {"poly": [[-400, 700], [0, 700], [200, 716], [200, 1800], [-400, 1800]], "style": "ground"}
    right = ground(x0=520, x1=1120)
    lv.append(L("6-4", 6, "Rumo à Toca do Tatá",
                "TINTA FIRME: a linha não cai! Faça uma rampa para o Tatá rolar até a toca.",
                [{"type": "tata", "pos": [122, 685], "flip": False}], [],
                [slide([[214, 730], [330, 820], [440, 915], [532, 986]])], survive=10,
                terrain=[plateau, right, block(660, 880, 760, 1000, "stone")],
                ink_mode="static", goal={"rect": [560, 900, 100, 100]},
                naive=[dome_over("tata", 122, floor=708)],
                teaches="Tinta Firme e objetivo de levar o bichinho até a toca."))
    lv.append(L("6-5", 6, "Teia na Caverna",
                "A aranha anda pelo teto e DESCE reto. Formigas vêm pelo chão. Abrigo com teto!",
                [animal("gelinho", 420)], [{"insect": "spider", "pos": [250, 830], "count": 2, "interval": 2.0, "delay": 0.5}, mound(80, count=4, interval=0.8)],
                [dome_over("gelinho", 420)], survive=10,
                terrain=[ground(), block(150, 760, 600, 800, "stone")],
                naive=[tent(300, height=110)],
                teaches="Aranha que desce do teto."))
    cp = animal("capi", 360)
    lv.append(L("6-6", 6, "Abelha Broca",
                "A Abelha Broca FURA a linha depois de um tempinho. Dois traços = parede dupla!",
                [cp], [hive(590, 420, insect="broca", count=3, interval=0.8)],
                [dome_over("capi", 360, pad=20, apex_gap=26), dome_over("capi", 360, pad=50, apex_gap=60)],
                survive=6.0, strokes=2,
                naive=[wide_dome([cp])],
                teaches="Parede dupla contra quem fura."))
    lv.append(L("6-7", 6, "Ventania",
                "Rajadas de vento empurram a linha! Encoste o abrigo na pedra para ele não escorregar.",
                [animal("nuvem", 340)], [hive(90, 340, count=6, delay=1.0)],
                [dome_over("nuvem", 340)], survive=10,
                rocks=[{"pos": [470, 1000], "r": 34}],
                winds=[{"rect": [-100, 150, 920, 900], "dir": [1, 0], "force": 950, "on": 2.0, "off": 1.5, "delay": 0.5}],
                teaches="Vento empurra linhas e insetos."))
    # Gelinho escorrega (quase sem atrito) por um tobogã de Tinta Firme até o iglu
    ice_hill = {"poly": [[-400, 660], [60, 660], [190, 700], [190, 1800], [-400, 1800]], "style": "ice"}
    lv.append(L("6-8", 6, "Tobogã do Gelinho",
                "O Gelinho escorrega no gelo! Faça um tobogã de Tinta Firme até o iglu.",
                [{"type": "gelinho", "pos": [90, 631], "flip": False}], [hive(620, 330, count=3, delay=2.5)],
                [slide([[204, 714], [320, 800], [430, 900], [534, 986]])], survive=9,
                terrain=[ice_hill, ground(x0=520, x1=1120), block(670, 880, 760, 1000, "stone")],
                ink_mode="static", goal={"rect": [560, 900, 110, 100]},
                naive=[dome_over("gelinho", 90, floor=667)],
                teaches="Bichinho que escorrega + objetivo."))
    kk = animal("kiko", 330)
    lean_k = [[422, 866], [390, 868], [356, 876], [322, 890], [292, 910], [270, 940], [258, 988]]
    lv.append(L("6-9", 6, "Abrigo na Rocha",
                "Pouquíssima tinta! Use o paredão de pedra como parede e faça só um telhadinho.",
                [kk], [hive(100, 330, insect="mosquito", count=6, interval=0.35)],
                [lean_k], survive=9,
                terrain=[ground(), block(400, 880, 470, 1000, "stone")],
                teaches="Usar o cenário e economizar tinta."))
    nv2 = animal("nuvem", 200)
    gl2 = animal("gelinho", 520)
    lv.append(L("6-10", 6, "Pico Nevado",
                "Dois amigos, dois traços e buracos dos dois lados. Tampe tudo!",
                [nv2, gl2], holes_beside("nuvem", 200, count=3, interval=0.8) + holes_beside("gelinho", 520, count=3, interval=0.8) + [hive(360, 300, count=6, delay=1.2)],
                [dome_over("nuvem", 200, pad=30), dome_over("gelinho", 520, pad=30)], survive=10, strokes=2,
                naive=[wide_dome([nv2], pad=50), wide_dome([gl2], pad=50)],
                teaches="Revisão: buracos + dois traços."))

    # ============================================================ Mundo 7 — Praia do Sol
    lv.append(L("7-1", 7, "Pompom na Praia",
                "Pompom tem orelhas compridas: capriche na altura do abrigo!",
                [animal("pompom", 380)], [hive(130, 330, count=6)],
                [dome_over("pompom", 380)], survive=8,
                teaches="Novo bichinho; cenário de praia."))
    lv.append(L("7-2", 7, "Coqueiro Traiçoeiro",
                "Um coco vai cair (veja a linha pontilhada)! Um abrigo firme aguenta o bonk.",
                [animal("pompom", 360)], [hive(620, 340, count=4, delay=2.0)],
                [dome_over("pompom", 360)], survive=8,
                props=[{"type": "coconut", "pos": [360, 520], "drop": 2.0}],
                teaches="Objetos que caem."))
    pt = animal("patinha", 360)
    lv.append(L("7-3", 7, "Caranguejos da Toca",
                "Caranguejos moram nos buracos da areia. Tampe os buracos com as pontas da linha!",
                [pt], holes_beside("patinha", 360, insect="crab", count=2, interval=1.2) + [hive(600, 330, count=4, delay=1.0)],
                [dome_over("patinha", 360, pad=30)], survive=9,
                naive=[wide_dome([pt])],
                teaches="Tampar tocas (de novo, agora com caranguejos)."))
    pt4 = animal("patinha", 130)
    pp4 = animal("pompom", 600)
    lv.append(L("7-4", 7, "Piquenique",
                "As abelhas vão PRIMEIRO no mel. Quando acabar, atacam quem estiver mais perto do pote!",
                [pt4, pp4], [hive(560, 330, count=6, interval=0.3)],
                [dome_over("patinha", 130)], survive=10,
                props=[{"type": "honey", "pos": [250, 978], "amount": 4.0}],
                naive=[dome_over("pompom", 600)],
                teaches="Isca de mel: quem está em perigo de verdade?"))
    lv.append(L("7-5", 7, "Siri Teimoso",
                "Caranguejos empurram com força e não têm medo de água. Abrigo largo e pesado!",
                [animal("fofa", 380)], [mound(70, insect="crab", count=3, interval=1.2), hive(640, 330, count=4, delay=1.5)],
                [dome_over("fofa", 380, pad=30)], survive=11,
                teaches="Inseto que empurra na praia."))
    lv.append(L("7-6", 7, "Vespas no Quiosque",
                "Vespas avisam com \"!\" antes da investida, e ainda tem coco caindo!",
                [animal("pompom", 400)], [hive(110, 330, insect="wasp", count=2, interval=1.5)],
                [dome_over("pompom", 400, pad=28)], survive=9,
                props=[{"type": "coconut", "pos": [400, 500], "drop": 3.0}],
                teaches="Combinação: investida + queda."))
    shelf = {"poly": [[300, 860], [720, 860], [720, 1000], [560, 1000], [560, 900], [300, 900]], "style": "stone"}
    lv.append(L("7-7", 7, "Toca no Rochedo",
                "Tinta Firme e quase nada de tinta: feche só a entrada da toca da Patinha!",
                [animal("patinha", 470)], [hive(90, 760, insect="mosquito", count=7, interval=0.3)],
                [[[288, 913], [288, 950], [288, 988]]], survive=9,
                terrain=[ground(), shelf], ink_mode="static",
                naive=[dome_over("patinha", 470, apex_gap=20)],
                teaches="Tinta Firme como portinha."))
    dune = {"poly": [[-400, 740], [40, 740], [190, 760], [190, 1800], [-400, 1800]], "style": "ground"}
    beach_pit = [dune, {"poly": [[190, 1060], [470, 1060], [470, 1800], [190, 1800]], "style": "ground"}, ground(x0=470, x1=1120), block(680, 890, 760, 1000, "stone")]
    lv.append(L("7-8", 7, "Rumo ao Guarda-Sol",
                "O Pingo vai rolar da duna! Faça uma rampa de Tinta Firme por cima da água até a toca.",
                [{"type": "pingo", "pos": [110, 718], "flip": False}], [],
                [slide([[202, 772], [300, 840], [400, 920], [482, 986]])], survive=10,
                terrain=beach_pit, props=[{"type": "water", "rect": [190, 990, 280, 70]}],
                ink_mode="static", goal={"rect": [540, 900, 130, 100]},
                naive=[dome_over("pingo", 110, floor=748)],
                teaches="Rampa sobre a água."))
    pt9 = animal("patinha", 360)
    lv.append(L("7-9", 7, "Coco e Caranguejo",
                "Coco caindo E caranguejos nos buracos. Abrigo firme com as pontas nos buracos!",
                [pt9], holes_beside("patinha", 360, insect="crab", count=2, interval=1.2),
                [dome_over("patinha", 360, pad=30)], survive=9,
                props=[{"type": "coconut", "pos": [360, 540], "drop": 2.5}],
                naive=[wide_dome([pt9])],
                teaches="Combinar regras."))
    pp10 = animal("pompom", 190)
    ff10 = animal("fofa", 500)
    lv.append(L("7-10", 7, "Festa na Praia",
                "Dois traços para dois amigos. Cuidado com as tocas e com o coco da Fofa!",
                [pp10, ff10], holes_beside("pompom", 190, insect="crab", count=2, interval=1.2) + [hive(360, 300, count=6, delay=1.0)],
                [dome_over("pompom", 190, pad=30), dome_over("fofa", 500, pad=30)], survive=10, strokes=2,
                props=[{"type": "coconut", "pos": [500, 520], "drop": 3.0}],
                naive=[wide_dome([pp10], pad=50), dome_over("fofa", 500, pad=30)],
                teaches="Revisão da praia."))

    # ============================================================ Mundo 8 — Fundo do Mar
    sea = dict(underwater=True)
    lv.append(L("8-1", 8, "Olá, Tito!",
                "No fundo do mar, as águas-vivas nadam devagarinho até o Tito.",
                [animal("tito", 360)], [coral(600, 380, count=4)],
                [dome_over("tito", 360)], survive=10, **sea,
                teaches="Novo mundo: fundo do mar."))
    lv.append(L("8-2", 8, "Baiacu Bolha",
                "O baiacu INCHA quando chega perto e empurra tudo. Deixe o abrigo bem espaçoso!",
                [animal("tito", 360)], [coral(620, 400, insect="puffer", count=3, interval=1.2)],
                [dome_over("tito", 360, pad=40, apex_gap=44)], survive=10, **sea,
                teaches="Criatura que cresce."))
    ff3 = animal("fofa", 360)
    lv.append(L("8-3", 8, "Caranguejos do Fundo",
                "Até no fundo do mar tem toca de caranguejo! Tampe com as pontas da linha.",
                [ff3], holes_beside("fofa", 360, insect="crab", count=2, interval=1.2) + [coral(620, 380, count=3, delay=1.5)],
                [dome_over("fofa", 360, pad=30)], survive=10, **sea,
                naive=[wide_dome([ff3])],
                teaches="Tocas no fundo do mar."))
    lv.append(L("8-4", 8, "Correnteza",
                "A correnteza empurra as águas-vivas e a sua linha! Apoie o abrigo na pedra.",
                [animal("lulu", 340)], [coral(80, 380, count=5, interval=0.7)],
                [dome_over("lulu", 340)], survive=11,
                rocks=[{"pos": [450, 1000], "r": 32}],
                winds=[{"rect": [-100, 150, 920, 900], "dir": [1, 0], "force": 500, "on": 2.5, "off": 1.5, "delay": 0.5}],
                **sea, teaches="Correnteza (vento submarino)."))
    cave = [ground(), block(200, 880, 260, 1000, "stone"), block(400, 880, 460, 1000, "stone")]
    lv.append(L("8-5", 8, "Toca do Polvo",
                "O Tito se escondeu entre as pedras. Só falta uma tampa na entrada de cima!",
                [animal("tito", 330)], [coral(600, 360, count=5, interval=0.6)],
                [[[246, 866], [300, 866], [360, 866], [414, 866]]], survive=10,
                terrain=cave,
                naive=[dome(330, 130, 880, pad=10, apex_gap=30)],
                **sea, teaches="Usar o cenário: uma tampinha basta."))
    tt6 = animal("tito", 300)
    ll6 = animal("lulu", 440)
    lv.append(L("8-6", 8, "Cardume Gelatinoso",
                "Muitas águas-vivas dos dois lados! Um abrigo grande para os dois amigos.",
                [tt6, ll6], [coral(80, 360, count=5, interval=0.6), coral(640, 360, count=5, interval=0.6, delay=0.8)],
                [dome(370, 107, 952, pad=24)], survive=11, **sea,
                teaches="Muitas criaturas."))
    lv.append(L("8-7", 8, "Recife de Coral",
                "Baiacus E águas-vivas. Espaço para inchar e nada de frestas!",
                [animal("fofa", 360)], [coral(620, 360, insect="puffer", count=2, interval=1.5), coral(100, 360, count=4, interval=0.8)],
                [dome_over("fofa", 360, pad=40, apex_gap=44)], survive=11, **sea,
                teaches="Combinação no recife."))
    tt8 = animal("tito", 360)
    lv.append(L("8-8", 8, "Polvo e Caranguejo",
                "Tocas de caranguejo e baiacu. Pontas nos buracos e abrigo espaçoso!",
                [tt8], holes_beside("tito", 360, insect="crab", count=2, interval=1.2, gap=34) + [coral(620, 380, insect="puffer", count=2, interval=1.5, delay=1.5)],
                [dome_over("tito", 360, pad=34, apex_gap=44)], survive=10, **sea,
                naive=[wide_dome([tt8], pad=56)],
                teaches="Tampar + espaço."))
    lv.append(L("8-9", 8, "Correnteza Forte",
                "Correnteza fortíssima! Trave o abrigo entre as duas pedras.",
                [animal("tito", 360)], [coral(80, 360, count=6, interval=0.6)],
                [dome_over("tito", 360, pad=30)], survive=11,
                rocks=[{"pos": [270, 1000], "r": 26}, {"pos": [450, 1000], "r": 26}],
                winds=[{"rect": [-100, 150, 920, 900], "dir": [1, 0], "force": 1100, "on": 2.0, "off": 1.0, "delay": 0.5}],
                **sea, teaches="Travar o abrigo."))
    tt10 = animal("tito", 190)
    ff10b = animal("fofa", 500)
    lv.append(L("8-10", 8, "Rei dos Mares",
                "O grande final do fundo do mar: dois traços, tocas, baiacus e águas-vivas!",
                [tt10, ff10b], holes_beside("tito", 190, insect="crab", count=2, interval=1.2) + [coral(360, 330, insect="puffer", count=2, interval=1.5), coral(640, 360, count=4, interval=0.8)],
                [dome_over("tito", 190, pad=30, apex_gap=40), dome_over("fofa", 500, pad=36, apex_gap=44)], survive=11, strokes=2,
                naive=[wide_dome([tt10], pad=50), dome_over("fofa", 500, pad=36, apex_gap=44)],
                **sea, teaches="Revisão final."))
    return lv


if __name__ == "__main__":
    levels = campaign()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "worlds": WORLDS, "levels": levels}, f, ensure_ascii=False, indent=1)
    print(f"{len(levels)} fases gravadas em {os.path.relpath(OUT)}")
