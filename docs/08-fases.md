# 08 — Campanha de estratégia (versão 0.5.0)

A campanha mantém 63 fases em oito mundos. A fonte editável é `tools/make_levels.py`; `python3 tools/make_levels.py` gera `data/levels.json`. A versão 0.5 mantém o progresso anterior e acrescenta táticas aos desafios sem apagar moedas, animais ou acessórios.

As duas primeiras fases ensinam a desenhar. A partir da terceira, o jogador encontra problemas de apoios, bloqueio de nascimentos, rotas, camadas e distribuição de traços. Não há detecção nem proibição de círculos: uma solução diferente continua válida quando satisfaz a física e o objetivo.

A mensagem inicial usa `objective`, sem mostrar a receita do traço. O código de dados mantém `tip` e `solution` para dicas e validação automatizada.

## Mundo 1 — Jardim dos Bichinhos

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 1-1 | Oi, Capitu! | Aprender o desenho e a física | 1 | 380 | 6 s |
| 1-2 | Zumbido em Dobro | Aprender o desenho e a física | 1 | 380 | 8 s |
| 1-3 | Telhado para Brasa | Tampar ninhos e apoiar um teto | 1 | 175 | 8 s |
| 1-4 | Gargalo das Formigas | Proteger dois amigos no gargalo | 1 | 310 | 10 s |
| 1-5 | Rampa do Pingo | Construir uma rota até a toca | 1 | 445 | 10 s |
| 1-6 | Ponte de Folhas | Tampar ninhos e apoiar um teto | 1 | 165 | 8 s |

## Mundo 2 — Floresta Encantada

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 2-1 | Porta da Floresta | Usar a caverna e fechar a passagem | 1 | 175 | 8 s |
| 2-2 | Escolha à Luz | Ler as luzes e priorizar o alvo | 1 | 220 | 11 s |
| 2-3 | Teto Compartilhado | Tampar ninhos e apoiar um teto | 1 | 370 | 8 s |
| 2-4 | Parede Amiga | Fechar o ninho e aproveitar o paredão | 1 | 475 | 8 s |
| 2-5 | Apoios Separados | Tampar ninhos e apoiar um teto | 2 | 430 | 9 s |
| 2-6 | Telhado Baixinho | Fechar o ninho e aproveitar o paredão | 1 | 450 | 9 s |

## Mundo 3 — Vale das Formigas

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 3-1 | Apoio na Rocha | Fechar o ninho e aproveitar o paredão | 1 | 445 | 11 s |
| 3-2 | Ponte sobre a Entrada | Tampar ninhos e apoiar um teto | 1 | 235 | 10 s |
| 3-3 | Travessia do Pingo | Construir uma rota até a toca | 1 | 415 | 10 s |
| 3-4 | Elevador de Folha | Acompanhar uma plataforma móvel | 1 | 205 | 9 s |
| 3-5 | Duas Barreiras | Separar duas barreiras contra as brocas | 2 | 770 | 5 s |
| 3-6 | Formigueiro Gigante | Ajustar o abrigo às posições das tocas | 1 | 485 | 12 s |

## Mundo 4 — Lagoa Misteriosa

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 4-1 | Bolhas da Lulu | Usar água, ilhas e fechar nascimentos | 1 | 220 | 10 s |
| 4-2 | Telhado da Tuca | Tampar ninhos e apoiar um teto | 1 | 210 | 9 s |
| 4-3 | Recanto da Brasa | Fechar o ninho e aproveitar o paredão | 1 | 420 | 9 s |
| 4-4 | Parede do Lago | Fechar o ninho e aproveitar o paredão | 1 | 445 | 10 s |
| 4-5 | Camadas de Proteção | Separar duas barreiras contra as brocas | 2 | 770 | 5 s |
| 4-6 | Ilhas Amigas | Usar água, ilhas e fechar nascimentos | 3 | 795 | 10 s |

## Mundo 5 — Acampamento no Quintal

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 5-1 | Noite de Lanternas | Ler as luzes e priorizar o alvo | 1 | 205 | 11 s |
| 5-2 | Brocas no Acampamento | Separar duas barreiras contra as brocas | 2 | 770 | 5 s |
| 5-3 | Carrossel de Tábua | Acompanhar uma plataforma móvel | 1 | 325 | 10 s |
| 5-4 | Pouca Tinta | Fechar o ninho e aproveitar o paredão | 1 | 335 | 9 s |
| 5-5 | Todos Juntos | Agrupar os amigos e bloquear ninhos internos | 3 | 1080 | 12 s |
| 5-6 | Rainha Zumbina | Ancorar sob pedras contra forças que levantam a linha | 1 | 565 | 14 s |

