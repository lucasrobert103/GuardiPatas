"""Campanha de ESTRATÉGIA do GuardiPatas (64 fases, 8 mundos).

Regra de ouro (o teste automático confere): a partir da 1-3, o "círculo" — um abrigo
fechado em volta de cada bichinho, justo ou folgado — PERDE. Cada fase pede uma ideia:

  encosta     use o muro/pedra como parede (só dá tinta para meio abrigo)
  caverna     o bichinho está numa caverna: feche só a porta
  tampa       bichinho num buraco fundo: uma tampa por cima
  buracos     os insetos saem de buracos no chão: tampe as saídas
  pontaria    os buracos estão colados no bichinho: os pés do abrigo pousam neles
  isca        a Traça Come-Tinta rói a linha mais perto: atraia ela para a água
  rinoceronte o Besouro-Rinoceronte vira abrigos soltos: tampe a toca dele
  ponte/rampa o medroso foge quando VÊ um inseto: guie a fuga até a toca segura
  escolha     isca de luz/mel: descubra quem está em perigo de verdade
  muralha     formigas não sobem parede íngreme: um muro protege a turma toda
  caixa       a caixa é a outra parede
  + Tinta Firme (rampas até a toca), vento, chefões...

A tinta é calculada para a solução registrada caber com folga, mas o círculo NÃO
(`ink_for`). Coordenadas: tela 720×1280, chão em y = 1000.
"""
import math

from make_levels import (GROUND, HALF_H, HALF_W, WORLDS, L, animal, block, coral, dome, dome_over,
                         ground, hive, hole, hooked_dome, mound, slide, stroke_len, tent)

G = GROUND
SOL_RATIO = 0.62      # a solução usa ~62 % da tinta
CIRCLE_CAP = 0.6      # a tinta nunca passa de 60 % do círculo justo (meio círculo cai e deixa brecha)


# ---------------------------------------------------------------- medidas
def circle_len(animals, strokes=1, pad=22, apex=30):
    """Comprimento do 'círculo justo' que o teste automático desenha (tests/test_runner.gd)."""
    boxes = []
    for a in animals:
        hw, hh = HALF_W[a["type"]], HALF_H[a["type"]]
        x, y = a["pos"]
        boxes.append([x - hw, y - hh, x + hw, y + hh])
    boxes.sort(key=lambda b: b[0])
    per = max(1, math.ceil(len(boxes) / max(strokes, 1)))
    total = 0.0
    for i in range(0, len(boxes), per):
        g = boxes[i:i + per]
        x0, y0 = min(b[0] for b in g), min(b[1] for b in g)
        x1, y1 = max(b[2] for b in g), max(b[3] for b in g)
        total += stroke_len(dome((x0 + x1) / 2, (x1 - x0) / 2, y0, y1 + 1, pad=pad, apex_gap=apex))
    return total


def ink_for(solution, animals, strokes, cap=True):
    sol = sum(stroke_len(s) for s in solution)
    ink = sol / SOL_RATIO
    if cap:
        ink = min(ink, circle_len(animals, strokes) * CIRCLE_CAP)
        assert ink >= sol * 1.06, f"a solução ({sol:.0f}) não cabe abaixo do círculo ({circle_len(animals, strokes):.0f})"
    return int(ink)


def bez(p0, p1, p2, n=10):
    out = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        out.append([round(x), round(y)])
    return out


def flat(x0, x1, y=G - 12):
    return [[x0, y], [round((x0 + x1) / 2), y], [x1, y]]


def burrow(x, floor=G, w=110, h=80):
    return {"type": "burrow", "rect": [x, floor - h, w, h]}


def water(x, y, w, h):
    return {"type": "water", "rect": [x, y, w, h]}


def ground_pieces(*spans, y=G):
    """Chão em pedaços (os vãos entre eles são abismos)."""
    return [{"poly": [[a, y], [b, y], [b, 1800], [a, 1800]], "style": "ground"} for a, b in spans]


