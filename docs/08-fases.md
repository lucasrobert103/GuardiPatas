# 08 — Campanha de estratégia (versão 0.6.0)

A campanha mantém 63 fases em oito mundos. A fonte editável é `tools/make_levels.py`; `python3 tools/make_levels.py` gera `data/levels.json`. A versão 0.6 mantém o progresso anterior e acrescenta táticas aos desafios sem apagar moedas, animais ou acessórios.

Todas as fases exigem planejar o desenho e ler o cenário. O jogador encontra problemas de apoios, bloqueio de nascimentos, rotas, camadas e distribuição de traços. Não há detecção nem proibição de círculos: uma solução diferente continua válida quando satisfaz a física e o objetivo.

A mensagem inicial usa `objective`, sem mostrar a receita do traço. O código de dados mantém `tip` e `solution` para dicas e validação automatizada.

## Mundo 1 — Jardim dos Bichinhos

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 1-1 | Oi, Capitu! | Aprender o desenho e a física | 2 | 265 | 10 s |
| 1-2 | Zumbido em Dobro | Aprender o desenho e a física | 3 | 425 | 9 s |
| 1-3 | Telhado para Brasa | Tampar ninhos e apoiar um teto | 2 | 200 | 8 s |
| 1-4 | Gargalo das Formigas | Proteger dois amigos no gargalo | 2 | 315 | 10 s |
| 1-5 | Rampa do Pingo | Construir uma rota até a toca | 1 | 395 | 10 s |
| 1-6 | Ponte de Folhas | Tampar ninhos e apoiar um teto | 2 | 190 | 8 s |

## Mundo 2 — Floresta Encantada

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 2-1 | Porta da Floresta | Usar a caverna e fechar a passagem | 2 | 195 | 8 s |
| 2-2 | Escolha à Luz | Ler as luzes e priorizar o alvo | 2 | 240 | 11 s |
| 2-3 | Teto Compartilhado | Tampar ninhos e apoiar um teto | 2 | 370 | 8 s |
| 2-4 | Parede Amiga | Fechar o ninho e aproveitar o paredão | 2 | 465 | 8 s |
| 2-5 | Apoios Separados | Tampar ninhos e apoiar um teto | 3 | 425 | 9 s |
| 2-6 | Telhado Baixinho | Fechar o ninho e aproveitar o paredão | 2 | 440 | 9 s |

## Mundo 3 — Vale das Formigas

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 3-1 | Apoio na Rocha | Fechar o ninho e aproveitar o paredão | 2 | 465 | 11 s |
| 3-2 | Ponte sobre a Entrada | Tampar ninhos e apoiar um teto | 2 | 265 | 10 s |
| 3-3 | Travessia do Pingo | Construir uma rota até a toca | 1 | 395 | 10 s |
| 3-4 | Elevador de Folha | Acompanhar uma plataforma móvel | 2 | 240 | 9 s |
| 3-5 | Duas Barreiras | Separar duas barreiras contra as brocas | 3 | 780 | 5.0 s |
| 3-6 | Formigueiro Gigante | Ajustar o abrigo às posições das tocas | 2 | 500 | 12 s |

## Mundo 4 — Lagoa Misteriosa

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 4-1 | Bolhas da Lulu | Usar água, ilhas e fechar nascimentos | 2 | 250 | 10 s |
| 4-2 | Telhado da Tuca | Tampar ninhos e apoiar um teto | 2 | 240 | 9 s |
| 4-3 | Recanto da Brasa | Fechar o ninho e aproveitar o paredão | 2 | 440 | 9 s |
| 4-4 | Parede do Lago | Fechar o ninho e aproveitar o paredão | 2 | 465 | 10 s |
| 4-5 | Camadas de Proteção | Separar duas barreiras contra as brocas | 3 | 780 | 5.0 s |
| 4-6 | Ilhas Amigas | Usar água, ilhas e fechar nascimentos | 3 | 760 | 10 s |

## Mundo 5 — Acampamento no Quintal

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 5-1 | Noite de Lanternas | Ler as luzes e priorizar o alvo | 2 | 240 | 11 s |
| 5-2 | Brocas no Acampamento | Separar duas barreiras contra as brocas | 3 | 780 | 5.0 s |
| 5-3 | Carrossel de Tábua | Acompanhar uma plataforma móvel | 2 | 350 | 10 s |
| 5-4 | Pouca Tinta | Fechar o ninho e aproveitar o paredão | 2 | 360 | 9 s |
| 5-5 | Todos Juntos | Agrupar os amigos e bloquear ninhos internos | 3 | 1035 | 12 s |
| 5-6 | Rainha Zumbina | Ancorar sob pedras contra forças que levantam a linha | 1 | 540 | 14 s |

