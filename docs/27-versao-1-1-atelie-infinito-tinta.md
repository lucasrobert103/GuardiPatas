# 27 — Versão 1.1: Ateliê, carregamento do Modo Infinito e tinta sem fim

## Modo Infinito

**Antes:**
- A primeira fase levava cerca de 9 segundos para ficar pronta.
- A próxima fase era montada e simulada **escondida enquanto o jogador jogava**, com os efeitos sonoros tocando e física extra rodando ao mesmo tempo.
- Essa simulação escondida sempre perde de propósito (é a prova "sem linha"). Por isso o jogador ouvia o som de derrota no meio da própria partida.

**Agora:**
- **Tela de carregamento:** ao tocar em Começar, Continuar ou Próxima, aparece um cartão com "Fase N", uma barra de progresso, a coelhinha correndo das abelhas e o que está acontecendo:
  - "Escolhendo o cenário…"
  - "Chamando os bichinhos…"
  - "Espalhando os ninhos de insetos…"
  - "Ajeitando pedras e plataformas…"
  - "Deixando tudo prontinho…"
  - "Quase lá!"

  Nenhuma mensagem fala em teste.
- **Não dá para começar antes:** o cartão cobre a tela, os botões ficam desativados e o "voltar" do Android espera terminar. A fase só abre quando está pronta.
- **Rápido:** enquanto prepara, a física roda **8 vezes mais rápido**. O passo continua de 1/60 s, então o resultado é idêntico ao do jogo. Neste computador a fase fica pronta em cerca de 1,5 a 2 s (antes eram cerca de 9 s).
- **Silêncio:** `Sfx.quiet` bloqueia efeitos, sons contínuos e vibração das simulações escondidas.
- **Nada escondido durante a partida:** a preparação em segundo plano foi removida. `InfiniteDirector.halt()` cancela qualquer preparação e devolve física e som ao normal sempre que outra tela abre. Os corações só mudam quando o jogador perde de verdade, um por derrota.
- **Botão novo na tela inicial:** um cartão roxo e rosa com o símbolo ∞ desenhado, uma estrelinha correndo por ele e brilhinhos. Ele mostra o recorde, ou "Continue sua corrida!" com um selo vermelho quando há uma corrida em andamento.

## Tinta nas fases normais

Na campanha, no Desafio do Dia, nas fases do editor e nos treinos, **a tinta nunca acaba**:
- O medidor continua mostrando as marcas de 3, 2 e 1 estrela.
- Gastar mais só diminui as estrelas. Passando do orçamento, a fase vale 1 estrela, e vencer sempre dá pelo menos 1.
- Depois que o medidor esvazia, dá para continuar desenhando à vontade, **sem aviso, som ou cor de alerta**.

O Modo Infinito mantém o limite de tinta como desafio, porque não tem estrelas.

O `strategy_test` foi ajustado. Uma estratégia preguiçosa só conta como atalho se vencer **dentro** do orçamento. Vitórias que estouram a tinta (113% a 382% nas fases 6-2, 7-4, 13-8 e 14-8) são registradas como "venceu só estourando a tinta (1 estrela)".

## Ateliê: pintar e desenhar

O Ateliê abre pelo novo azulejo **Pintar** na tela inicial.

| Ferramenta | Como é |
|---|---|
| Lápis | Traço fino e firme |
| Pincel | Traço redondo do tamanho escolhido |
| Giz | Textura de giz de cera (pontinhos com transparência) |
| Arco-íris | A cor muda suavemente ao longo do traço |
| Brilho | Linha clara com estrelinhas brancas, douradas e coloridas |
| Neon | Brilho em volta, cor viva e miolo branco |
| Spray | Nuvem de gotinhas que acompanha a velocidade do dedo |
| Balde | Pinta a região ao redor do toque. Respeita as linhas do modelo e os traços, sem frestas |
| Borracha | Apaga a pintura e deixa o fundo do modelo aparecer |
| Adesivos | 16 formas fofas (coração, estrela, flor, borboleta, balão, laço, coroa, nuvem, sol, lua, arco-íris, brilho, notinha, patinha, bolinho, folha), **todos os bichinhos** e **todos os insetos** do jogo |

- **Cores e tamanhos:** 22 cores em bolinhas (rolagem por arraste) e 4 tamanhos. As formas usam a cor escolhida, e trocar a cor com um adesivo selecionado muda a cor dele.
- **Adesivos:**
  - toque para colocar;
  - arraste para mover;
  - use − e + para mudar o tamanho;
  - ↔ espelha e ⟳ gira;
  - ✕ apaga.
- **12 modelos:**
  - **para desenhar livre:** papel em branco e caderno de pontinhos;
  - **para colorir:** Capitu, Casinha, Corações, Jardim de flores, Fundo do mar, Arco-íris e Noite estrelada. As linhas ficam **por cima** da pintura, como num livro de colorir;
  - **cenários prontos para enfeitar:** Prado ensolarado, Dia de praia e Montanha de neve.
- **Desfazer e refazer:** cada traço, balde ou adesivo vira uma ação. A cada 40 traços a pintura é achatada numa imagem para continuar leve, e o desfazer volta em blocos até 5 vezes.
- **Apagar tudo:** pede confirmação e mantém o modelo.
- **Salvar no Álbum:** grava a pintura inteira (modelo, pintura e adesivos) em 688×800, com confetes e o aviso "Salva no Álbum!".
- **Ao sair com pintura nova**, o jogo pergunta: Salvar no Álbum, Continuar pintando ou Sair.
- **Continuar de onde parou:** a pintura fica guardada na memória durante a sessão. Voltar ao Ateliê continua de onde parou.

**Como funciona por dentro** (`src/ui/paint_screen.gd`, `src/ui/paint_art.gd`):
- Duas SubViewports. Uma é a pintura, com fundo transparente e os traços como nós. A outra é a composição: fundo do modelo, pintura, linhas do modelo e adesivos.
- A borracha usa um material `blend_disabled` que grava transparência.
- O balde lê a composição em meia resolução e faz um preenchimento por faixas. Depois cria uma imagem da região, com 1 pixel a mais nas bordas, e a coloca na camada de pintura.
- Privacidade: as pinturas ficam só no aparelho, no Álbum do jogo. Os Termos e a Política de Privacidade agora citam as "pinturas do Ateliê".

## Testes

- `tests/v11_test.gd` (29 verificações):
  - tinta sem fim em todos os modos normais, sem aviso, e 1 estrela acima do orçamento;
  - botão novo do Infinito e azulejo Pintar inteiros na tela;
  - Pintar abre o Ateliê e o voltar retorna ao título;
  - carregamento: aparece na hora, bloqueia os botões, fica em silêncio, é acelerado, não fala em teste e ignora o voltar do Android;
  - a fase abre rápido, com som e física normais;
  - nada é preparado durante a partida e os corações ficam intactos;
  - perder tira exatamente 1 coração.
- `tests/paint_test.gd`, com 46 verificações quando há renderização e 39 no CI (sem renderização):
  - layout no celular;
  - todas as ferramentas pelo toque;
  - borracha e desfazer/refazer;
  - modelos e balde dentro do coração, sem vazar;
  - adesivos: colocar, arrastar, + e ↔, bichinhos, insetos e apagar;
  - salvar no Álbum;
  - pergunta ao sair e pintura guardada na sessão.

  Sem placa de vídeo, as conferências de pixel e o balde são pulados.
- Versão **1.1.0** (versionCode 8).
