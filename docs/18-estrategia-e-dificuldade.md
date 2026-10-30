# Estratégia e dificuldade — 0.4.0

O objetivo desta revisão é eliminar uma receita que resolve a campanha inteira, preservando soluções criativas e a possibilidade de aprender com as tentativas.

## Mudanças de jogo

- As duas primeiras fases continuam introdutórias. Já em 1-3 há ninhos nos apoios, em 1-4 um gargalo para proteger dois amigos e em 1-5 uma travessia até a toca.
- Recursos de pedra têm função: proteger lados, apoiar um teto, bloquear entradas e segurar as pontas contra vento/sucção. Nas fases de apoio, ignorar o ninho deixa nascer um inimigo que perfura a linha.
- Cavernas avançadas têm entradas lateral e superior. O jogador precisa repartir dois traços entre aberturas diferentes.
- Brocas soltas chegam perto mais cedo. É necessário usar duas camadas separadas; as camadas da solução têm distância suficiente para não serem perfuradas ao mesmo tempo.
- Tocas têm afastamentos diferentes, inclusive entre amigos. O raio de um abrigo repetido deixa de servir para todas as fases.
- O mar também tem o **Baiacu-broca**, com silhueta de peixe e ponta de broca. Ele respeita colisões, é resistente à água e usa a mesma mecânica de perfuração anunciada pela broca.
- Brocas contornam o canto superior de pedras quando o caminho direto está bloqueado, em vez de ficarem empurrando a rocha indefinidamente. Elas não atravessam terreno nem ignoram linhas antes de completar a perfuração.
- Vento ascendente dos chefões supera a gravidade, e as pedras de ancoragem ficam além dos pés de um arco comum.
- Permanecem fases com água, plataformas móveis, prioridades de luz/mel, vários bichinhos e rampas com destino. A campanha continua com 63 fases e os 14 bichinhos de física.
- A tinta disponível foi aproximada do custo de uma solução viável, com folga para desenho manual. Isso afeta tinta e estrelas, não aumenta artificialmente a vida dos inimigos.

## Objetivos e dicas

O balão inicial mostra o problema (`objective`). A descrição detalhada (`tip`) e a linha da solução continuam nos dados e nas dicas; o jogador não recebe automaticamente a receita exata no início de cada tentativa. O botão de velocidade 1×/2× permanece disponível após desenhar.

Não adicionamos reconhecimento de formato, derrota automática por desenhar círculo, pontos obrigatórios invisíveis ou validação de semelhança com um desenho único. Um círculo que aproveita corretamente o cenário ainda pode ser uma solução válida. Há testes específicos para impedir que os padrões comuns sejam atalhos nas 54 fases estratégicas marcadas.

Progresso de versões anteriores é mantido. Estrelas já ganhas não são retiradas; o jogador pode rejogar as fases redesenhadas. A versão e o preset Android foram atualizados para 0.4.0 / versionCode 2. Se a Console já tiver um código maior, incrementar antes do próximo envio.

## Testar e editar

Edite as famílias de desafios em `redesign_strategy()` de `tools/make_levels.py`. Os construtores base foram mantidos como templates para as variantes, água e plataformas.

A partir da raiz, com Godot 4.7.2:

```bash
python3 tools/make_levels.py
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
godot --headless --fixed-fps 60 --path . res://tests/strategy_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --daily-all
```

`--world=1` a `--world=8` filtra a avaliação de estratégia. `--audit` apenas relata resultados para investigar desenhos alternativos; o CI roda a versão com asserções, sem esse argumento. O teste usa a mesma ferramenta de desenho, validação de obstáculos, orçamento e física do jogador.

O teste de estratégia cobre seis tentativas por fase: três círculos/elipses, dois arcos comuns e cercas individuais. As cinco tentativas de padrão único geram 270 verificações obrigatórias nas 54 fases estratégicas. Os resultados das demais tentativas são relatados sem reprovar soluções legítimas de tutorial, prioridades ou cenários específicos. Isso não é uma prova matemática contra todos os desenhos ou tamanhos possíveis.

Os testes diários verificam todas as combinações elegíveis. Algumas regras não se aplicam quando tornariam a solução inválida: redução de tinta sem orçamento suficiente, Tinta Firme em plataforma móvel e tempo adicional na prova de brocas livres.

Consulte [a lista atual das fases](08-fases.md). A inspeção desktop e os testes automáticos não substituem uma rodada de balanceamento com jogadores em celulares.

## Resultado da validação

- 410 verificações da campanha aprovadas: soluções, perdas sem desenho, pegadas, progressão, traduções e amostra de dias.
- 270 verificações obrigatórias contra cinco padrões genéricos aprovadas nas 54 fases estratégicas. O relatório também registra alternativas nas demais fases e as tentativas individuais, sem reprovar soluções legítimas.
- 202 combinações de desafios diários aprovadas.
- 40 verificações de fluxo da interface e 37 da velocidade 1×/2× aprovadas.
- 75 scripts compilados sem erros. JSON reproduzido exatamente pelo gerador e `git diff --check` aprovado.
- Renderização desktop inspecionada em 1-3, 2-4, 6-5 e 8-2, antes/depois do desenho, incluindo texto grande e inglês.

Permanecem avisos conhecidos de recursos de áudio no encerramento de algumas suítes. A execução remota do CI e testes em aparelhos Android não foram realizados nesta sessão; uma rodada com jogadores reais continua necessária para ajustar a curva de dificuldade.
