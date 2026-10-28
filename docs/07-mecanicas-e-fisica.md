# 07 — Mecânicas principais e regras de física

## Ciclo de uma tentativa
```
DESENHANDO ──(solta o dedo / acabou os traços / "Pronto!")──► RODANDO ──(cronômetro = 0)──► VENCEU
                                                                │
                                                                └─(picada / queda / água)──► PERDEU
```
- Em **DESENHANDO** tudo está congelado (`RigidBody2D.freeze = true`): bichinhos, caixas, plataformas, e os insetos ainda não existem. O jogador planeja com calma.
- Ao começar a **simulação**, os ninhos liberam insetos e o cronômetro "Aguente firme!" conta `survive` segundos (6–12). Últimos 3 s com tique sonoro.
- **Reinício instantâneo**: botão sempre visível; recria a fase em 1 quadro (sem transição).

## Sistema de desenho (`src/game/line_drawer.gd`)
1. **Captura:** eventos de mouse emulados a partir do toque (`emulate_mouse_from_touch`), convertidos para coordenadas do mundo com `make_input_local`. Botões do HUD consomem o toque antes do jogo (`_unhandled_input`).
2. **Buffer → física:** posições vão para uma fila e são validadas em `_physics_process` (forma segura de consultar o espaço físico).
3. **Validação de cada passo** (círculo de raio = meia espessura + 3 px de folga):
   - dentro dos limites da área desenhável e fora das **zonas proibidas** (hachuradas em vermelho);
   - `intersect_shape` no ponto: não pode estar dentro de terreno, bichinho, caixa ou outra linha;
   - se o dedo entra num obstáculo, o ponto é **empurrado para a posição livre mais próxima** (busca em anéis de 3 a 18 px): o traço **contorna/abraça** o bichinho ou o terreno em vez de parar — perdoa a imprecisão do dedo;
   - `cast_motion` do último ponto ao novo (com raio 2,5 px menor, para permitir contornar corpos convexos): se algo estiver no caminho, o traço **para encostado** no obstáculo (nunca atravessa), com um X vermelho e som de bloqueio.
   - Movimentos rápidos são subdivididos em passos de 18 px (sem "pular" paredes finas).
4. **Orçamento de tinta:** cada pixel desenhado consome tinta; o último segmento é cortado no limite. Barra com marcas de 3★/2★; som e vibração quando acaba.
5. **Toque acidental:** traços < 24 px são descartados e a tinta devolvida.
6. **Ao soltar:** `LineMath.prepare_stroke` aplica Ramer–Douglas–Peucker (ε = 1,5 px), funde pontos a < 10 px e **limita a 40 segmentos** (aumenta ε se preciso). Sem suavização de cantos (ela poderia aproximar a linha de um obstáculo já validado).

## A linha como objeto físico (decisão ADR-003)
Avaliadas três abordagens:

| Abordagem | Prós | Contras | Veredito |
|---|---|---|---|
| Barreira estática permanente | 100 % estável, simples | Sem física → puzzles rasos; "parede mágica" no ar | ❌ (usada só como variação futura "tinta de pedra") |
| Corrente de corpos ligados por juntas | Linha "mole", visual vivo | Juntas no GodotPhysics2D podem vibrar/explodir; dezenas de corpos | ❌ |
| **Um único `RigidBody2D` composto por cápsulas** | Estável, barato, com peso e queda; nº de formas limitado | A linha é rígida (não dobra) | ✅ **escolhida** |

Parâmetros: espessura 14 px; uma `CapsuleShape2D` por segmento (altura = comprimento + espessura, cantos arredondados → sem quinas que prendem); **massa = 0,01 × comprimento** (0,8–9 kg) → linhas longas são mais fortes contra empurrões, mas gastam tinta (tensão com as estrelas); atrito 0,9; quique 0,05; **CCD por forma**; amortecimento angular 0,8. A cápsula raio 7 + folga de validação 3 px garante que a linha nasce sem sobreposição.

## Mecânicas de estratégia (mundos 3–8)
Para que "um círculo em volta de todo mundo" **não resolva tudo**, cada fase nova tem uma regra que pune a solução genérica. O teste automático guarda essa solução ingênua (`naive`) e **exige que ela perca** em 24 fases.