## Mundo 6 — Montanha Gelada

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 6-1 | Tobogã de Boas-vindas | Construir uma rota até a toca | 1 | 500 | 9 s |
| 6-2 | Buracos na Neve | Ajustar o abrigo às posições das tocas | 1 | 480 | 9 s |
| 6-3 | Porta da Montanha | Dividir traços entre teto e entrada lateral | 2 | 290 | 11 s |
| 6-4 | Rumo à Toca do Tatá | Construir uma rota até a toca | 1 | 475 | 10 s |
| 6-5 | Entrada da Caverna | Dividir traços entre teto e entrada lateral | 2 | 290 | 10 s |
| 6-6 | Abelha Broca | Separar duas barreiras contra as brocas | 2 | 770 | 5 s |
| 6-7 | Abrigo no Paredão | Fechar o ninho e aproveitar o paredão | 1 | 400 | 10 s |
| 6-8 | Tobogã do Gelinho | Construir uma rota até a toca | 1 | 500 | 9 s |
| 6-9 | Abrigo na Rocha | Fechar o ninho e aproveitar o paredão | 1 | 265 | 9 s |
| 6-10 | Pico Nevado | Ajustar o abrigo às posições das tocas | 2 | 910 | 10 s |
| 6-11 | Coruja Nevasca | Ancorar sob pedras contra forças que levantam a linha | 1 | 535 | 13 s |

## Mundo 7 — Praia do Sol

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 7-1 | Esconderijo do Pompom | Dividir traços entre teto e entrada lateral | 2 | 290 | 8 s |
| 7-2 | Telhado da Praia | Tampar ninhos e apoiar um teto | 1 | 155 | 8 s |
| 7-3 | Vespas na Praia | Ajustar o abrigo às posições das tocas | 1 | 405 | 9 s |
| 7-4 | Piquenique | Ler a isca de mel e priorizar o alvo | 1 | 205 | 10 s |
| 7-5 | Apoio da Fofa | Fechar o ninho e aproveitar o paredão | 1 | 415 | 11 s |
| 7-6 | Telhado Inclinado | Fechar o ninho e aproveitar o paredão | 1 | 400 | 9 s |
| 7-7 | Toca no Rochedo | Ajustar o abrigo às posições das tocas | 1 | 90 | 9 s |
| 7-8 | Rumo ao Guarda-Sol | Construir uma rota até a toca | 1 | 415 | 10 s |
| 7-9 | Coco e Caranguejo | Ajustar o abrigo às posições das tocas | 1 | 405 | 9 s |
| 7-10 | Festa na Praia | Ajustar o abrigo às posições das tocas | 2 | 775 | 10 s |
| 7-11 | Caranguejo Rei | Ajustar o abrigo às posições das tocas | 1 | 455 | 12 s |

## Mundo 8 — Fundo do Mar

| Fase | Nome | Problema principal | Traços | Tinta | Tempo simulado |
|---|---|---|---:|---:|---:|
| 8-1 | Telhado do Tito | Tampar ninhos e apoiar um teto | 1 | 160 | 10 s |
| 8-2 | Porta Submarina | Dividir traços entre teto e entrada lateral | 2 | 290 | 10 s |
| 8-3 | Caranguejos do Fundo | Ajustar o abrigo às posições das tocas | 1 | 495 | 10 s |
| 8-4 | Apoio de Coral | Fechar o ninho e aproveitar o paredão | 1 | 370 | 11 s |
| 8-5 | Toca do Polvo | Tampar ninhos e apoiar um teto | 1 | 200 | 10 s |
| 8-6 | Recanto Submarino | Fechar o ninho e aproveitar o paredão | 1 | 365 | 11 s |
| 8-7 | Meia-água no Recife | Fechar o ninho e aproveitar o paredão | 1 | 415 | 11 s |
| 8-8 | Polvo e Caranguejo | Ajustar o abrigo às posições das tocas | 1 | 420 | 10 s |
| 8-9 | Correnteza Forte | Apoiar a linha contra a correnteza | 1 | 230 | 11 s |
| 8-10 | Rei dos Mares | Ajustar o abrigo às posições das tocas | 2 | 715 | 11 s |
| 8-11 | Polvo Gigante | Ancorar sob pedras contra forças que levantam a linha | 1 | 485 | 12 s |

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
