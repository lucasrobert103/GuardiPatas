# 09 — Arquitetura técnica

Princípios: **simples, modular, orientada a dados, testável headless.** Sem frameworks internos, sem injeção de dependência, sem ECS — nós do Godot + algumas classes com responsabilidade clara.

## Estrutura de pastas
```
project.godot            Configuração (720×1280 retrato, Compatibility, autoloads)
data/levels.json         TODAS as fases (gerado por tools/make_levels.py)
assets/audio/*.wav       Efeitos e músicas (gerados por tools/gen_audio.py)
scenes/main.tscn         Cena raiz (só o script Main)
src/
  autoload/              Singletons globais
    sfx.gd               Áudio: pool de efeitos, loops, música com crossfade, vibração
    level_db.gd          Carrega data/levels.json
    game.gd              Progresso, moedas, dicas, cosméticos, conquistas, ajustes, save
  core/                  Código puro/compartilhado (sem cena)
    layers.gd            Camadas de colisão
    palette.gd           Cores oficiais e paletas dos mundos
    draw_util.gd         Primitivas de desenho com contorno
    line_math.gd         Simplificação/medição do traço (testável)
    scoring.gd           Estrelas e moedas (testável)
    cast.gd              Textos do elenco
  game/                  Jogo
    level.gd             Monta a fase a partir dos dados; máquina de estados
    line_drawer.gd       Entrada de toque + validação + prévia do traço
    drawn_line.gd        Linha física (RigidBody2D de cápsulas)
    animal.gd / animal_art.gd       Bichinho (física) / arte e expressões
    insects/insect.gd + bee, ant, beetle, mosquito, wasp, moth, termite, caterpillar, queen_bee,
            cricket, carpenter_bee, spider, crab, jellyfish, puffer, insect_art
    props/ crate, lamp, water, platform, nest, honey_pot, coconut, wind_zone, goal_zone
    terrain.gd, background.gd, fx.gd
  ui/                    Telas e HUD (construídos em código, tema único)
    main.gd              Roteador de telas + botão voltar do Android
    title_screen, level_select, collection_screen, settings_screen, hud, ui_kit, ui_icon, menu_bg
tests/test_runner.gd     Testes headless (unitários + validação + solubilidade das fases)
tools/                   Geradores de áudio e de fases
.github/workflows/ci.yml CI: importa o projeto e roda os testes com Godot 4.7.2
```

## Responsabilidades
| Área | Onde | Observações |
|---|---|---|
| Gerenciamento de fases | `LevelDB` + `Level` | Dados → nós. Nenhuma fase tem código próprio. |
| Entrada por toque | `Level._unhandled_input` → `LineDrawer` | HUD consome toques antes. |
| Sistema de desenho | `LineDrawer`, `LineMath` | Validação em `_physics_process`. |
| Física e colisões | `DrawnLine`, `Layers`, nós do Godot | Ver doc 07. |
| IA dos insetos | `Insect` + subclasses | `_behave()` por espécie; helpers `_fly_toward`, `_walk_toward`. |
| Bichinhos | `Animal` (+ `AnimalArt`) | Traços de espécie em `SPECIES`. |
| Vitória/derrota | `Level.win/lose` | Sinais `state_changed`, `result_ready`. |
| Pontuação e recompensas | `Scoring` + `Game.complete_level` | Regras puras testadas. |
| Interface e menus | `src/ui/*` | `UiKit` = tema e componentes. |
| Áudio e efeitos | `Sfx`, `Fx` | Partículas desenhadas, sem texturas. |
| Salvamento local | `Game` (JSON em `user://save.json`) | Mescla com padrões → saves antigos continuam válidos. |
| Configurações | `Game.settings` | Música, efeitos, vibração, reduzir movimento, alto contraste. |
| Monetização | **ainda não implementada** (decisão: só após validar diversão) | Interface prevista: `MonetizationService` (doc 11). |

