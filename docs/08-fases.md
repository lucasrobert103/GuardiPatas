# 08 — Campanha: 30 fases em 5 mundos

**Todas as 30 fases estão implementadas** em `data/levels.json`, cada uma com solução registrada verificada pelo teste automático (ver status dos testes no doc 12).
**Estrelas:** o orçamento de tinta é calibrado para a solução registrada usar ~55 %; 3★ exige ≤ 60 %, 2★ ≤ 80 %.
Regra de ouro: **toda solução pode ser deduzida olhando a cena** — ninhos visíveis com contagem, zonas proibidas hachuradas, lâmpada com contador, plataforma com trajeto pontilhado.

## Mundo 1 — Jardim dos Bichinhos (ensina o básico)
| Fase | Cenário | Objetivo / perigos | Mecânica ensinada | Solução válida |
|---|---|---|---|---|
| ✅ 1-1 Oi, Capitu! | Gramado plano, colmeia à direita | Proteger Capitu de 5 abelhas por 6 s | Desenhar, soltar, a linha cai com peso | Arco ("abrigo") sobre a Capitu, pernas quase no chão |
| ✅ 1-2 Zumbido em Dobro | Duas colmeias, uma de cada lado | 8 abelhas de duas direções, 8 s | Abrigo fechado protege de todos os lados | Mesmo arco, bem fechado |
| ✅ 1-3 Brasa, a Curiosa | Colmeia à esquerda | 6 abelhas, 8 s; Brasa é alta | Bichinhos têm tamanhos diferentes | Arco alto e estreito |
| ✅ 1-4 Fila de Formigas | Formigueiro à esquerda, Capitu à direita | 6 formigas pelo chão, 10 s | Inseto andarilho; parede em vez de teto | Tenda "Λ" íngreme entre o formigueiro e a Capitu (gasta pouca tinta → 3★) |
| ✅ 1-5 Bolinha de Espinhos | Colmeia + formigueiro | 4 abelhas + 4 formigas, 9 s | Dois tipos de inseto juntos | Arco sobre o Pingo (resolve os dois) |
| ✅ 1-6 Lá no Alto | Galho de madeira no alto | 6 abelhas, 8 s; galho estreito | Precisão: a linha tem que pousar na plataforma | Arco pequeno cujas pernas pousam no galho |

## Mundo 2 — Floresta Encantada (frestas, luz, vários bichinhos)
| Fase | Cenário | Objetivo / perigos | Mecânica | Solução |
|---|---|---|---|---|
| ✅ 2-1 Zizi, o Mosquito | Clareira | 7 mosquitos, 8 s | Inseto que acha qualquer fresta | Arco totalmente fechado no chão |
| ✅ 2-2 Luz da Lanterna | Lanterna (4 s) à esquerda | 5 mariposas, 10 s | Isca de luz e tempo visível | Arco sobre a Brasa antes de a luz apagar |
| ✅ 2-3 Dois Amigos | Capitu e Nino lado a lado | 7 abelhas, 8 s | Vários bichinhos | Um arco largo sobre os dois |
| ✅ 2-4 Caixa Amiga | Caixa de madeira ao lado | 6 abelhas, 8 s | Objetos físicos economizam tinta | Arco sobre a Capitu; ou meia-água apoiada na caixa (3★) |
| ✅ 2-5 Duas Linhas | Pedra separa Capitu e Pingo | 8 abelhas, 9 s; **2 traços** | Mais de um traço; botão "Pronto!" | Um arco para cada |
| ✅ 2-6 Zona Proibida | Faixa listrada acima da Brasa | 8 abelhas de dois lados, 9 s | Espaço limitado para desenhar | Arco baixinho abaixo da zona |

