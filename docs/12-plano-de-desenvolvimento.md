# 12 — Plano de desenvolvimento e status

## Etapas
| Etapa | Entregas | Status |
|---|---|---|
| **1. Pesquisa e planejamento** | Pesquisa de motores com fontes, público e diferencial, identidade visual, elenco, insetos, mecânicas, fases, arquitetura, riscos | ✅ docs 01–14 |
| **2. Protótipo jogável** | Cenário, bichinho, inseto, desenho por toque, colisões, vitória/derrota, reinício rápido | ✅ |
| **3. MVP** | 6 bichinhos, insetos principais, 10+ fases, menus, ajustes, salvamento | ✅ no código (30 fases, 8 insetos + chefona). **Falta: teste em aparelhos Android reais** |
| **4. Expansão** | 30 fases, mundos, animações, sons, recompensas; monetização após validar qualidade | 🟡 30 fases, 5 mundos, sons e recompensas feitos; monetização **não iniciada (de propósito)** |
| **5. Publicação** | APK de teste, pacote/assinatura/AAB, desempenho/estabilidade/permissões, materiais da loja | 🟡 preset de exportação e checklist prontos (doc 14); falta gerar/assinar/testar em aparelho |

## O que foi implementado
Ver doc 09 para a arquitetura. Resumo: desenho validado por física; linha como corpo rígido de cápsulas; 6 bichinhos com traços de física próprios e expressões; 8 insetos + chefona com IA; caixas, tábuas, lâmpadas, água, plataformas móveis, zonas proibidas, pedras; 30 fases em 5 mundos com cenários próprios; HUD com barra de tinta e metas de estrela, cronômetro, dicas, pausa, resultado; título, mapa, coleção (amigos, guarda-roupa, conquistas), ajustes (volumes, vibração, reduzir movimento, alto contraste, apagar progresso); salvamento local; 28 efeitos + 2 músicas; botão voltar do Android e pausa ao minimizar.

## O que foi testado (e como)
> Esta seção é atualizada a cada execução dos testes. Ver o resultado mais recente abaixo.

- **Sintaxe de todos os scripts**: `gdparse` (gdtoolkit) — OK.
- **Geometria das soluções** (folga ≥ 10 px, limites, zonas proibidas, tinta): validador Python — 30/30 OK.
- **Motor real — Godot 4.7.2** compilado do código-fonte oficial (tag `4.7.2-stable`) dentro do ambiente de desenvolvimento, porque o download do binário estava bloqueado pela rede e o GitHub Actions não iniciou runners nesta conta (ver abaixo):
  - importação do projeto (`--import`) sem erros;
  - **compilação dos 45 scripts** (`tests/check_scripts.tscn`) sem erros;
  - **156 verificações** (`tests/test_runner.tscn`): unitários de `LineMath`, `Scoring`, progresso/salvamento e áudio (31 sons importados, 6 com loop lido do WAV); validação do desenho (traço não entra em chão, bichinho ou zona proibida e para encostado no obstáculo); e, para **cada uma das 30 fases**, *a solução registrada vence* e *sem linha a fase é perdida*;
  - a bateria completa foi executada **7 vezes** após as correções (os insetos têm variação estética aleatória) — 0 falhas em todas;
  - **capturas de tela reais** renderizadas com OpenGL (Mesa/Xvfb) em 720×1280 para revisar arte e interface (`tests/screenshots.tscn`; amostras em `docs/img/`). Problemas encontrados e corrigidos assim: ícones descentralizados nos botões, textos quebrando letra a letra, botão de dica fora da tela, balão de dica cobrindo a colmeia, título do mundo 5 empurrando botões, tendas escondidas atrás das colinas.
- **Teste de fluxo da interface** (`tests/flow_test.tscn`): título → mapa → fase → pausa → derrota → dica → vitória → próxima → recomeçar → mapa → troca de mundo → coleção (compra/equipa) → conquistas → ajustes → cancelar apagar → voltar do Android. 21 verificações OK. Achou e corrigiu: **a pausa não pausava**.
- **Robustez das soluções** (`--variants`, relatório): cada solução é redesenhada 15 % mais larga, 15 % mais alta, deslocada 12 px e 5 % mais apertada. Primeira rodada: 33 de 120 variações perdiam, quase todas por "deslocado" (o começo do traço encostava no bichinho e era recusado, abrindo uma fresta). Depois de o traço passar a **contornar obstáculos**: **119/120 vencem** (a exceção é a 5-5 com abrigos mais largos, que não cabem lado a lado — esperado).
- **Bugs reais encontrados pelos testes e corrigidos:** formigas/besouros/cupins/lagartas não venciam o atrito do chão (andarilhos agora usam atrito 0 com controle de velocidade); formigueiros bloqueavam outros andarilhos (ninhos ganharam camada de colisão própria); inferência de tipo inválida na tela de coleção.
- **Não testado ainda:** aparelho Android real (desempenho, toque, tamanho do APK), áudio audível (os WAVs foram gerados e importados, mas não ouvidos), exportação AAB (requer Android SDK + templates).
- **GitHub Actions:** o workflow está no repositório, mas os jobs terminam em ~2 s sem runner atribuído (sintoma típico de limite de minutos/cobrança da conta para repositório privado). Quando a conta liberar Actions, o mesmo pipeline roda sozinho a cada push.

