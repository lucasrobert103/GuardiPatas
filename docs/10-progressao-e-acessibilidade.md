# 10 — Progressão, recompensas e acessibilidade

## Progressão (implementada)
- **Fases em sequência:** vencer libera a próxima. Mundos aparecem no mapa conforme as fases existem. **Nenhuma barreira de estrelas ou pagamento** para avançar.
- **Estrelas (1–3) por economia de tinta**, com as metas visíveis na barra antes de desenhar. Vencer sempre dá pelo menos 1★.
- **Moedas:** +10 por estrela nova, +3 por vitória, +5 no primeiro 3★. Repetir uma fase já perfeita dá só +3 → sem incentivo a "farmar".
- **Amigos:** cada bichinho salvo pela primeira vez entra na Coleção com ficha e história.
- **Guarda-roupa:** 6 acessórios cosméticos (60–250 moedas) para qualquer bichinho conhecido.
- **Conquistas:** 10 (primeira vitória, 10/30 estrelas, 5 fases perfeitas, vencer com ≤ 25 % de tinta, completar mundos, conhecer os 6, equipar acessório, tentar 10 vezes).
- **Dicas opcionais:** começa com 3; trocar 40 moedas por +1. A dica mostra a solução tracejada animada. **Paga uma vez por fase na sessão** (recomeçar não cobra de novo). Disponível também na tela de derrota.

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