def thorns(x0, x1, h=40, floor=G):
    return {"poly": [[x0, floor], [x0 + 8, floor - h], [x1 - 8, floor - h], [x1, floor]], "style": "thorns"}


# ---------------------------------------------------------------- arquétipos
def lean_to(kind, x, side="left", wall_w=70, wall_top=None, reach=26, floor=G, style="stone"):
    """Bichinho colado num muro; a solução é uma meia-água do topo do muro até o chão."""
    hw, hh = HALF_W[kind], HALF_H[kind]
    top = floor - 2 * hh
    wall_top = wall_top if wall_top is not None else top - 8
    s = -1 if side == "left" else 1
    wall_in = x + s * (hw + 6)
    wall_out = wall_in + s * wall_w
    wall = block(min(wall_in, wall_out), wall_top, max(wall_in, wall_out), floor, style)
    # "Γ": telhado reto saindo do topo do muro e descida até o chão (curva suave no canto)
    roof_y = min(wall_top - 12, top - 22)
    start = [wall_in - s * 16, roof_y]
    corner = [x - s * (hw + 16), roof_y]
    end = [x - s * (hw + reach), floor - 12]
    pts = [start]
    for i in range(1, 4):
        pts.append([round(start[0] + (corner[0] - start[0]) * i / 4), roof_y])
    pts += bez([corner[0] + s * 18, roof_y], [corner[0] - s * 6, roof_y + 4], [end[0], roof_y + 40], n=4)[1:]
    pts.append([end[0], round((roof_y + 40 + end[1]) / 2)])
    pts.append(end)
    return wall, pts


def cave(kind, x, mouth="right", inner=80, back=110, front=80, roof_th=40, opening=74, floor=G, style="stone"):
    """Caverna com teto alto por dentro e BOCA BAIXA (um "beiral" desce na entrada).
    A porta (solução) é curta: encosta no beiral pelo lado de fora. Lá dentro sobra espaço
    em cima do bichinho, então um meio círculo deixa brecha para os insetos."""
    hw, hh = HALF_W[kind], HALF_H[kind]
    roof_y = floor - 2 * hh - inner
    s = 1 if mouth == "right" else -1
    back_in = x - s * (hw + back)
    back_out = back_in - s * 40
    mouth_x = x + s * (hw + front)
    lip_top = floor - opening
    terr = [block(min(back_in, back_out), roof_y - roof_th, max(back_in, back_out), floor, style),
            block(min(back_out, mouth_x), roof_y - roof_th, max(back_out, mouth_x), roof_y, style),
            block(min(mouth_x, mouth_x - s * 34), roof_y - 2, max(mouth_x, mouth_x - s * 34), lip_top, style)]
    # porta = "escada" encostada no beiral, do lado de fora: fica firme sozinha
    top = [mouth_x + s * 12, lip_top - 16]
    foot = [mouth_x + s * 40, floor - 12]
    door = [top, [round((top[0] + foot[0]) / 2), round((top[1] + foot[1]) / 2)], foot]
    return terr, door, mouth_x


def pit_lid(kind, x, margin=34, extra_depth=14):
    """Bichinho num buraco fundo; a solução é uma tampa sobre a boca."""
    hw, hh = HALF_W[kind], HALF_H[kind]
    depth = 2 * hh + extra_depth
    x0, x1 = x - hw - margin, x + hw + margin
    terr = ground_pieces((-400, x0), (x1, 1120)) + [block(x0 - 1, G + depth, x1 + 1, 1800)]
    lid = flat(x0 - 26, x1 + 26)
    return terr, animal(kind, x, floor=G + depth), lid


def precision(kind, x, gap=14, **hole_kw):
    """Buracos colados no bichinho: o abrigo certo pousa os pés em cima deles."""
    hw = HALF_W[kind]
    holes = [hole(x - hw - gap, **hole_kw), hole(x + hw + gap, **hole_kw)]
    return holes, dome_over(kind, x, pad=gap)


