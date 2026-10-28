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
| `music_menu` (92 bpm, 21 s) / `music_level` (112 bpm, 17 s) | Músicas em loop com crossfade |

## Mixagem
Barramentos `Music` e `SFX` (criados em código), volumes ajustáveis em Ajustes; *pool* de 12 players com variação de tom para repetições; intervalo mínimo por som para não "empilhar" 20 bonks no mesmo quadro.