## Mundo 6 — Montanha Gelada

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 6-1 | Tobogã de Boas-vindas | Construir uma rota até a toca | 1 | 480 | 9 s |
| 6-2 | Buracos na Neve | Ajustar o abrigo às posições das tocas | 2 | 500 | 9 s |
| 6-3 | Porta da Montanha | Dividir traços entre teto e entrada lateral | 3 | 315 | 11 s |
| 6-4 | Rumo à Toca do Tatá | Construir uma rota até a toca | 1 | 455 | 10 s |
| 6-5 | Entrada da Caverna | Dividir traços entre teto e entrada lateral | 3 | 315 | 10 s |
| 6-6 | Abelha Broca | Separar duas barreiras contra as brocas | 3 | 780 | 5.0 s |
| 6-7 | Abrigo no Paredão | Fechar o ninho e aproveitar o paredão | 2 | 425 | 10 s |
| 6-8 | Tobogã do Gelinho | Construir uma rota até a toca | 1 | 480 | 9 s |
| 6-9 | Abrigo na Rocha | Fechar o ninho e aproveitar o paredão | 2 | 295 | 9 s |
| 6-10 | Pico Nevado | Ajustar o abrigo às posições das tocas | 3 | 910 | 10 s |
| 6-11 | Coruja Nevasca | Ancorar sob pedras contra forças que levantam a linha | 1 | 510 | 13 s |

## Mundo 7 — Praia do Sol

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 7-1 | Esconderijo do Pompom | Dividir traços entre teto e entrada lateral | 3 | 315 | 8 s |
| 7-2 | Telhado da Praia | Tampar ninhos e apoiar um teto | 2 | 190 | 8 s |
| 7-3 | Vespas na Praia | Ajustar o abrigo às posições das tocas | 2 | 430 | 9 s |
| 7-4 | Piquenique | Ler a isca de mel e priorizar o alvo | 2 | 240 | 10 s |
| 7-5 | Apoio da Fofa | Fechar o ninho e aproveitar o paredão | 2 | 435 | 11 s |
| 7-6 | Telhado Inclinado | Fechar o ninho e aproveitar o paredão | 2 | 420 | 9 s |
| 7-7 | Toca no Rochedo | Ajustar o abrigo às posições das tocas | 2 | 125 | 9 s |
| 7-8 | Rumo ao Guarda-Sol | Construir uma rota até a toca | 1 | 395 | 10 s |
| 7-9 | Coco e Caranguejo | Ajustar o abrigo às posições das tocas | 2 | 430 | 9 s |
| 7-10 | Festa na Praia | Ajustar o abrigo às posições das tocas | 3 | 780 | 10 s |
| 7-11 | Caranguejo Rei | Ajustar o abrigo às posições das tocas | 2 | 475 | 12 s |

## Mundo 8 — Fundo do Mar

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 8-1 | Telhado do Tito | Tampar ninhos e apoiar um teto | 2 | 195 | 10 s |
| 8-2 | Porta Submarina | Dividir traços entre teto e entrada lateral | 3 | 315 | 10 s |
| 8-3 | Caranguejos do Fundo | Ajustar o abrigo às posições das tocas | 2 | 515 | 10 s |
| 8-4 | Apoio de Coral | Fechar o ninho e aproveitar o paredão | 2 | 395 | 11 s |
| 8-5 | Toca do Polvo | Tampar ninhos e apoiar um teto | 1 | 190 | 10 s |
| 8-6 | Recanto Submarino | Fechar o ninho e aproveitar o paredão | 2 | 385 | 11 s |
| 8-7 | Meia-água no Recife | Fechar o ninho e aproveitar o paredão | 2 | 435 | 11 s |
| 8-8 | Polvo e Caranguejo | Ajustar o abrigo às posições das tocas | 2 | 440 | 10 s |
| 8-9 | Correnteza Forte | Apoiar a linha contra a correnteza | 1 | 465 | 11 s |
| 8-10 | Rei dos Mares | Ajustar o abrigo às posições das tocas | 3 | 720 | 11 s |
| 8-11 | Polvo Gigante | Ancorar sob pedras contra forças que levantam a linha | 1 | 465 | 12 s |

## Critérios de validação

- Toda fase precisa vencer com a solução registrada e perder sem desenho.
- A solução precisa continuar coletando a Pegada Dourada; traços retos de dois pontos também são suportados.
- `strategy_test.tscn` tenta três círculos/elipses de tamanhos diferentes e dois arcos genéricos em todas as fases. Nas 54 fases marcadas com `strategy_required`, esses cinco padrões devem perder.
- O teste também registra tentativas de cercas individuais; elas são soluções adaptadas a cada animal e não são proibidas automaticamente.
- Tutorial, priorização, água e plataformas podem aceitar outros abrigos válidos. O critério não é copiar a solução registrada, e sim impedir que uma receita única resolva a campanha inteira.
- Desafios diários só sorteiam redução de tinta quando a solução base cabe com margem. Hora Extra não é sorteada para a prova de duas camadas com brocas livres. As combinações disponíveis são testadas com `--daily-all`.

## Ondas táticas da versão 0.5

A geometria, tinta, tempo e soluções desta tabela são mantidos. As ameaças agora procuram passagens e alternam entre alvos expostos, respeitando as iscas. Cinco fases recebem combinações adicionais:

| Fase | Combinação |
|---|---|
| 4-2 | Mosquitos e brocas nos apoios, mais lagartas escaladoras |
| 6-2 | Brocas nas tocas e grilos com salto preparado |
| 6-7 | Mosquitos, broca no apoio e aranhas que tentam outra descida |
| 7-3 | Brocas nas tocas e vespas com investida anunciada |
| 7-6 | Mosquitos, broca no apoio e caranguejos com golpe de pressão |

Veja [as táticas e sua validação](19-insetos-taticas.md).