def herd(kind, x, hazard, hx0, hx1, burrow_x, nodraw_w=180, floor=G):
    """Medroso que foge: o perigo (abismo/água/espinhos) fica entre ele e a toca segura."""
    hh = HALF_H[kind]
    props = [burrow(burrow_x, floor)]
    if hazard == "pit":
        terr = ground_pieces((-400, hx0), (hx1, 1120))
        sol = flat(hx0 - 22, hx1 + 22)
    elif hazard == "water":
        terr = ground_pieces((-400, hx0), (hx1, 1120)) + [block(hx0 - 1, floor + 110, hx1 + 1, 1800)]
        props.append(water(hx0, floor + 8, hx1 - hx0, 102))
        sol = flat(hx0 - 22, hx1 + 22)
    else:  # espinhos: uma rampa por cima da moita
        terr = [ground(), thorns(hx0, hx1)]
        mid = (hx0 + hx1) / 2
        sol = bez([hx0 - 40, floor - 12], [mid, floor - 110], [hx1 + 40, floor - 12])
    nodraw = [[x - nodraw_w / 2, floor - 2 * hh - 70, nodraw_w, 2 * hh + 70]]
    return terr, props, sol, nodraw


def decoy_pond(side="left", pond_w=120):
    """Laguinho na beira da tela: uma linha por cima dele atrai a Traça para a água."""
    if side == "left":
        terr = [{"poly": [[pond_w - 20, G], [1120, G], [1120, 1800], [pond_w - 20, 1800]], "style": "ground"},
                block(-400, G + 110, pond_w - 20, 1800), block(-400, G, -20, G + 110)]
        props = [water(-20, G + 10, pond_w, 100)]
        decoy = [[12, G - 15], [52, G - 15], [pond_w - 30, G - 15]]
    else:
        x0 = 720 - pond_w + 20
        terr = [{"poly": [[-400, G], [x0, G], [x0, 1800], [-400, 1800]], "style": "ground"},
                block(x0, G + 110, 1120, 1800), block(740, G, 1120, G + 110)]
        props = [water(x0, G + 10, pond_w, 100)]
        decoy = [[x0 + 10, G - 15], [x0 + 50, G - 15], [708, G - 15]]
    return terr, props, decoy


def hook_rocks(kind, x, foot=110, pad=30, apex=40, floor=G):
    """Abrigo com pezinhos que passam por baixo de duas pedras: não sai voando."""
    hd = hooked_dome(kind, x, foot=foot, floor=floor, pad=pad, apex_gap=apex)
    fx = [hd[0][0] + 30, hd[-1][0] - 30]
    return hd, [{"pos": [fx[0], floor - 59], "r": 30}, {"pos": [fx[1], floor - 59], "r": 30}]


SEA = {"underwater": True}
MOUNTAIN_WIND = {"rect": [-100, 150, 920, 900], "dir": [1, 0], "force": 950, "on": 2.0, "off": 1.4, "delay": 0.6}


