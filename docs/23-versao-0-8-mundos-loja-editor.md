# Versão 0.8 — editor refeito, tela inicial, 2 mundos, 6 insetos, 3 bichinhos e loja cheia

Revisão em 31/10/2026. Branch `ccr-69427eab-1v26vu`.

## O que estava quebrado e foi corrigido

A integração anterior trouxe versões antigas de `insect.gd`, `nest.gd` e `insect_art.gd` (sem o `InsectNavigator`) e telas que chamavam membros inexistentes: **11 scripts não compilavam** e o jogo não abria. O código voltou ao último estado estável (`a3fbb97`, 410 verificações aprovadas) e tudo abaixo foi refeito por cima dele.

## Editor de fases ("Criar")

- **Causa real dos botões sumindo:** a câmera da fase desloca o desenho em celulares mais altos que 16:9 (a maioria hoje: 19,5:9, 20:9). A barra de ferramentas ficava no mesmo canvas da fase e era empurrada para fora da tela. Agora a interface do editor fica numa `CanvasLayer` própria, presa à **área segura** do aparelho (entalhe e barra de gestos).
- Botões dividem a largura disponível e cortam o texto com reticências: nunca empurram a tela.
- **Bichinho** abre uma grade com **todos os 17 bichinhos** do jogo; **Inseto** abre uma grade com **todos os 21 insetos/criaturas** (com descrição do poder ao escolher).
- Andarilhos podem sair de formigueiro ou de **buraco no chão** (opção no seletor).
- Tocar num ninho já posto muda a quantidade (2 · 3 · 4 · 6 · 8 · 10); tocar num bichinho o vira de lado.
- **Desfazer** (até 40 passos), **Limpar** com confirmação, **renomear** a fase, contadores de limite (bichinhos 4, ninhos 5, pedras 6, blocos 6), tempo até 15 s e até 3 traços.
- Blocos empilham; apagar o bloco de baixo faz os de cima (e os bichinhos) descerem.
- Teste novo `tests/editor_visual_test.tscn`: 5 proporções de tela (720×1280, 720×1600, 720×1100, 960×1280, 600×1280), todos os botões inteiros na tela, toques reais na GUI, seletores completos, desfazer/limpar/empilhar.

## Tela inicial

- Um botão **Jogar** e quatro atalhos (Desafio, Bichinhos, Casinha, Criar). Ajustes no canto; a **Loja** fica no contador de moedas (com "+").
- A turma fica num morrinho sob um escudo de tinta; uma abelha e uma vespa rondam e **batem no escudo**, que pisca.
- Na trilha de grama embaixo, **bichinhos passam andando** — às vezes correndo de uma abelha. Tocar em qualquer bichinho faz ele pular.
- Layout distribuído entre o logo e a trilha em qualquer proporção; respeita "Reduzir movimento".

## Novos insetos (cada um com um poder, sempre com aviso visível)

| Inseto | Poder | Como se defender |
|---|---|---|
| **Vagalume Pisca** | Brilha e deixa os insetos a até 170 px **35% mais rápidos** (halo amarelo neles) | Abrigo sem frestas |
| **Mosca Gêmea** | Na 1ª batida na tinta **vira duas mosquinhas** menores e mais rápidas | Nada de frestas |
| **Cigarra Cantora** | Carrega o canto (anéis + "!") e solta uma **onda que empurra** linhas e caixas soltas | Tinta Firme ou abrigo travado em pedras |
| **Besouro Pum-Pum** | Mira de longe (arco pontilhado) e **lança fumaça em arco** — "Bonk!" | Telhado |
| **Louva-a-deus Garra** | Agarra a linha e a **levanta e segura** para passar por baixo; pula pedras (com aviso) | Pés do abrigo sob pedras, Tinta Firme |
| **Formiga Tesoura** | Encostada na tinta por 1,3 s, **corta** e passa | Tampar a saída, camadas, pedra |

## Novos bichinhos

- **Zeca** (sapo, nada), **Mel** (ursinha grande e pesada, abrigo alto) e **Fiapo** (bicho-preguiça comprido, aguenta uma picadinha). Arte, susto, acessórios, fichas na Coleção e traduções.

## 20 fases novas e difíceis (63 → 83)

