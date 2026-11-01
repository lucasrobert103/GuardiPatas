# Versão 1.0 — Modo Infinito, mundos 11–14, missões, tutoriais e petiscos

Revisão em 01/11/2026. Branch `ccr-69427eab-1v26vu`.

## Números contínuos
- A campanha é numerada sem parar: **Fase 1, 2, 3… 123** no mapa, no topo da fase e nas fotos.
- O mapa mostra "Fases 84 a 93 · 36 de 123 fases vencidas · Missões X/369"; a tela inicial mostra "Próxima: Fase N · X de 123 vencidas"; a vitória mostra "Fases vencidas: X de 123" e comemora a cada 10.

## Modo Infinito
- Botão "Modo Infinito · Recorde N" na tela inicial.
- Fases geradas sem parar a partir de uma semente (`src/core/infinite.gd`), usando os moldes da campanha: arco, buracos ao lado, gruta com tampa, abrigo travado em pedras e dois amigos. Cada molde traz a própria solução.
- **Antes de aparecer, a fase é simulada escondida** (`InfiniteValidator`, num mundo de física separado): a solução tem que vencer e, sem linha, a fase tem que ser perdida. Se falhar, outra variação é sorteada (`InfiniteDirector`). A próxima fase é preparada enquanto você joga a atual.
- Fica mais difícil a cada fase: mais insetos, saídas mais rápidas, tinta mais justa e insetos novos liberados aos poucos (vespas, moscas, joaninhas, ninjas, libélulas, brocas, cigarras, pulgões, tatus…).
- 3 corações por corrida; recorde salvo; moedas por fase e um **baú a cada 5 fases** (+40 moedas e petiscos).
- Teste `tests/infinite_test.tscn`: 30 fases seguidas, todas entregues com solução e "sem linha perde"; gerador determinístico; dificuldade crescente; corações e recorde.

## Mundos novos (83 → 123 fases)
| Mundo | Novidade |
|---|---|
| 11 · Cidade dos Brinquedos | Trenzinho que passa e empurra tudo no trilho; blocos de montar que caem (pontilhado avisa) e ficam no cenário |
| 12 · Nuvens Altas | Sem chão: nuvens que afundam com peso; vento que muda de lado; Lua pendurada |
| 13 · Deserto das Dunas | Areia movediça que puxa a tinta; tempestade de areia que esconde parte da tela; oásis; **Rainha Térmita** (chefona que abre túneis com aviso) |
| 14 · Castelo Assombrado | Lanternas que piscam no ritmo; **Boo**, o fantasminha que atravessa tinta comum (só a Tinta Firme e a luz o seguram) |

Todas as 40 fases foram validadas (solução vence, sem linha perde) nas três dificuldades. 11-6, 11-9, 13-8 e 14-8 não têm atalho genérico e estão marcadas como estratégia obrigatória.

## Bichinhos novos
Bolota (porquinho-da-índia, anda de lado de nervoso), Plim (canguruzinho, pula de susto), Duda (girafinha altíssima), Nhoque (caracol: aguenta duas picadas, escorrega) e Lua (morceguinho que dorme pendurada no teto).

## Insetos novos
Joaninha Mamãe (solta filhotes), Besouro-tatu (rola e quebra a tinta), Mosquito-Ninja (fica quase invisível), Pulgão Cola (gruda e pesa), Libélula Relâmpago (arrancada em zigue-zague), Boo (atravessa tinta comum) e a chefona Rainha Térmita. Todos com aviso visível antes do poder.

## Tutorial jogável
Na primeira fase em que um inseto aparece, um cartão mostra uma **demonstração ao vivo** (o mesmo motor de física, numa janelinha) e oferece **Treinar** (fase curtinha com tinta de sobra) ou **Jogar**. O cartão não volta depois de visto.

## Missões extras
3 por fase (369 no total), sempre cumpríveis: usar até X% da tinta (calculado pela solução registrada), vencer no Difícil/Extremo (quando a fase aguenta) ou de primeira, e vencer sem dica. Cada uma dá +10 moedas; aparecem na vitória e no mapa.

## Casinha
- **Petiscos** ganhos a cada vitória (mais estrelas, mais petiscos): biscoito, morango, picolé e bolinho. O pote na cozinha mostra quantos você tem; dar um petisco enche barriguinha e carinho.
- **Banho de bolhas**: mini-jogo de 15 s no banheiro. Estoure bolhas (as douradas valem 3, combos dão bônus); limpa e dá carinho; moedas pelo placar.

## Testes
`features_test` (tutorial, treino vencível para cada inseto, demonstrações de todos os insetos, missões, petiscos, bolhas, numeração) e `infinite_test` entram no CI junto com os anteriores.