# ---------------------------------------------------------------- campanha
def campaign():
    lv = []
    errors = []

    def add(id_, world, name, tip, animals, nests, solution, strokes=1, cap=True, ink=None, **kw):
        if ink is None:
            try:
                ink = ink_for(solution, animals, strokes, cap)
            except AssertionError as e:
                errors.append(f"{id_}: {e}")
                ink = 1
        lv.append(L(id_, world, name, tip, animals, nests, solution, ink=ink, strokes=strokes, **kw))

    # ============================================================ 1 — Jardim dos Bichinhos
    add("1-1", 1, "Oi, Capitu!", "Desenhe um abrigo sobre a Capitu. Os insetos saem quando você solta o dedo!",
        [animal("capi", 360)], [hive(600, 360, count=5)], [dome_over("capi", 360)], cap=False, survive=6,
        teaches="Desenhar, soltar e a linha cair com peso.")
    add("1-2", 1, "Zumbido em Dobro", "Abelhas dos dois lados! Um abrigo fechado protege de todas as direções.",
        [animal("capi", 360)], [hive(120, 380, count=4), hive(600, 380, count=4, delay=0.8)],
        [dome_over("capi", 360)], cap=False, survive=8, teaches="Ameaças de várias direções.")
    terr, door, _ = cave("capi", 300, mouth="right")
    add("1-3", 1, "Toca Escura", "A tinta não dá para um abrigo inteiro! A Capitu está numa toca: feche só a porta.",
        [animal("capi", 300)], [hive(640, 380, count=7)], [door], survive=9, terrain=[ground()] + terr,
        teaches="Fechar a entrada em vez de cercar.")
    trio = [animal("pingo", 130), animal("brasa", 240), animal("capi", 370)]
    roof_y = 830
    terr = [ground(), block(40, roof_y - 40, 520, roof_y, "wood"), block(40, roof_y, 80, G, "wood")]
    add("1-4", 1, "Varanda", "Os três amigos estão na varanda. Não dá tinta para cercar todos: feche o lado aberto!",
        trio, [hive(650, 360, count=7), mound(690, count=5, interval=0.7, delay=1.0)],
        [[[532, roof_y - 20], [555, 900], [578, G - 12]]], survive=11, terrain=terr,
        teaches="Proteger vários fechando uma passagem.")
    add("1-5", 1, "Tampa-Buracos", "As formigas saem dos BURACOS. Deite a linha bem em cima de cada buraco!",
        [animal("brasa", 110), animal("capi", 360), animal("tuca", 610)],
        [hole(235, count=5, interval=0.7), hole(485, count=5, interval=0.7, delay=0.8)],
        [flat(205, 265), flat(455, 515)], strokes=2, survive=10, teaches="Cortar o problema na origem.")
    terr, props, sol, nd = herd("pompom", 290, "pit", 420, 500, 570)
    add("1-6", 1, "Pompom Medroso", "O Pompom FOGE quando vê um inseto — e não olha onde pisa! Faça uma ponte até a toca.",
        [animal("pompom", 290)], [hive(60, 420, count=6, interval=0.4)], [sol], cap=False, survive=10,
        terrain=terr, props=props, nodraw=nd, teaches="Bichinho medroso: guiar a fuga.")
    holes, d = precision("pingo", 360, gap=10, count=4, interval=0.8)
    add("1-7", 1, "Pontaria", "Os buracos estão colados no Pingo! Os pés do abrigo têm que pousar BEM em cima deles.",
        [animal("pingo", 360)], holes + [hive(620, 360, count=4, delay=1.5)], [d], cap=False, survive=10,
        teaches="Precisão: o abrigo também tampa.")
    terr, door, mouth = cave("capi", 280, mouth="right", front=110)
    hx = 280 + HALF_W["capi"] + 12
    add("1-8", 1, "Formigas na Toca", "Tem um formigueiro colado na Capitu, DENTRO da toca! Tampe o buraco e feche a porta.",
        [animal("capi", 280)], [hole(hx, count=5, interval=0.6, delay=0.6), hive(640, 360, count=6, delay=1.0)],
        [flat(hx - 4, hx + 44), door], strokes=2, cap=False, survive=11, terrain=[ground()] + terr,
        teaches="Revisão: duas ideias juntas.")

    # ============================================================ 2 — Floresta Encantada
    terr, props, decoy = decoy_pond("left")
    add("2-1", 2, "Traça Come-Tinta", "A Traça rói a linha MAIS PERTO dela. Dê uma isca por cima do laguinho!",
        [animal("capi", 430)], [mound(170, insect="traca", count=4, interval=0.8), hive(650, 360, count=7, delay=2.2)],
        [dome_over("capi", 430), decoy], strokes=2, cap=False, survive=12, terrain=terr, props=props,
        teaches="Isca: usar o comportamento do inseto contra ele.")
    terr, door, _ = cave("kiko", 420, mouth="left", opening=60)
    add("2-2", 2, "Mosquitos no Oco", "Mosquitos passam por qualquer frestinha. Aqui a tinta é FIRME: feche a porta do oco bem rente!",
        [animal("kiko", 420)], [hive(80, 360, insect="mosquito", count=8, interval=0.3)], [door], survive=9,
        terrain=[ground()] + terr, ink_mode="static", teaches="Fechar sem frestas.")
    add("2-3", 2, "Luz da Lanterna", "As mariposas ficam na lanterna. Quando ela apagar, atacam quem estiver MAIS PERTO.",
        [animal("kiko", 200), animal("capi", 570)], [hive(360, 300, insect="moth", count=6, interval=0.3)],
        [dome_over("kiko", 200)], survive=13, props=[{"type": "lamp", "pos": [100, 650], "duration": 5}],
        teaches="Descobrir quem está em perigo.")
    terr, props, sol, nd = herd("nino", 470, "water", 210, 330, 60)
    add("2-4", 2, "Nino no Riacho", "O Nino foge das mariposas e cai no riacho! Faça uma ponte até a toca dele.",
        [animal("nino", 470)], [hive(680, 380, insect="moth", count=5, interval=0.5)], [sol], cap=False, survive=10,
        terrain=terr, props=props, nodraw=nd, teaches="Fuga com água no caminho.")
    terr, props, decoy = decoy_pond("right")
    add("2-5", 2, "Traças na Beira", "Traças à direita, abelhas à esquerda. Uma isca no lago e um abrigo para o Kiko!",
        [animal("kiko", 260)], [mound(520, insect="traca", count=4, interval=0.8), hive(70, 360, count=6, delay=2.2)],
        [dome_over("kiko", 260), decoy], strokes=2, cap=False, survive=12, terrain=terr, props=props,
        teaches="Isca do outro lado.")
    add("2-6", 2, "Duas Lanternas", "As mariposas trocam de lanterna quando uma apaga. Depois da ÚLTIMA, vão no mais perto dela.",
        [animal("nino", 110), animal("capi", 360), animal("brasa", 610)],
        [hive(360, 280, insect="moth", count=6, interval=0.3)], [dome_over("brasa", 610)], survive=14,
        props=[{"type": "lamp", "pos": [200, 640], "duration": 3}, {"type": "lamp", "pos": [560, 640], "duration": 7}],
        teaches="Prever o caminho dos insetos.")
    terr, props, decoy = decoy_pond("right")
    add("2-7", 2, "Clareira Perigosa", "Rinoceronte, Traças e abelhas! Tampe a toca do Rino, dê a isca e cubra o Kiko.",
        [animal("kiko", 330)], [hole(90, insect="rino", count=1, delay=0.4), mound(570, insect="traca", count=3, interval=1.0),
                                hive(200, 300, count=5, delay=2.6)],
        [flat(60, 120), decoy, dome_over("kiko", 330)], strokes=3, cap=False, survive=13, terrain=terr, props=props,
        teaches="Três ameaças, três traços.")
    terr_c, door, _ = cave("capi", 470, mouth="left")
    terr_p, props, decoy = decoy_pond("left")
    add("2-8", 2, "Floresta Escura", "A Traça vai roer a porta da toca! Feche a porta E dê uma isca no laguinho.",
        [animal("capi", 470)], [mound(150, insect="traca", count=3, interval=1.0, delay=0.5), hive(120, 300, count=6, delay=2.4)],
        [door, decoy], strokes=2, cap=False, survive=13, terrain=terr_p + terr_c, props=props, teaches="Combinar duas ideias.")

    # ============================================================ 3 — Vale das Formigas
    add("3-1", 3, "Rinoceronte!", "O Rinoceronte VIRA abrigos soltos. Tampe a toca dele primeiro!",
        [animal("capi", 420)], [hole(150, insect="rino", count=2, interval=2.0, delay=0.3), hive(650, 360, count=6, delay=2.5)],
        [flat(120, 180), dome_over("capi", 420)], strokes=2, cap=False, survive=12, teaches="Rinoceronte e prioridade.")
    add("3-2", 3, "Beira do Abismo", "O Pompom vai fugir para a beirada! Faça um escorregador por cima dos espinhos até a toca.",
        [animal("pompom", 230, floor=820)], [hive(50, 420, count=6, interval=0.4)],
        [slide([[392, 812], [480, 880], [580, 988]])], cap=False, survive=10,
        terrain=[{"poly": [[-400, 820], [380, 820], [380, 1800], [-400, 1800]], "style": "ground"}, ground(x0=380),
                 thorns(380, 560, h=50)],
        props=[burrow(600)], nodraw=[[140, 680, 180, 130]], teaches="Rampa para a fuga.")
    terr, props, decoy = decoy_pond("right")
    add("3-3", 3, "Dupla Encrenca", "Um Rinoceronte e duas Traças! Tampe a toca do Rino e leve as Traças para o lago.",
        [animal("capi", 260)], [hole(110, insect="rino", count=1, delay=0.3), mound(470, insect="traca", count=2, interval=1.2)],
        [flat(80, 140), decoy], strokes=2, cap=False, survive=12, terrain=terr, props=props,
        teaches="Duas ameaças, duas ideias.")
    holes, d = precision("capi", 380, gap=12, count=5, interval=0.7)
    add("3-4", 3, "Formigueiro Gigante", "Formigueiros colados na Capitu! Pouse as pontas do abrigo BEM em cima dos buracos.",
        [animal("capi", 380)], holes + [mound(660, insect="beetle", count=1, delay=2.0)], [d], cap=False, survive=11,
        teaches="Precisão + empurrão.")
    h1, d1 = precision("brasa", 190, gap=10, insect="cricket", count=3, interval=1.0)
    h2, d2 = precision("kiko", 520, gap=10, insect="cricket", count=3, interval=1.0, delay=0.6)
    add("3-5", 3, "Grilos Pulões", "Grilos pulam por cima de paredes e saem de buracos colados nos amigos. Abrigos com os pés nos buracos!",
        [animal("brasa", 190), animal("kiko", 520)], h1 + h2, [d1, d2], strokes=2, cap=False, survive=11,
        teaches="Inseto que pula.")
    add("3-6", 3, "Tocas do Vale", "Rinoceronte numa toca, formigas na outra e abelhas no céu. Tampe as tocas e cubra a Capitu.",
        [animal("capi", 450)], [hole(120, insect="rino", count=1, delay=0.5), hole(250, count=5, interval=0.7),
                                hive(660, 380, count=5, delay=2.0)],
        [flat(90, 150), flat(220, 280), dome_over("capi", 450)], strokes=3, cap=False, survive=12,
        teaches="Ordem das tarefas.")
    terr_c, door, _ = cave("capi", 470, mouth="left", front=90)
    add("3-7", 3, "Rino na Toca", "O Rinoceronte vira portas soltas! Tampe a toca dele e feche a porta da Capitu.",
        [animal("capi", 470)], [hole(110, insect="rino", count=1, delay=0.4), hive(90, 330, count=6, delay=1.6)],
        [flat(85, 135), door], strokes=2, cap=False, survive=11, terrain=[ground()] + terr_c,
        teaches="A porta também precisa de proteção.")
    add("3-8", 3, "Vale Inteiro", "Três tocas, três traços: uma delas é do Rinoceronte. Tampe todas!",
        [animal("brasa", 100), animal("capi", 360), animal("pingo", 620)],
        [hole(230, count=5, interval=0.7), hole(490, insect="rino", count=1, delay=0.4), hole(690, count=4, interval=0.8)],
        [flat(200, 260), flat(460, 520), flat(662, 712)], strokes=3, survive=11,
        teaches="Revisão do vale.")
    assert not errors, "\n".join(errors)
    return lv
