# 11 — Monetização, privacidade e classificação

> **Status:** nada de monetização está implementado no protótipo — por decisão (Etapa 4: "só após validar a qualidade do jogo"). Não existe botão de anúncio ou de compra no jogo hoje.

## Restrições que definem a estratégia
1. **Público "todas as idades" inclui crianças** → o app cai na **Política de Famílias** da Google Play: anúncios só de **SDKs autocertificados para Famílias**, conteúdo adequado, sem coleta de identificadores de crianças; no AdMob, marcar **tratamento direcionado a crianças (TFCD)** / classificação de conteúdo máxima "G" para usuários menores ou de idade desconhecida.
2. **Brasil — ECA Digital (Lei 15.211/2025, exigível desde 17/03/2026) e LGPD:** minimização de dados, configurações protetivas por padrão, nada de loot boxes para menores, transparência nas compras. (Validar com assessoria jurídica antes do lançamento — análises jurídicas citadas no doc 02.)
3. **Google Play Billing:** usar **Billing Library 8+** (o plugin oficial do Godot acompanha); compras de conteúdo digital *obrigatoriamente* pelo Google Play Billing.

## Estratégia recomendada (equilibrada, sem previsões fantasiosas)
| Fonte | Como | Quando | Por quê |
|---|---|---|---|
| **Compra única "Sem anúncios + Pacote Apoiador"** | Remove todos os anúncios e dá 3 acessórios exclusivos | Lançamento | Simples, honesto, pais entendem |
| **Anúncio recompensado opcional** | Só em dois lugares: "ganhar 1 dica" e "dobrar moedas da fase" (na tela de vitória) | Lançamento | Escolha do jogador; nunca necessário para progredir |
| **Intersticial (moderado)** | No máx. a cada 3 fases **vencidas**, nunca após derrota, nunca nos primeiros 10 min de jogo, nunca no meio de uma tentativa ou puzzle | Avaliar após dados de retenção | Receita base sem estragar o ritmo |
| **Pacotes cosméticos** | "Pijama Party", "Festa Junina", "Inverno" — conjunto fixo, preço claro | Pós-lançamento | Conteúdo, não poder |
| **Mundos extras** | Pacotes de 12 fases pagos **opcionais**, campanha principal sempre gratuita | Pós-lançamento | Expansão sustentável |

**Nunca:** moeda premium com conversão confusa, caixas aleatórias, ofertas com cronômetro, anúncios em telas de criança sem consentimento dos responsáveis, empurrar anúncios para "continuar".

Sobre receita: não há previsão numérica aqui de propósito. A receita de anúncios em apps para famílias tem CPMs mais baixos (sem personalização). O plano é medir na Etapa 4 (teste fechado) e decidir intersticiais com dados.

## Arquitetura prevista
```gdscript
# src/services/monetization.gd (Etapa 4)
# API mínima e única usada pelo jogo; implementações trocáveis:
#   MonetizationNull (desktop/testes) · MonetizationAndroid (plugin AdMob + GodotGooglePlayBilling)
func is_ad_free() -> bool
func can_show_rewarded() -> bool
func show_rewarded(reason: String) -> void   # emite rewarded_earned / rewarded_failed
func purchase(product_id: String) -> void     # emite purchase_completed / purchase_failed
func restore_purchases() -> void
```
Fluxo de consentimento: UMP (User Messaging Platform) do Google onde aplicável; para crianças/idade desconhecida, anúncios **não personalizados** com TFCD. Toda chamada de anúncio passa por `Game` → respeita "Sem anúncios" e as regras de frequência acima.

## Privacidade (estado atual)
- O protótipo **não coleta nem transmite nenhum dado** (sem rede, sem analytics, sem IDs). Save local em `user://save.json`.
- Permissões Android: apenas **VIBRATE** (para a vibração opcional). Nenhuma permissão perigosa.
- Formulário de **Segurança de dados** da Play: hoje "nenhum dado coletado/compartilhado". Mudará com o SDK de anúncios — atualizar antes de enviar.
- Política de privacidade (obrigatória para Famílias) — rascunho a publicar numa página própria antes do teste fechado.

## Classificação etária
Questionário IARC: sem violência (picadas são cômicas, sem dano), sem linguagem imprópria, sem compras aleatórias → esperado **Livre / PEGI 3 / ESRB E**. Público-alvo no Play Console: **"todas as idades" incluindo menores de 13** → seguir a Política de Famílias integralmente (ou, se optar por 13+, remover apelo infantil, o que não combina com o jogo).
