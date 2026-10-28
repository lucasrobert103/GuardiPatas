# 03 — Identidade visual

## Pilares
1. **Redondo e macio.** Tudo nasce de elipses, discos e triângulos de ponta arredondada. Nada pontudo ameaçador — nem os insetos (eles são *travessos*, não *malvados*).
2. **Contorno ameixa, nunca preto.** Contorno `#3A2B3C` de 4 px em personagens e 2–3 px em detalhes. Dá unidade "desenho animado" sem pesar.
3. **Linguagem de cor com significado fixo:**

| Significado | Cor | Uso |
|---|---|---|
| **Proteção** | Azul-giz `#4AA3FF` + brilho `#BFE3FF` | A linha do jogador, botões de ação secundária |
| **Perigo** | Laranja-vermelho `#FF5A36` | Insetos agressivos (vespa), zonas proibidas, "Ai!" |
| **Vitória** | Ouro `#FFD23F` | Estrelas, moedas, confete, aviso "!" da vespa |
| **Ação positiva** | Verde `#5CC46A` | "Jogar", "Próxima", "Pronto!" |
| **Tinta acabando** | Coral `#FF7A6B` | Barra de tinta < 20 % |

4. **Silhueta primeiro.** Cada bichinho e inseto é reconhecível só pela forma (teste do "borrão preto"): capivara = pão deitado com laranja; raposa = gota em pé com orelhas e cauda; ouriço = sol de espinhos; esquilo = bolinha + cauda em "S"; tartaruga = cúpula; axolote = cápsula com 3 brânquias. Abelha = oval listrado; vespa = oval fino listrado; mosquito = palito com pernas; mariposa = asas grandes; formiga = três bolinhas; besouro = meia-lua brilhante.
5. **Animação exagerada e procedural:** respiração (squash & stretch), tremedeira de susto, pulos de comemoração com amassadinha no chão, pupilas que **seguem o perigo**, piscadas aleatórias. Tudo calculado em `_draw()` — leve e sempre fluido.

## Cenários (profundidade simples)
Camadas: céu em gradiente → sol/lua → nuvens que passeiam → colinas longe → elemento do mundo → colinas perto → terreno jogável (terra + faixa de grama + flores/tufos).

| Mundo | Céu | Elemento característico |
|---|---|---|
| 1. Jardim dos Bichinhos | Azul-claro | Flores rosas, sol grande |
| 2. Floresta Encantada | Verde-água | Pinheiros, vaga-lumes (futuro) |
| 3. Vale das Formigas | Pôr do sol laranja | Mesas de pedra, formigueiros |
| 4. Lagoa Misteriosa | Azul profundo | Faixa de lago com reflexos |
| 5. Acampamento no Quintal | Noite violeta + estrelas | Barracas, lanternas |

O **terreno jogável é sempre mais saturado e contornado** que o fundo → o jogador distingue de relance o que é sólido.

## Interface
- Botões "gordinhos" com borda inferior grossa (parecem apertáveis), cantos 30 px, **altura mínima 84–96 px** (≥ 48 dp em qualquer tela).
- Texto com contorno branco/ameixa, tamanho mínimo 21 px em resolução de projeto 720×1280.
- Ícones vetoriais próprios (pausa, reiniciar, dica, estrela, cadeado, moeda...) — não dependem de emoji/fonte.
- Barra de tinta com **marcas de estrela**: o jogador vê quanto pode gastar para 3★ e 2★ antes de desenhar.

## Efeitos que comunicam
- **Perigo:** "!" dourado piscando sobre a vespa que vai investir; contorno vermelho opcional em todos os insetos (modo alto contraste); X vermelho onde o traço foi bloqueado.
- **Proteção:** poeira quando a linha pousa; "boink" + amassadinho no inseto que bate na linha.
- **Vitória:** confete, pulos, estrelas que aparecem uma a uma com tons ascendentes.

## Acessibilidade visual
- Nada depende só de cor: perigo também tem forma (zigue-zague, "!", X), insetos têm padrões (listras, pintas, segmentos).
- Modo **alto contraste** (anel vermelho nos insetos) e **reduzir movimento** (sem tremor de câmera, menos partículas, sem pulos amplos).

## Pipeline de arte
Hoje a arte é **procedural** (código em `src/game/animal_art.gd` e `src/game/insects/insect_art.gd`). Para a versão comercial, o plano é: manter as mesmas proporções/âncoras e substituir por sprites vetoriais (SVG → texturas) ou rigs Skeleton2D, sem mudar a física, porque as formas de colisão são independentes da arte.
