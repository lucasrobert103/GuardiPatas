# 10 — Progressão, recompensas e acessibilidade

## Progressão (implementada)
- **Fases em sequência:** vencer libera a próxima. Mundos aparecem no mapa conforme as fases existem. **Nenhuma barreira de estrelas ou pagamento** para avançar.
- **Estrelas (1–3) por economia de tinta**, com as metas visíveis na barra antes de desenhar. Vencer sempre dá pelo menos 1★.
- **Moedas:** +10 por estrela nova, +3 por vitória, +5 no primeiro 3★. Repetir uma fase já perfeita dá só +3 → sem incentivo a "farmar".
- **Amigos:** cada bichinho salvo pela primeira vez entra na Coleção com ficha e história.
- **Guarda-roupa:** 9 acessórios cosméticos (60–250 moedas: boné, laço, óculos, chapéu de palha, presilha estrela-do-mar, coroa de flores, cachecol, touca, coroa dourada) para qualquer bichinho conhecido.
- **Modo Livre:** depois de vencer uma fase (ganhar estrela), o botão **Livre** dá **tinta infinita** para o jogador fazer o que quiser, sem mexer nas estrelas.
- **Conquistas: 39**, em `Game.ACHIEVEMENT_LIST` (condições em `_achievement_checks()`):
  - vitórias (1, 10, 50) e sequências sem perder (5, 15);
  - estrelas (10, 30, 60, 100, 150) e fases perfeitas (5, 15, 30);
  - economia (≤ 25 % e ≤ 15 % da tinta);
  - um troféu por mundo (8) e a Rainha Zumbina;
  - amigos (6, 10, 14 bichinhos);
  - guarda-roupa (equipar, 3 itens, todos) e cofrinho (500 moedas);
  - mecânicas novas: **Tampa-Buracos** (5 buracos tampados), **Entrega Fofa** (3 tocas), **Artista Livre** (vencer no Modo Livre);
  - persistência: dica, 100/500 linhas, tentar de novo 10/50 vezes.
- **Dicas opcionais:** começa com 3; trocar 40 moedas por +1. A dica mostra a solução tracejada animada. **Paga uma vez por fase na sessão** (recomeçar não cobra de novo). Disponível também na tela de derrota.

## Abertura
Ao abrir o app aparece uma abertura retrô (estilo synthwave, ~3,6 s, toque para pular) com **"desenvolvido por RetroNexa — retronexa.com.br"** e jingle próprio (`src/ui/splash_screen.gd`). O site não pôde ser consultado daqui (bloqueado pela política de rede do ambiente), então a abertura usa só o nome e o endereço.

<img src="img/abertura.png" width="200">

## Ética de design (anti-manipulação)
- Sem vidas/energia, sem tempo de espera, sem roleta, sem caixas surpresa, sem contagem regressiva de ofertas.
- Sem "quase ganhou, pague para continuar".
- Moedas só se ganham jogando (enquanto não houver loja); preços sempre visíveis; nada aleatório.
- Mensagens de derrota **ensinam** (ex.: "os insetos deslizam pela linha até achar uma brecha").

## Acessibilidade (implementada)
| Recurso | Como |
|---|---|
| Cores distinguíveis | Perigo/proteção/vitória também diferem em forma; insetos com padrões |
| Alto contraste | Anel vermelho em volta de cada inseto (Ajustes) |
| Reduzir movimento | Sem tremor de câmera, menos partículas, sem pulos amplos |
| Sem dependência de áudio | Todo som tem equivalente visual; legenda do cronômetro |
| Textos legíveis | ≥ 21 px na resolução de projeto, contorno em todo texto sobre cenário |
| Controles simples | Um gesto; botões ≥ 84 px; toque acidental curto é ignorado |
| Volumes separados | Música e efeitos; vibração opcional |
| Pausa automática | Ao minimizar o app |

## Próximos passos de acessibilidade
Modo "sem cronômetro visível" (só barra), tamanho de texto ajustável, tradução EN/ES, suporte a leitor de tela nos menus (AccessKit no Godot 4.5+).
