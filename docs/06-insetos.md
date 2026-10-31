# 06 — Insetos e ameaças

**Regras de justiça (valem para todos):**
1. O ninho de onde o inseto sai **é visível** e mostra **quantos** ainda vão sair (`x5`).
2. Velocidade de referência fixa e comportamento determinado pelas regras abaixo — **nenhum sorteio decide a fase**. O único ruído é um zigue-zague estético.
3. Todo inseto tem **uma forma clara de ser bloqueado**, deduzível pela aparência.
4. Ninguém morre: no fim da fase eles **desistem** (voam embora / cochilam); a água os **leva boiando**.

Implementação: `src/game/insects/*.gd` (base `Insect`, comportamento em `_behave()`).

| # | Nome | Velocidade de referência | Movimento | Ponto forte | Limitação | Como bloquear | Estado |
|---|---|---|---|---|---|---|---|
| 1 | **Abelha Zumbi** | 245 px/s | Procura desvios em cantos/pontas; prefere alvos expostos e mantém o alvo sem oscilar | Insistente; contorna | Empurra pouco (massa 0,18); respeita mel | Abrigo fechado e apoiado | ✅ |
| 2 | **Formiga Tilim** | 108 px/s | Anda em fila; sobe degraus ≤ 18 px e rampas suaves; não colide com as colegas | Grupo mais rápido | Não voa, não sobe paredes íngremes, não nada | Parede íngreme, vala, água | ✅ |
| 3 | **Besouro Bolota** | 68 px/s | Empurra e prepara um golpe de 0,65 s contra barreiras soltas | Massa 3,5; impulso no ponto de contato | Lento, não escala; intervalo entre golpes | Barreira travada no terreno ou Tinta Firme | ✅ |
| 4 | **Mosquito Zizi** | 325 px/s | Voo mais preciso, busca frestas e desvios com folga para o corpo de 14 px | Explora entradas pequenas | Quase não empurra (massa 0,05) | Abrigo sem frestas | ✅ |
| 5 | **Vespa Faísca** | 215 px/s + investida 850 px/s | Mira por 0,7 s com direção pontilhada; trava nos últimos 0,25 s; recupera por 0,9 s | Impacto forte e antecipação do movimento | Anuncia a direção e não corrige durante a investida | Barreira apoiada e previsão do ângulo | ✅ |
| 6 | **Mariposa Lumi** | 165 px/s | Contorna obstáculos até a lâmpada e orbita; ao apagar persegue o amigo próximo dali | Muda de prioridade com a luz | Respeita a isca, é leve | Proteger para o fim da luz | ✅ |
| 7 | **Cupim Roque-Roque** | 55 px/s | Vai até a **caixa/tábua de madeira** mais próxima (até 420 px) e a rói: rachaduras aparecem e ela quebra após 1,6 s de roída acumulada | Destrói barreiras de madeira | Não afeta a linha de tinta nem pedra | Não confiar só em madeira; abrigo de tinta | ✅ |
| 8 | **Lagarta Gulosa** | 50 px/s | Anda e sobe paredes, caixas e linhas | Escala mais rápido | Lenta, não voa; água a leva | Abrigo fechado ou água | ✅ |

| 9 | **Grilo Saltitante** | 80 px/s + pulo | Prepara salto por 0,3 s perto de parede, beirada ou alvo elevado; mostra trajetória | Supera paredes baixas | Não fura; precisa de chão para saltar | Abrigo com teto ou vão largo | ✅ |
| 10 | **Abelha Broca** | 220 px/s | Perfura um corpo de traço após 2,2 s de contato acumulado; anel mostra progresso | Atravessa uma camada | Cada traço exige nova perfuração; não fura pedra | Duas camadas separadas ou tampar ninho | ✅ |
| 11 | **Aranha Fiandeira** | 130 px/s | Anuncia a descida; se bloqueada, recolhe o fio e tenta outra lateral | Procura outra entrada | Move-se fisicamente; teto e laterais impedem passagem | Teto com laterais protegidas | ✅ |
| 12 | **Caranguejo Belisco** | 92 px/s | Anda de lado e prepara golpe anunciado de 0,65 s | Pressiona tinta solta; resiste à água | Lento, não voa; intervalo entre golpes | Tampar tocas e travar barreiras | ✅ |
| 13 | **Água-viva Gelatina** | pulsos a cada 0,9 s | Segue desvio e antecipa um pouco o movimento do alvo | Pulsos direcionados, sem ângulo sorteado | Leve, lenta, desviada pela correnteza | Abrigo sem frestas | ✅ |
| 14 | **Baiacu Bolha** | 120 px/s | Infla perto do alvo ou ao pressionar tinta/madeira (raio 13 → 27) | Empurra e mantém a pressão | Crescimento não atravessa tinta; pode murchar | Abrigo espaçoso e apoiado | ✅ |