## Mundo 3 — Vale das Formigas (abismos, empurrões, objetos móveis)
| Fase | Cenário | Objetivo / perigos | Mecânica | Solução |
|---|---|---|---|---|
| ✅ 3-1 Bolota Teimosa | Chão plano | 2 besouros pela esquerda | Inseto que empurra | Arco largo (mais tinta = mais peso) |
| ✅ 3-2 Ponte Sobre o Nada | Abismo entre formigueiro e Capitu | 8 formigas + 4 abelhas | Abismos param andarilhos | Não desenhar ponte! Só um arco contra as abelhas |
| ✅ 3-3 Ladeira do Pingo | Rampa de 15° terminando num laguinho | Pingo rola quando a simulação começa; 5 abelhas | Física do bichinho | Arco apoiado na própria rampa: segura o Pingo e o protege |
| ✅ 3-4 Elevador de Folha | Plataforma que desce e sobe | 6 abelhas; Nino sobre a plataforma | Objetos móveis | Arco apoiado na própria plataforma (move junto) |
| ✅ 3-5 Roque-Roque | Duas caixas empilhadas formam parede | 3 cupins roem a madeira + 4 formigas | Barreiras frágeis | Arco de tinta sobre a Capitu (a madeira vai cair) |
| ✅ 3-6 Formigueiro Gigante | Dois formigueiros + besouro | 14 formigas + 1 besouro, 12 s | Revisão do mundo | Arco largo (pesado) sobre a Capitu |

## Mundo 4 — Lagoa Misteriosa (água, novos amigos, vespas)
| Fase | Cenário | Objetivo / perigos | Mecânica | Solução |
|---|---|---|---|---|
| ✅ 4-1 Bolhas da Lulu | Lulu numa ilhota de pedra no meio da lagoa | 10 formigas (a água as leva) + 5 abelhas | Água leva insetos embora | Arco pequeno sobre a Lulu, na ilhota |
| ✅ 4-2 Vovó Tuca | Tuca no gramado | 6 abelhas; tinta curta | Casco aguenta 1 picada | Arco baixo e largo (o casco perdoa uma brecha) |
| ✅ 4-3 Faísca! | Vespeiro no alto à esquerda | 2 vespas | Investida telegrafada ("!") | Arco firme e mais largo (mais pesado) |
| ✅ 4-4 Fosso Protetor | Fosso com água entre o formigueiro e a Capitu | 10 formigas + 5 abelhas | Usar o cenário a favor | Arco contra as abelhas; o fosso leva as formigas |
| ✅ 4-5 Lagarta Gulosa | Gramado | 2 lagartas + 5 formigas | Inseto que escala paredes | A tenda que barrava formigas não basta: arco fechado |
| ✅ 4-6 Ilhas Amigas | Brasa na margem esquerda, Lulu na ilhota, Tuca na direita | 6 mosquitos + 1 vespa, 3 traços | Vários bichinhos e traços | Um arco para cada |

## Mundo 5 — Acampamento no Quintal (noite, luz e combinações)
| Fase | Cenário | Objetivo / perigos | Mecânica | Solução |
|---|---|---|---|---|
| ✅ 5-1 Noite de Lanternas | Lanternas de 3 s (esq.) e 7 s (dir.) | 6 mariposas, 11 s | Iscas e tempo | Só o Nino precisa de abrigo: as mariposas ficam na lanterna que dura mais e depois vão ao bichinho mais perto dela (3★ com pouca tinta) |
| ✅ 5-2 Fogueira de Brinquedo | Duas caixas soltas | 5 abelhas + 1 besouro empurrando | Objetos + empurrão | Arco largo sobre a Capitu |
| ✅ 5-3 Carrossel de Tábua | Plataforma que vai e volta na horizontal | 9 abelhas de dois lados | Plataforma horizontal | Arco sobre a Brasa, apoiado na plataforma |
| ✅ 5-4 Pouca Tinta | Bloco de pedra alto ao lado da Capitu; tinta curtíssima | 6 mosquitos | Economia extrema | Meia-água do topo do bloco até o chão (o arco completo não cabe) |
| ✅ 5-5 Todos Juntos | Os seis bichinhos | 8 abelhas + 5 mosquitos, 3 traços, 12 s | Revisão geral | Três arcos agrupando os amigos de dois em dois |
| ✅ 5-6 Rainha Zumbina | Duas colmeias + a Rainha pairando | Rajadas de vento a cada 3,2 s + 12 abelhas, 14 s | Batalha especial sem violência | Arco sobre a Capitu entre as duas pedras, que o travam contra as rajadas |

## Como criar uma fase nova
1. Adicione uma chamada `L(...)` em `tools/make_levels.py` (funções `ground`, `block`, `animal`, `hive`, `mound`, `dome_over`, `tent`).
2. Rode `python3 tools/make_levels.py` → atualiza `data/levels.json`.
3. Rode os testes (`--level=ID` para só ela). O teste exige: **a solução vence** e **sem linha perde**.
4. Ajuste `stars` para que a solução "esperta" dê 3★ e a "bruta" dê 1–2★.
