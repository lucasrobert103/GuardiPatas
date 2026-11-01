# Versão 0.9 — rolagem, botões acessíveis, pausa ilustrada, prévias e dificuldade

Revisão em 01/11/2026. Branch `ccr-69427eab-1v26vu`.

## Rolagem arrastando em qualquer lugar
- `src/ui/drag_scroll.gd` (`DragScroll.attach(scroll)`) em todas as listas (Loja, Ajustes, Coleção, Criar, Álbum, editor, Casinha).
- Funciona com dedo **e mouse**, começa em qualquer ponto (inclusive em cima de um botão) e tem inércia. Passado o limiar de 14 px, o botão tocado é cancelado (não dispara). Toque curto continua sendo clique.
- A barra de rolagem fica escondida.
- Teste: `tests/scroll_test.tscn` (arrastar em botão rola e não aperta; toque curto clica; Loja e Ajustes rolam).

## Botões longe da borda de baixo
- No Android a faixa de gestos "come" toques colados na borda. `UiKit.GESTURE_GAP` (64 px) + área segura do aparelho (`UiKit.safe_insets` / `UiKit.keep_safe`) agora valem para editor, Criar, Loja, Coleção, Mapa, Álbum, Ajustes e Casinha.
- No editor, em telas baixas a câmera desce para o chão aparecer acima da doca.
- `editor_visual_test` confere 5 proporções: doca fora da faixa de gestos e chão visível acima dela.

## Pausa ilustrada
- A pausa mostra uma cena desenhada: os bichinhos e os insetos da fase cochilando sob a lua ("Z z" subindo). Tocar num bichinho faz ele pular.
- Três botões redondos com desenho (Recomeçar, Continuar, Mapa), a dica da fase e interruptores desenhados de Música e Sons (nota/alto-falante riscados quando desligados).

## Prévia antes de comprar
- `src/ui/product_preview.gd`: toda compra (moedas do jogo ou dinheiro) abre antes uma prévia grande e animada: bichinho com o efeito dele, pacote com os bichinhos, acessório/efeito vestido num bichinho à escolha (setas), pilha de moedas, lista "O que vem" e preço.
- Na Loja, o "Comprar" da prévia leva à Área dos responsáveis; no guarda-roupa e nos efeitos, compra com moedas. Se faltar moeda, a prévia abre e mostra quanto falta.
- Testes: `store_test` (prévia não compra; "Comprar" pede o responsável; efeito continua ao trocar de bichinho) e `flow_test` (guarda-roupa).

## Dificuldade
- `src/core/difficulty.gd`: **Normal**, **Difícil** (padrão; +30% insetos, saídas 15% mais rápidas, insetos 15% mais velozes, +25% moedas) e **Extremo** (+60%, 25%, 30%, +50% moedas). Troca no mapa (botão com chama) ou em Ajustes → Desafio.
- Vale para as 83 fases da campanha (não muda Desafio do Dia, editor nem Modo Livre).
- Verificação: `test_runner.tscn -- --difficulty=1` e `--difficulty=2` (no CI). Fases em que a solução registrada não aguentaria ficam limitadas (`Difficulty.CAPS`): 10-2 em Normal; 9-9 e 10-7 até Difícil.

## Abertura RetroNexa para outros projetos
Pacote independente (Godot 4, sem dependências do GuardiPatas) entregue no chat: `addons/retronexa_splash/` com o script, a cena, o desenho do Pingo, fontes Inter (OFL), sons e um LEIA-ME; mais o vídeo MP4 com som.