### Última execução (28/10/2026, Godot 4.7.2, `--fixed-fps 60`)
```
  1-1 Oi, Capitu!            solução=VENCEU (6.0s, tinta 56%, 3★)  sem-linha=PERDEU (3.4s, sting)
  1-2 Zumbido em Dobro       solução=VENCEU (8.0s, tinta 56%, 3★)  sem-linha=PERDEU (3.3s, sting)
  1-3 Brasa, a Curiosa       solução=VENCEU (8.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.3s, sting)
  1-4 Fila de Formigas       solução=VENCEU (10.0s, tinta 55%, 3★)  sem-linha=PERDEU (4.1s, sting)
  1-5 Bolinha de Espinhos    solução=VENCEU (9.0s, tinta 54%, 3★)  sem-linha=PERDEU (3.4s, sting)
  1-6 Lá no Alto             solução=VENCEU (8.0s, tinta 55%, 3★)  sem-linha=PERDEU (2.4s, sting)
  2-1 Zizi, o Mosquito       solução=VENCEU (8.0s, tinta 56%, 3★)  sem-linha=PERDEU (2.7s, sting)
  2-2 Luz da Lanterna        solução=VENCEU (10.0s, tinta 55%, 3★)  sem-linha=PERDEU (6.2s, sting)
  2-3 Dois Amigos            solução=VENCEU (8.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.5s, sting)
  2-4 Caixa Amiga            solução=VENCEU (8.0s, tinta 56%, 2★)  sem-linha=PERDEU (3.5s, sting)
  2-5 Duas Linhas            solução=VENCEU (9.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.4s, sting)
  2-6 Zona Proibida          solução=VENCEU (9.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.4s, sting)
  3-1 Bolota Teimosa         solução=VENCEU (11.0s, tinta 55%, 3★)  sem-linha=PERDEU (6.2s, sting)
  3-2 Ponte Sobre o Nada     solução=VENCEU (10.0s, tinta 56%, 3★)  sem-linha=PERDEU (4.0s, sting)
  3-3 Ladeira do Pingo       solução=VENCEU (9.0s, tinta 56%, 3★)  sem-linha=PERDEU (2.1s, water)
  3-4 Elevador de Folha      solução=VENCEU (9.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.0s, sting)
  3-5 Roque-Roque            solução=VENCEU (12.0s, tinta 56%, 3★)  sem-linha=PERDEU (8.3s, sting)
  3-6 Formigueiro Gigante    solução=VENCEU (12.0s, tinta 55%, 3★)  sem-linha=PERDEU (2.9s, sting)
  4-1 Bolhas da Lulu         solução=VENCEU (10.0s, tinta 55%, 3★)  sem-linha=PERDEU (4.5s, sting)
  4-2 Vovó Tuca              solução=VENCEU (9.0s, tinta 55%, 3★)  sem-linha=PERDEU (4.0s, sting)
  4-3 Faísca!                solução=VENCEU (9.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.6s, sting)
  4-4 Fosso Protetor         solução=VENCEU (10.0s, tinta 56%, 3★)  sem-linha=PERDEU (4.0s, sting)
  4-5 Lagarta Gulosa         solução=VENCEU (13.0s, tinta 56%, 3★)  sem-linha=PERDEU (3.5s, sting)
  4-6 Ilhas Amigas           solução=VENCEU (10.0s, tinta 55%, 3★)  sem-linha=PERDEU (2.7s, sting)
  5-1 Noite de Lanternas     solução=VENCEU (11.0s, tinta 55%, 3★)  sem-linha=PERDEU (9.5s, sting)
  5-2 Fogueira de Brinquedo  solução=VENCEU (11.0s, tinta 55%, 3★)  sem-linha=PERDEU (4.2s, sting)
  5-3 Carrossel de Tábua     solução=VENCEU (10.0s, tinta 55%, 3★)  sem-linha=PERDEU (2.4s, sting)
  5-4 Pouca Tinta            solução=VENCEU (9.0s, tinta 81%, 3★)  sem-linha=PERDEU (2.7s, sting)
  5-5 Todos Juntos           solução=VENCEU (12.0s, tinta 55%, 3★)  sem-linha=PERDEU (3.3s, sting)
  5-6 Rainha Zumbina         solução=VENCEU (14.0s, tinta 56%, 3★)  sem-linha=PERDEU (3.7s, sting)
==== RESULTADO: 156 ok, 0 falhas ====  (119 na época desta tabela + 37 checagens de áudio adicionadas depois)
```

## Próximos passos (em ordem)
1. Testar em 2–3 aparelhos Android reais (entrada + recente): FPS, toque, tamanho do APK, consumo.
2. Teste com jogadores (crianças com responsáveis + adultos): clareza das dicas, dificuldade, frustração.
3. Arte final: substituir o desenho procedural por sprites/rigs mantendo as âncoras; ícone adaptativo.
4. Tradução (EN/ES) via CSV do Godot.
5. Monetização (doc 11) atrás de `MonetizationService`, com Billing 8+ e SDK autocertificado para Famílias.
6. Teste fechado na Play Console, política de privacidade, materiais da loja.
