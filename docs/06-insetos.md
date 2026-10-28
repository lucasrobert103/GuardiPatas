# 06 — Insetos e ameaças

**Regras de justiça (valem para todos):**
1. O ninho de onde o inseto sai **é visível** e mostra **quantos** ainda vão sair (`x5`).
2. Velocidade máxima fixa e comportamento determinado pelas regras abaixo — **nenhum sorteio decide a fase**. O único ruído é um zigue-zague estético.
3. Todo inseto tem **uma forma clara de ser bloqueado**, deduzível pela aparência.
4. Ninguém morre: no fim da fase eles **desistem** (voam embora / cochilam); a água os **leva boiando**.

Implementação: `src/game/insects/*.gd` (base `Insect`, comportamento em `_behave()`).

| # | Nome | Velocidade | Movimento | Ponto forte | Limitação | Como bloquear | Estado |
|---|---|---|---|---|---|---|---|
| 1 | **Abelha Zumbi** | 230 px/s | Voa direto ao bichinho mais próximo, com zigue-zague; ao ser segurada, **desliza pela barreira** procurando brecha | Insistente; contorna | Empurra pouco (massa 0,15) | Abrigo fechado e apoiado | ✅ |
| 2 | **Formiga Tilim** | 95 px/s | Anda em **fila** pelo chão; sobe **degraus ≤ 18 px** e rampas suaves; não colide com as colegas | Vem em grupo, contorna obstáculos baixos | Não voa, não sobe paredes íngremes, não nada | Parede "Λ" íngreme, vala, água | ✅ |
| 3 | **Besouro Bolota** | 60 px/s | Anda pelo chão e **empurra** (força até 1100) | Desloca linhas leves e caixas | Lento, não escala, não voa | Barreira **pesada** (mais tinta) ou travada no terreno | ✅ |
| 4 | **Mosquito Zizi** | 300 px/s | Voo rápido e errático; desliza forte procurando fresta | Passa por qualquer brecha > 14 px | Quase não empurra (massa 0,05) | Abrigo **sem frestas** | ✅ |
| 5 | **Vespa Faísca** | 200 px/s + investida 820 px/s | Aproxima-se até 260 px, **mira 0,7 s com "!" piscando** e investe em linha reta; depois fica tonta 0,9 s | Impacto forte, empurra a linha | Telegrafa o ataque; após a investida fica vulnerável | Barreira apoiada no chão / pesada; prever o ângulo pelo "!" | ✅ |
| 6 | **Mariposa Lumi** | 150 px/s | **Orbita a lâmpada acesa** mais próxima; quando apaga (contador visível), vai devagar ao bichinho | Muda de alvo | Lenta, fraca | Proteger para o momento em que a luz apagar; usar a luz como isca | ✅ |
| 7 | **Cupim Roque-Roque** | 55 px/s | Vai até a **caixa/tábua de madeira** mais próxima (até 420 px) e a rói: rachaduras aparecem e ela quebra após 1,6 s de roída acumulada | Destrói barreiras de madeira | Não afeta a linha de tinta nem pedra | Não confiar só em madeira; abrigo de tinta | ✅ |
| 8 | **Lagarta Gulosa** | 42 px/s | Anda pelo chão e **sobe qualquer parede** (terreno, caixa ou a sua linha), descendo do outro lado | Paredes e tendas não a seguram | Muito lenta; não voa; água a leva | **Abrigo fechado** (arco) ou água | ✅ |

### Chefona (sem violência) ✅
**Rainha Zumbina** — abelha-rainha gigante (fase 5-6) que **não pica**: paira indo de um lado ao outro e, a cada 3,2 s, **infla as bochechas** (aviso de 1 s com "!") e **sopra** uma rajada que empurra linhas, caixas e bichinhos para longe dela (e deixa as operárias tontas). Vence-se aguentando 14 s com um abrigo travado entre duas pedras. (Implementação: `src/game/insects/queen_bee.gd`.)

### Progressão da dificuldade
Mundo 1: abelha → formiga → abelha+formiga. Mundo 2: mosquito, mariposa+luz, vários bichinhos, dois traços. Mundo 3: besouro, abismos, plataformas móveis, cupim. Mundo 4: água, Lulu e Tuca, vespa, lagarta. Mundo 5: noite, lâmpadas como isca, combinações e chefão.