## Fluxo de dados
```
levels.json ──► LevelDB ──► Main._start_level ──► Level.setup/_build ──► nós (Terrain, Animal, Nest, Lamp...)
toque ──► Level._unhandled_input ──► LineDrawer (fila → validação física) ──► stroke_finished ──► DrawnLine
Nest ──► Level.add_insect ──► Insect._behave (consulta Level.nearest_animal / nearest_lit_lamp)
Animal.body_entered(Insect) ──► Level.lose ──► Hud (resultado)      Level.win ──► Game.complete_level ──► save
```

## Formato de fase (`data/levels.json`)
```json
{
  "id": "1-4", "world": 1, "name": "Fila de Formigas", "tip": "texto exibido no início",
  "ink": 600, "survive": 10, "stars": [0.45, 0.7], "strokes": 1,
  "terrain": [{"poly": [[x,y], ...], "style": "ground|stone|wood|glass"}],
  "rocks":   [{"pos": [x,y], "r": 40}],
  "props":   [{"type": "crate|plank", "pos": [x,y], "size": [w,h], "rot": 0},
              {"type": "lamp", "pos": [x,y], "duration": 4},
              {"type": "water", "rect": [x,y,w,h]},
              {"type": "platform", "rect": [x,y,w,h], "travel": [dx,dy], "period": 3},
              {"type": "honey", "pos": [x,y], "amount": 6},
              {"type": "coconut", "pos": [x,y], "drop": 3}],
  "winds":   [{"rect": [x,y,w,h], "dir": [1,0], "force": 700, "on": 2, "off": 2, "delay": 1, "insects": 0.3}],
  "goal":    {"rect": [x,y,w,h]},          // opcional: vence ao levar todos até a toca
  "ink_mode": "static",                    // opcional: Tinta Firme (a linha não cai)
  "underwater": true,                      // opcional: fundo do mar
  "naive":   [[[x,y], ...]],               // opcional: círculo genérico que TEM que perder
  "nodraw":  [[x,y,w,h]],
  "animals": [{"type": "capi|brasa|pingo|nino|tuca|lulu|gelinho|nuvem|kiko|tata|pompom|patinha|fofa|tito", "pos": [x,y], "flip": false}],
  "nests":   [{"insect": "bee|ant|beetle|mosquito|wasp|moth|termite|caterpillar|cricket|broca|spider|crab|jellyfish|puffer", "pos": [x,y], "count": 6, "interval": 0.5, "delay": 0.2, "hole": false}],
  "solution": [[[x,y], ...]]
}
```
`stars`: fração máxima de tinta usada para 3★ e 2★. `solution`: lista de traços (um por `strokes`).

## Decisões arquiteturais (ADRs resumidos)
- **ADR-001 — Godot 4.7 + GDScript.** Ver doc 02.
- **ADR-002 — Arte procedural vetorial.** APK pequeno, animação barata, iteração rápida; trocável por sprites depois sem mexer na física.
- **ADR-003 — Linha = um RigidBody2D composto de cápsulas (≤ 40).** Ver doc 07.
- **ADR-004 — Fases em JSON + gerador.** Sem duplicação de código; testes automáticos de solubilidade.
- **ADR-005 — UI construída em código com `UiKit`.** Tema consistente, sem dezenas de `.tscn` para manter; telas pequenas.
- **ADR-006 — Monetização isolada e tardia.** Nada de SDK de anúncios no protótipo; interface única quando entrar.
- **ADR-007 — Testes headless no CI** com o binário oficial. Fases impossíveis ou triviais quebram o build.

## Expansão prevista
Novo inseto = nova subclasse de `Insect` + `Nest.make_insect` + arte em `InsectArt`. Novo bichinho = entrada em `Animal.SPECIES` + função de desenho + `Cast`. Novo objeto = classe em `props/` + caso em `Level._build_prop`. Tradução: textos de UI estão concentrados nas telas e em `Cast`; próximo passo é extrair para CSV de tradução do Godot.
