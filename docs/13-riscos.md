# 13 — Riscos técnicos e mitigação

| # | Risco | Prob. | Impacto | Mitigação | Status |
|---|---|---|---|---|---|
| 1 | Instabilidade da física 2D (vibração, tunelamento, corpos "explodindo") | Média | Alto | Corpo único de cápsulas (≤ 40), CCD, 20 iterações, massa proporcional, folga na validação; **teste de solução por fase no CI**; plano B: GDExtension Box2D/Rapier | Mitigado no protótipo; validar em aparelho |
| 2 | Física diferente entre aparelhos (ponto flutuante) mudando o resultado de fases "no limite" | Baixa | Médio | Soluções registradas com folga; passo fixo de 60 Hz; não depender de equilíbrio milimétrico | Em observação |
| 3 | Fases impossíveis ou triviais | Média | Alto | Teste automático: solução **vence** e **sem linha perde** | ✅ automatizado |
| 4 | Desempenho em aparelhos de entrada (redesenho procedural a cada quadro) | Média | Médio | Fundo desenhado uma vez; só personagens/insetos redesenham; teto de 45 insetos; renderizador Compatibility; medir em aparelho real (Etapa 3) | A medir |
| 5 | Plugin de anúncios da comunidade abandonado ou incompatível | Média | Médio | Interface `MonetizationService` isolada; alternativa: plugin Android v2 próprio sobre o SDK oficial | Planejado |
| 6 | Mudança de requisito da Play (API alvo anual, Billing) | Alta (é anual) | Médio | Godot atualizado a cada versão estável; checklist de publicação (doc 14) | Contínuo |
| 7 | Conformidade Famílias/ECA Digital/LGPD | Média | Alto | Sem coleta de dados hoje; SDK autocertificado; TFCD; sem loot boxes; revisão jurídica antes do lançamento | Planejado |
| 8 | Toque impreciso em telas pequenas / dedo cobrindo a linha | Média | Médio | Traço segue o dedo com prévia grossa e contorno; validação visível (X); "toque acidental" ignorado; reinício instantâneo | Implementado; validar com jogadores |
| 9 | Arte procedural parecer "simples demais" para competir | Média | Médio | Direção de arte definida (doc 03); pipeline de troca por sprites sem mexer na física | Planejado |
| 10 | Escopo crescer (30+ fases, chefão) e atrasar | Alta | Médio | Etapas pequenas; gerador de fases; cada fase validada automaticamente | Em curso |
| 11 | CI sem runner (cobrança/limite do GitHub Actions) | Ocorreu | Baixo | Testes também rodam localmente com qualquer binário 4.7.2 (doc 14) | Ver doc 12 |
| 12 | Perda de save (atualização/desinstalação) | Baixa | Médio | Save versionado e mesclado com padrões; backup via Google Play Games Saves (futuro) | Parcial |