- **Mundo 9 — Bosque dos Vagalumes** (noite, árvores e vagalumes) e **Mundo 10 — Vulcão Fumegante** (lava e fumaça), 10 fases cada, incluindo as chefonas Rainha da Noite e Coração do Vulcão.
- Ondas pesadas, tinta justa (a solução usa ~90%), buracos de saída ao lado dos bichinhos, grutas e crateras estreitas, abrigos travados em pedras e até 3 camadas.
- **10 fases sem nenhum atalho genérico** (círculos, arcos e arcos duplos perdem): 9-4, 9-6, 9-7, 9-8, 9-9, 10-2, 10-3, 10-5, 10-7 e 10-10 — marcadas `strategy_required` e verificadas pelo CI.
- Os mundos 9–10 ficam **fora do sorteio do Desafio do Dia** (`no_daily`): as regras extras do desafio foram calibradas para as 63 fases da campanha principal.

## Loja cheia

Abas **Destaques · Moedas · Bichinhos · Efeitos**. 18 produtos:

- Destaques: Kit Boas-vindas, **Turma Mágica** (4 bichinhos mágicos + 1.000 moedas), **Baú Supremo** (tudo + 5.000 moedas + 20 dicas), **Pata Dourada** (dobro de moedas para sempre).
- Moedas: 300 · 900 · 2.000 · 5.000 · 12.000 e Lâmpada de 10 dicas.
- Bichinhos: **4 bichinhos mágicos com efeito especial próprio** — Faísca (dragãozinho, Chama Mágica), Lumi (unicórnio, Arco-íris), Cometa (gatinho galáctico, Poeira de Estrelas), Pipoca (hamster dourada, Brilho Dourado) — além de Amora, Bambu e Gotinha.
- Efeitos: **8 efeitos especiais** (Folhinhas, Neve, Bolhas, Corações, Brilho, Estrelas, Chama Mágica, Arco-íris) comprados com moedas do jogo ou no Pacote de Efeitos, e usados em qualquer bichinho (também pelo guarda-roupa da Coleção).
- Nada disso muda a dificuldade das fases (bichinhos da loja vivem na Casinha; efeitos são só visuais). A Pata Dourada só multiplica moedas.
- Toda compra com dinheiro passa pela Área dos responsáveis.

## Compras com dinheiro de verdade: o que já está pronto e o que falta

**Pronto no código** (`src/autoload/play_billing.gd`): adaptador para o plugin Android *GodotGooglePlayBilling* (API 1.x/2.x). Ele conecta, busca os preços reais no Google Play, abre a compra, recupera compras não finalizadas, envia o token ao **seu servidor de verificação**, só entrega depois do "ok" do servidor e então consome (moedas) ou reconhece (direitos). Entrega idempotente por número do pedido. Sem plugin ou sem servidor, **falha fechado**: nada é cobrado nem entregue e a loja mostra "Compras indisponíveis neste aparelho".

**Ainda NÃO foi testado num aparelho com produtos reais.** Para ligar:

1. Instalar o plugin GodotGooglePlayBilling compatível com Godot 4.7 no export Android e ativar a permissão de Internet no preset (`permissions/internet`, hoje `false`).
2. Criar no Play Console os 18 IDs de produto (os mesmos de `Store.PRODUCTS`): moedas e dicas como **consumíveis**; bichinhos, pacotes, efeitos e Pata Dourada como **não consumíveis**.
3. Publicar um servidor que receba `{product, token, order_id}`, confira a compra na **Google Play Developer API** (pacote, produto, estado, não reembolsada) e responda `{"ok": true, "product": "<id>"}`. Nunca colocar credenciais da conta de serviço no app.
4. Definir a URL em `Project Settings → guardipatas/billing/verify_url`.
5. Testar com *license testers* no track interno: aprovada, recusada, pendente, cancelada, sem conexão, reinstalação.
6. Rever os requisitos de Famílias, Data safety e a política de privacidade antes de publicar (doc 16).

## Traduções

Todos os textos de tela estão em PT/EN/ES (0 sem tradução de 758). A tabela `tools/i18n_table.py` agora também contém as linhas que antes existiam só no CSV, então `python3 tools/i18n.py build` não perde mais traduções.

## Como testar

```bash
godot --headless --path . --import
godot --headless --path . res://tests/check_scripts.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn
godot --headless --path . res://tests/editor_visual_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/strategy_test.tscn
# capturas (precisa de tela virtual):
xvfb-run godot --path . --rendering-driver opengl3 res://tests/ui_shots.tscn -- --screen=editor --size=720x1600 --picker=animal --out=/tmp/editor.png
```
