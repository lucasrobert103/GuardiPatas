# 04 — Som e música

Todo o áudio é **sintetizado do zero** por `tools/gen_audio.py` (Python + numpy) — 100 % original, sem licença de terceiros, regenerável e ajustável. Saída: WAV 16 bits mono 22 kHz em `assets/audio/` (o Godot comprime em QOA na importação). Sons contínuos carregam um chunk `smpl` com pontos de loop, que o importador de WAV do Godot lê automaticamente.

## Direção sonora
- **Brinquedo de madeira + sininhos:** marimba, sinos, baixo dedilhado, chocalho. Nada agressivo.
- **Humor cartoon:** "boink" quando um inseto bate na linha, guincho cômico na picada, "wah-wah-wah-waaah" de trombone de brinquedo na derrota.
- **Informação nunca só no som:** cada som tem par visual (X vermelho no bloqueio, "!" da vespa, contador da lâmpada, legenda "Aguente firme!").

## Catálogo
| Arquivo | Quando toca |
|---|---|
| `ui_click`, `ui_back`, `ui_locked` | Botões, voltar, fase trancada |
| `draw_loop` (loop) | Enquanto desenha (giz de cera); volume segue o movimento |
| `draw_end`, `draw_blocked`, `ink_empty` | Soltar o traço, traço bloqueado, tinta acabou |
| `line_land` | Linha pousa no chão (com poeira) |
| `buzz_bee` (loop) | Zumbido de abelhas/vespas; volume cresce com a quantidade |
| `buzz_mosquito`, `moth_flutter` (loops) | Mosquitos, mariposas |
| `wasp_charge`, `wasp_dash` | Vespa mirando e investindo |
| `ant_step`, `beetle_step` | Passinhos |
| `bonk` | Inseto bate na linha; casco da Tuca bloqueia |
| `gasp`, `sting` | Bichinho se assusta; picadinha ("Ai!") |
| `splash` | Inseto levado pela água / bichinho molhado |
| `tick` | Últimos 3 segundos |
| `star1..3`, `coin`, `win`, `unlock`, `pop` | Recompensas e comemoração |
| `lose` | Derrota (após 1 s, sem pressa) |
| `hint` | Dica aparece |
| `music_menu` (92 bpm, 21 s) / `music_level` (112 bpm, 17 s) | Menu e mundo 1 — loop com crossfade |
| `quack`, `baa`, `bloop` | Vozes de susto da Patinha, da Nuvem e da Lulu/Tito (as outras espécies usam `gasp` com tom próprio) |

## Uma trilha por mundo (`world_music()`)
Cada trilha tem 16 compassos (A B A C) e instrumentos próprios, com o mesmo volume médio (`even_loudness`). `Sfx.level_track` escolhe pela fase.

| Trilha | Mundo | Clima | Instrumentos |
|---|---|---|---|
| `music_level` | 1 Jardim | brincalhão, 112 bpm | marimba, sininhos, bateria leve |
| `music_forest` | 2 Floresta | ré dórico, 100 bpm | flauta, harpa (Karplus-Strong), chocalho |
| `music_valley` | 3 Vale das Formigas | faroeste, 120 bpm, swing | violão dedilhado, blocos de madeira "cavalgando" |
| `music_pond` | 4 Lagoa | fá maior, 96 bpm | marimba e bolhinhas |
| `music_camp` | 5 Acampamento | canção de ninar, 84 bpm | caixinha de música, harpa, grilos |
| `music_mountain` | 6 Montanha | mi menor, 108 bpm | glockenspiel, guizos de trenó |
| `music_beach` | 7 Praia | calipso, 116 bpm | steel drum, violão "skank", clave |
| `music_sea` | 8 Mar | sonhador, 80 bpm | colchão de sintetizador, sinos, bolhas |
| `music_boss` | chefões | lá menor harmônico, 132 bpm | quadrada macia, marcha com palmas (animada, não assustadora) |

## Mixagem
Barramentos `Music` e `SFX` (criados em código), volumes ajustáveis em Ajustes; *pool* de 12 players com variação de tom para repetições; intervalo mínimo por som para não "empilhar" 20 bonks no mesmo quadro.