| Mecânica | Como funciona | O que pede do jogador |
|---|---|---|
| **Buracos / tocas** | Formigas e caranguejos saem de buracos no chão; uma linha ou caixa a ≤ 10 px do buraco **tampa** | Desenhar com as **pontas em cima dos buracos** — um círculo folgado deixa os buracos dentro |
| **Abelha Broca** | Fura a linha após 2,2 s encostada | **Parede dupla** (dois traços) |
| **Grilo / Aranha** | Pulam por cima ou descem do teto | Abrigo com teto |
| **Tinta Firme** (`ink_mode: static`) | A linha não cai: fica parada onde foi desenhada (cor azul) | Construir **rampas, tobogãs e portinhas** |
| **Toca de destino** (`goal`) | Vence quando todos os bichinhos ficam 0,35 s dentro da toca; perde se o tempo acabar | Levar Tatá/Gelinho/Pingo **rolando ou escorregando** até a toca |
| **Pote de mel** | Abelhas e vespas vão primeiro ao mel; quando acaba, atacam quem estiver **mais perto do pote** | Descobrir quem está em perigo de verdade |
| **Coco que cai** | Cai do coqueiro (trajeto pontilhado); se acertar um bichinho, "bonk!" e perde | Abrigo **firme** que aguente o impacto |
| **Vento / correnteza** | Zona que empurra linhas e caixas (100 %) e insetos (fração configurável) | **Travar** o abrigo em pedras/paredes |
| **Tinta apertada** | Orçamento abaixo do necessário para o círculo | Usar o cenário como parede |

## Modo Livre (tinta infinita)
Em fase **já vencida**, o botão **Livre** (canto inferior esquerdo) liga a tinta infinita (barra arco-íris "∞") e até 20 traços: o jogador desenha o que quiser só por diversão. Vitórias no Modo Livre **não mudam estrelas nem moedas**, mas contam para a conquista "Artista Livre".

## Física geral
- 60 ticks/s, **20 iterações** do solver, interpolação de física ligada (suave em 90/120 Hz).
- Camadas (`src/core/layers.gd`): terreno · linha · bichinho · voador · andarilho · objeto · ninho. Voadores colidem entre si (enxame faz pressão); andarilhos **não** colidem entre si (fila fluida, sem pilhas instáveis); voadores e andarilhos se ignoram.
- **Teto de 45 insetos** por fase; insetos que saem da área são removidos.
- **Detecção de picada:** `contact_monitor` no bichinho (`body_entered`) — só conta durante RODANDO.
- **Derrota por queda:** bichinho abaixo de y = 1360. **Derrota por água:** bichinho que não nada entra na água.

## Prevenção de exploits e bugs
| Risco | Prevenção |
|---|---|
| Desenhar dentro do bichinho/terreno para "prender" | Validação por forma + cast; folga de 3 px |
| Linha atravessando parede fina com movimento rápido | Subdivisão em passos de 18 px + cast |
| Centenas de colisores | Máx. 40 cápsulas por traço; um corpo por traço |
| Tunelamento de insetos rápidos | CCD na linha e na vespa; espessura mínima 14 px |
| Rabisco infinito | Orçamento de tinta |
| Desenhar fora da tela | Área desenhável limitada (`bounds`) |
| Fase "resolvida" sem desenhar | Teste automático exige derrota sem linha |
| Fase "resolvida" com o círculo genérico | Teste automático exige derrota da solução ingênua (`naive`) |
| Fase impossível | Teste automático exige vitória com a solução registrada |
| App minimizado no meio da fase | Pausa automática (`NOTIFICATION_APPLICATION_PAUSED`) |

## Resoluções e proporções
Resolução de projeto 720×1280 (retrato), `stretch = canvas_items`, `aspect = expand`: em telas mais altas (20:9) ou mais largas (tablets) aparece **mais cenário**, nunca barras pretas, e a área de jogo continua inteira e centralizada. O terreno de cada fase se estende além da área de projeto. HUD ancorado nas bordas.
