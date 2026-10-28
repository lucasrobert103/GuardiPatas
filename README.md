# GuardiPatas — Proteja os Bichinhos 🐾

Puzzle de física 2D para Android: **desenhe uma linha com o dedo** para proteger bichinhos fofos de insetos travessos. Solte o dedo, a física começa, os insetos saem dos ninhos — e o seu abrigo tem que aguentar até o cronômetro zerar.

Feito em **Godot 4.7.2 (GDScript)**, renderizador Compatibility, para todas as idades.

<p>
<img src="docs/img/titulo.png" width="200"> <img src="docs/img/fase-dica.png" width="200"> <img src="docs/img/fase-formigas.png" width="200"> <img src="docs/img/fase-rampa.png" width="200">
</p>
<p>
<img src="docs/img/fase-todos.png" width="200"> <img src="docs/img/fase-rainha.png" width="200"> <img src="docs/img/colecao.png" width="200"> <img src="docs/img/vitoria.png" width="200">
</p>

*(capturas reais do jogo renderizadas pelo próprio Godot)*

## O que já tem
- **30 fases em 5 mundos** (Jardim, Floresta, Vale das Formigas, Lagoa, Acampamento) + chefona **Rainha Zumbina** (que sopra vento, sem violência).
- **6 bichinhos** originais com traços de física próprios: Capitu (capivara pesada), Brasa (raposa alta), Pingo (ouriço que rola), Nino (esquilo levinho), Tuca (tartaruga cujo casco aguenta uma picada) e Lulu (axolote que vive na água).
- **8 insetos** com regras diferentes: abelha, formiga, besouro, mosquito, vespa, mariposa, cupim e lagarta.
- Linha com **peso real** (corpo rígido de cápsulas), validação do traço por física, tinta limitada com metas de estrela visíveis, caixas, lâmpadas, água, plataformas móveis, zonas proibidas.
- Menus, mapa, coleção com histórias, **guarda-roupa cosmético**, conquistas, dicas, ajustes de acessibilidade (alto contraste, reduzir movimento), salvamento local, botão voltar do Android.
- **28 efeitos sonoros + 2 músicas** sintetizados do zero (`tools/gen_audio.py`).
- **Testes automáticos**: cada fase é desenhada com a solução registrada e simulada — tem que vencer; e sem linha tem que perder. 119 verificações, 0 falhas.
- **Sem anúncios, sem compras, sem coleta de dados** nesta versão (monetização planejada com ética no doc 11).

## Rodar
1. Instale o **Godot 4.7.2** e importe `project.godot`.
2. **F5** — o mouse faz o papel do dedo.

Testes: `godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn` · Exportar para Android e publicar: [docs/14](docs/14-como-rodar-e-publicar.md).

## Documentação (primeira entrega)
| # | Documento |
|---|---|
| 01 | [Resumo executivo](docs/01-resumo-executivo.md) |
| 02 | [Pesquisa tecnológica, comparação Unity × Godot × Defold, fontes e recomendação](docs/02-pesquisa-tecnologica.md) |
| 03 | [Identidade visual](docs/03-identidade-visual.md) |
| 04 | [Som e música](docs/04-audio.md) |
| 05 | [Ficha dos seis bichinhos](docs/05-personagens.md) |
| 06 | [Ficha dos insetos](docs/06-insetos.md) |
| 07 | [Mecânicas e regras de física](docs/07-mecanicas-e-fisica.md) |
| 08 | [As 30 fases (cenário, objetivo, perigos, mecânica, solução)](docs/08-fases.md) |
| 09 | [Arquitetura técnica e decisões](docs/09-arquitetura.md) |
| 10 | [Progressão, recompensas e acessibilidade](docs/10-progressao-e-acessibilidade.md) |
| 11 | [Monetização, privacidade e classificação](docs/11-monetizacao-e-privacidade.md) |
| 12 | [Plano de desenvolvimento, o que foi testado e o que falta](docs/12-plano-de-desenvolvimento.md) |
| 13 | [Riscos técnicos e mitigação](docs/13-riscos.md) |
| 14 | [Como rodar, testar, exportar e publicar](docs/14-como-rodar-e-publicar.md) |

## Decisão técnica
**Godot 4.7.2 + GDScript.** A mecânica central — criar um corpo físico de forma livre a cada tentativa e validar o traço contra o cenário — é natural no Godot; ele roda **headless com passo fixo**, o que permite testar automaticamente se cada fase é solucionável; é **MIT, sem royalties**, leve para celulares modestos e guarda cenas/dados em texto. Detalhes e fontes no [doc 02](docs/02-pesquisa-tecnologica.md).