<img src="img/criaturas.png" width="420">

**Ninhos e tocas:** colmeia, formigueiro, teia, coral e **buraco/toca** (14 tipos de ninho). Um buraco **tampado** por linha ou caixa (raio 10 px) não solta mais ninguém — aparece "Tampado!".

### Chefona (sem violência) ✅
**Rainha Zumbina** — abelha-rainha gigante (fase 5-6) que **não pica**: paira indo de um lado ao outro e, a cada 3,2 s, **infla as bochechas** (aviso de 1 s com "!") e **sopra** uma rajada que empurra linhas, caixas e bichinhos para longe dela (e deixa as operárias tontas). Vence-se aguentando 14 s com um abrigo travado entre duas pedras. (Implementação: `src/game/insects/queen_bee.gd`.)

### Chefões dos mundos 6–8 ✅ (`src/game/insects/boss.gd`)
Todos avisam 1 s antes de agir (ícone "!" piscando + marcação na tela) e ninguém se machuca:
- **Coruja Nevasca** (6-11): pousada num galho, levanta as asas e derruba **bolas de neve** nos **X** marcados no chão (perto do bichinho, alternando dois lados / centro). Neve que acerta o bichinho = "Bonk de neve!". As bolas de neve ficam numa camada própria de colisão: não "atiram" abelhas através da linha.
- **Caranguejo Rei** (7-11): anda de lado na areia, levanta a garra mostrando o **arco pontilhado** e arremessa uma **concha** no bichinho mais perto. Os caranguejinhos saem das tocas.
- **Polvo Gigante** (8-11): incha (aviso) e por 1,4 s **suga** linhas e caixas na direção dele (insetos sentem só um pouco); depois solta uma nuvem de tinta, só visual. Se um bichinho chegar até ele: "Abraço apertado!". Bloqueio justo: passar as pontas do abrigo por baixo das pedras.

### Progressão da dificuldade
Mundo 1: abelha → formiga → abelha+formiga. Mundo 2: mosquito, mariposa+luz, vários bichinhos, dois traços. Mundo 3: besouro, abismos, plataformas móveis, cupim. Mundo 4: água, Lulu e Tuca, vespa, lagarta. Mundo 5: noite, lâmpadas como isca, combinações e chefão. Mundo 6 (Montanha): buracos, grilos, aranha, abelha broca, vento, Tinta Firme. Mundo 7 (Praia): caranguejos nas tocas, coco caindo, isca de mel, vespas. Mundo 8 (Mar): águas-vivas, baiacus, correnteza, caranguejos do fundo.

## Baiacu-broca (campanha 0.4)

Aparece em tocas no coral e nos apoios submarinos. Tem corpo de baiacu com uma ponta de broca, resiste à água e perfura cada corpo de linha após 2,2 segundos de contato acumulado, como a abelha-broca. Pedras continuam bloqueando-o. A resposta estratégica é tampar a saída no apoio ou usar camadas independentes e espaçadas. A toca mostra o símbolo de broca antes do início da simulação.

Abelhas-broca e baiacus-broca contornam o canto superior das pedras quando a rota direta está bloqueada. O movimento continua físico, com velocidade limitada: não teleportam nem atravessam terreno.

## Revisão 0.5

As velocidades acima são referências de controle; impulsos e forças externas continuam fazendo parte da física. As cinco ondas adicionadas à campanha, detalhes dos avisos, memória das iscas e testes físicos estão em [Insetos com novas táticas](19-insetos-taticas.md).
