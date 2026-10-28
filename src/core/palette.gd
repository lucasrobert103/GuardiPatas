class_name Palette
## Cores oficiais do jogo (ver docs/03-identidade-visual.md).
## Centralizar aqui garante contraste consistente e facilita temas/acessibilidade.

const OUTLINE := Color("3a2b3c")        # contorno ameixa-escuro (nunca preto puro)
const OUTLINE_W := 4.0
const WHITE := Color("fffaf2")
const CREAM := Color("fff1d6")
const BLUSH := Color(1.0, 0.56, 0.68, 0.75)

# Linguagem de cor do jogo
const INK := Color("4aa3ff")            # proteção: azul-giz
const INK_HI := Color("bfe3ff")
const INK_LOW := Color("ff7a6b")        # tinta acabando
const DANGER := Color("ff5a36")         # perigo: laranja-vermelho
const DANGER_SOFT := Color(1.0, 0.35, 0.21, 0.25)
const GOLD := Color("ffd23f")           # vitória / estrelas
const GOLD_DARK := Color("e0a100")
const NODRAW := Color(1.0, 0.35, 0.35, 0.22)

# Terreno
const GRASS := Color("7bc96f")
const GRASS_DARK := Color("4f9a4a")
const DIRT := Color("c99b6d")
const DIRT_DARK := Color("a87b52")
const STONE := Color("b8b5c9")
const WOOD := Color("d79a5b")
const WOOD_DARK := Color("a86c3a")
const WATER := Color(0.38, 0.72, 0.95, 0.75)
const WATER_HI := Color(0.8, 0.94, 1.0, 0.9)

# UI
const UI_BG := Color("fff4dc")
const UI_PANEL := Color("ffffff")
const UI_PRIMARY := Color("ff8a3d")
const UI_SECONDARY := Color("4aa3ff")
const UI_GOOD := Color("5cc46a")
const UI_MUTED := Color("cfc4b4")
const UI_TEXT := Color("3a2b3c")

## Paletas de cenário por mundo: céu topo, céu base, colinas longe, colinas perto, acento.
const WORLDS := {
	1: {"sky_top": Color("8fd3ff"), "sky_bottom": Color("e3f6ff"), "far": Color("a9dba0"), "near": Color("8fcf84"), "accent": Color("ff9ec7"), "ground": Color("7bc96f"), "dirt": Color("c99b6d")},
	2: {"sky_top": Color("6fb7a8"), "sky_bottom": Color("d8f1d0"), "far": Color("5e9e7a"), "near": Color("4f8a68"), "accent": Color("ffe28a"), "ground": Color("6cb86a"), "dirt": Color("9c7a5a")},
	3: {"sky_top": Color("ffb27a"), "sky_bottom": Color("ffe9c7"), "far": Color("e0a679"), "near": Color("cf8f5e"), "accent": Color("ffd23f"), "ground": Color("d9b45a"), "dirt": Color("c08552")},
	4: {"sky_top": Color("7aa7e0"), "sky_bottom": Color("d6ecff"), "far": Color("8bb8c9"), "near": Color("6fa3b0"), "accent": Color("b3f0ff"), "ground": Color("8ccf7a"), "dirt": Color("a08a74")},
	5: {"sky_top": Color("3b3f7a"), "sky_bottom": Color("9a86c9"), "far": Color("4d4f8a"), "near": Color("3f4275"), "accent": Color("ffe08a"), "ground": Color("5f9a64"), "dirt": Color("7a6250")},
}


static func world(world_id: int) -> Dictionary:
	return WORLDS.get(world_id, WORLDS[1])
