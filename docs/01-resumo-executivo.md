# 01 — Resumo executivo

## O jogo em uma frase
**GuardiPatas** é um puzzle de física 2D para Android em que você desenha **uma linha com o dedo** para proteger bichinhos fofos de insetos travessos — e torce para a sua engenhoca aguentar até o cronômetro zerar.

## Conceito
- **Loop de 30 segundos:** olhar a cena → planejar → desenhar → soltar o dedo (a física começa, os insetos saem) → aguentar 6–12 s → comemoração, estrelas e moedas → próxima fase (ou "De novo!" em menos de 1 s).
- **Fácil de aprender:** um gesto só. **Difícil de dominar:** cada inseto tem uma regra física diferente, a linha tem peso e cai, e as estrelas premiam quem usa **pouca tinta**.
- **Humor sem violência:** ninguém se machuca. Uma picada vira "Ai!" com bochecha vermelha e estrelinhas girando; na vitória os insetos desistem e vão embora (ou tiram um cochilo).

## Público
- **Todas as idades** (classificação alvo: Livre/PEGI 3). Núcleo: famílias, crianças de 6+ com responsáveis, adultos casuais que gostam de puzzles curtos.
- **Mercado inicial:** Brasil (textos em português, aparelhos modestos), com estrutura pronta para tradução.

## Diferenciais
1. **Elenco próprio e memorável:** Capitu (capivara com laranjinha na cabeça), Brasa (raposa tagarela), Pingo (ouriço que vira bolinha e rola), Nino (esquilo leve como pluma), Tuca (tartaruga-vovó cujo casco aguenta uma picada) e Lulu (axolote que vive no aquário). **Cada um muda a física da fase.**
2. **Insetos com regras, não só perseguidores:** formigas andam e não sobem paredes; besouros empurram; mosquitos acham frestas; vespas avisam ("!") e investem; mariposas seguem a luz; cupins roem madeira; lagartas escalam a sua linha.
3. **Justiça verificável:** toda fase tem uma solução registrada que um **teste automático** desenha e simula com a física real; e também é testado que, sem linha, a fase é perdida. Nada de fase impossível ou trivial.
4. **Monetização gentil:** jogo completo sem pagar; sem anúncios durante a tentativa; nada de loot box.
5. **Leve:** arte vetorial desenhada por código e áudio sintetizado → APK pequeno, roda em celular de entrada.

## Decisão técnica
**Godot 4.7.2 + GDScript**, renderizador Compatibility, AAB via Gradle, API alvo 36. Justificativa completa em [02-pesquisa-tecnologica.md](02-pesquisa-tecnologica.md).

## Estado atual (esta entrega)
- Documentação de design completa (este diretório).
- **Jogo jogável**: 63 fases em 8 mundos, 4 chefões, Desafio do Dia, medalhas, Casinha, Álbum, editor de fases, português/inglês/espanhol, 14 bichinhos (cada um com seu susto), 14 criaturas com IA + chefona, mecânicas de estratégia (buracos, Tinta Firme, tocas, mel, coco, vento), Modo Livre, 39 conquistas, abertura RetroNexa, desenho por toque validado, física, vitória/derrota, estrelas, moedas, dicas, guarda-roupa, conquistas, ajustes de acessibilidade, salvamento, efeitos sonoros e músicas sintetizados.
- Ver o que foi testado e o que falta em [12-plano-de-desenvolvimento.md](12-plano-de-desenvolvimento.md).
