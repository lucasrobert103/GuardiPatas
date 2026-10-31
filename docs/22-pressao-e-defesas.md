# 22 — Insetos mais fortes e defesas exigentes (0.7.0)

A campanha passa a pressionar abrigos soltos, saídas parcialmente cobertas e defesas com poucas camadas. As 63 fases mantêm os identificadores e o progresso existente; moedas, acessórios e animais não são apagados. Android: versão 0.7.0, versionCode 7.

## Força e ritmo

| Ameaça | Antes | Agora |
|---|---|---|
| Abelha | 245 px/s; massa 0,18 | 300 px/s; massa 0,40; direção mais ágil |
| Mosquito | 325 px/s | 390 px/s; maior agilidade para explorar frestas |
| Vespa | Investida 850 px/s; massa 0,36; recuperação 0,9 s | Investida 1050 px/s; massa 0,72; recuperação 0,65 s |
| Besouro | Massa 3,5; impulso 220; empurrão 1100 | Massa 5; impulso 400; empurrão 1600 |
| Caranguejo | Massa 1,4; impulso 145; empurrão 650 | Massa 2,2; impulso 250; empurrão 1000 |
| Broca / baiacu-broca | 220 px/s; 2,2 s de contato por camada | 270 px/s; 1,6 s por camada |
| Grilo | Anda a 80 px/s; intervalo de salto 1,5 s | Anda a 100 px/s; intervalo 1,1 s |
| Aranha | 130 px/s; espera bloqueada 0,5 s | 165 px/s; procura outra descida após 0,35 s |
| Baiacu | 120 px/s; massa 0,5–1,7 | 150 px/s; massa 0,75–2,55 |
| Água-viva | 90 px/s; pulso a cada 0,9 s | 110 px/s; pulso a cada 0,7 s |

Formigas, lagartas e mariposas também se movem mais rápido. Os valores atuais completos estão em [06-insetos.md](06-insetos.md).

Os ninhos recebem `ceil(contagem × 1,4)`, intervalo de saída × 0,72 (mínimo 0,22 s) e espera inicial × 0,8 (mínimo 0,18 s). O gerador limita o total anunciado da fase base a 42 insetos, abaixo do limite simultâneo de 45. O desafio diário Enxame continua acrescentando sua própria regra.

Os avisos permanecem: a vespa mira por 0,7 s e trava a direção nos últimos 0,25 s; o besouro e o caranguejo anunciam o golpe por 0,65 s; o grilo prepara o salto por 0,3 s. As brocas mostram a perfuração. Nenhum movimento desliga colisões com pedra ou teleporta o inseto.

## Saídas e caminhos

Encostar um traço no centro ou em uma lateral da toca já não conta como cobrir toda a boca. Duas consultas físicas, a 12 px de cada lado do centro, verificam a cobertura por tinta ou objeto. Peças diferentes podem cobrir cada lado. Dois pequenos marcadores mostram as partes cobertas em verde, com um risco branco, e as abertas em amarelo; a revisão da tentativa também registra essa informação.

Uma abertura parcial só permite nascer um inseto cujo corpo cabe na saída. As posições candidatas ficam dentro dos 24 px de cada lado da toca, descontando raio do corpo e margem. O jogo verifica tinta, terreno e objetos antes de criar o corpo no mundo; se não houver espaço, o nascimento espera. Isso impede que uma broca apareça além de uma tampa deslocada por poucos pixels.

Quando o mel ou a luz acabam, o alvo lembrado fica próximo da posição da isca. Antes, a posição do inseto no fim da atração podia fazê-lo perseguir outro amigo distante. O pote vazio continua sendo um obstáculo físico; agora a navegação procura seus cantos. Se o enxame bloquear um ponto de passagem e o inseto ficar parado por 0,7 s, ele considera outro caminho, mantendo colisões.

## Fases

- 3-5, 4-5, 5-2 e 6-6 têm três camadas independentes, orçamento correspondente e sobrevivência de 5,4 s. As três precisam contribuir: retirar qualquer camada deve perder.
- 3-6, 4-6, 7-3 e 7-4 recebem pedras que permitem apoiar as defesas contra o impacto maior. Em 4-6, a posição da Tuca e dos apoios deixa espaço para desenhar.
- 4-1 coloca a saída adicional na outra borda da ilha, exigindo uma tampa própria além dos pés do teto.
- 5-5 mantém três abrigos para os seis amigos; suas pontas compartilham a proteção das saídas entre os grupos.
- Em 7-4, o mel dura menos: é necessário considerar o ataque depois da isca.
- As soluções foram ajustadas para cobrir a largura das bocas, com tinta calculada a aproximadamente 90% do orçamento. O jogo continua aceitando qualquer desenho que satisfaça a física e o objetivo.

O gerador é a fonte editável: `python3 tools/make_levels.py`. A [tabela das fases](08-fases.md) apresenta os orçamentos e tempos atualizados.

## Validação

Com Godot 4.7.2, na raiz do projeto:

```bash
python3 tools/make_levels.py
godot --headless --fixed-fps 60 --path . res://tests/check_scripts.tscn
godot --headless --fixed-fps 60 --path . res://tests/insect_tactics_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
godot --headless --fixed-fps 60 --path . res://tests/strategy_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --daily-all
godot --headless --fixed-fps 60 --path . res://tests/replay_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/speed_test.tscn
godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn
```

O teste de pressão usa quatro abelhas contra a mesma barreira livre, com massa 9, sem gravidade e sem rotação, durante 120 passos físicos. Com o perfil anterior, o deslocamento máximo foi 20,88 px; com o atual, 71,38 px. A comparação mede efeito físico, além dos números de configuração.

A suíte estratégica testa oito padrões em todas as 63 fases: três círculos, dois arcos, círculos individuais e dois pares de arcos. Soma ainda 12 omissões obrigatórias das provas de três camadas. Esses padrões devem perder; o código de jogo não reconhece nem proíbe formatos. Isso detecta regressões conhecidas, mas não prova a ausência de todas as soluções alternativas possíveis.

Testes e capturas executados no desktop com Godot 4.7.2, física a 60 passos/s e renderização OpenGL Compatibility/Mesa. A avaliação de dificuldade por jogadores e os testes em aparelhos Android continuam necessários. Algumas suítes mantêm avisos conhecidos de recursos no encerramento; erros de script e falhas de asserção são verificados separadamente.

Resultados locais: 410 verificações da campanha, 516 de padrões genéricos e camadas, 200 combinações diárias, 34 de táticas, 28 da revisão e 37 de velocidade aprovadas; fluxo da interface aprovado e 87 scripts compilados sem erro. Após reposicionar a saída de 4-1, sua solução, os oito padrões negativos e suas quatro regras diárias foram revalidados. Capturas de proteção parcial, três camadas e investida anunciada foram inspecionadas no renderizador real.
