# 02 — Pesquisa tecnológica e escolha do motor

**Data da pesquisa:** 28/10/2026.
**Método:** documentação oficial primeiro (Godot, Unity, Google/Android, Defold); notícias e fóruns só como complemento, sempre marcados.
**Legenda:** ✅ **Fato** confirmado em fonte oficial · 🟡 **Fonte secundária** (notícia/fórum, não confirmada oficialmente) · 💭 **Opinião/estimativa** do time.

> Limitação honesta: o ambiente onde este documento foi escrito não tinha acesso a `godotengine.org` (bloqueado pela política de rede). As informações do Godot vêm do **código-fonte e da referência de classes oficiais da tag `4.7.2-stable`** (clonados do repositório oficial `godotengine/godot`) e da documentação oficial indexada por busca. Os testes do jogo rodam no GitHub Actions com o binário oficial 4.7.2.

---

## 1. O que o jogo exige da tecnologia

| Necessidade do GuardiPatas | Por que importa |
|---|---|
| Física 2D estável com corpos criados **em tempo de execução** | A linha do jogador vira um corpo rígido com forma arbitrária a cada tentativa. |
| Consultas de física (raio, forma, "cast") | Impedir que o traço atravesse paredes/bichinhos e evitar colisores inconsistentes. |
| Toque preciso e barato | Captura de traço a 60+ Hz em aparelhos de entrada. |
| Animação 2D expressiva | Personagens com expressões, susto, comemoração. |
| Fases configuráveis por dados | 30+ fases sem duplicar código; testes automáticos de solução. |
| Exportação Android AAB, API alvo atual | Exigência da Google Play. |
| Anúncios recompensados + compras (futuro) | Monetização ética, compatível com a Política de Famílias. |
| APK pequeno, pouca memória/bateria | Público amplo, aparelhos modestos, mercado brasileiro. |
| Custo zero ou previsível | Projeto independente. |

## 2. Fatos verificados por tecnologia

### Godot Engine 4.7 (GDScript)
- ✅ Versão estável mais recente: **4.7.2-stable** (tag no repositório oficial; `version.py`: `major=4, minor=7, patch=2, status="stable"`). Godot 4.7.0 saiu em 18/06/2026 🟡 (notícias), 4.7.1 em julho/2026 🟡.
- ✅ Licença **MIT**, sem royalties, sem taxa por instalação, sem tela de abertura obrigatória.
- ✅ Física 2D própria (GodotPhysics2D) com `RigidBody2D`, `CapsuleShape2D`, `CollisionPolygon2D`, `AnimatableBody2D`, CCD (`CCD_MODE_CAST_SHAPE`) e consultas `PhysicsDirectSpaceState2D.intersect_shape / cast_motion / intersect_ray` (referência de classes 4.7).
- ✅ `cast_motion` retorna as frações seguras/inseguras do movimento e **ignora formas já sobrepostas** — por isso o jogo também usa `intersect_shape` no ponto final (doc. da classe).
- ✅ Interpolação de física 2D (`physics/common/physics_interpolation`) para movimento suave em telas de 90/120 Hz.
- ✅ Exportação Android: **AAB exige "Gradle build"** ativado no preset (docs oficiais "Exporting for Android" e "Gradle builds for Android"); opções `gradle_build/min_sdk`, `gradle_build/target_sdk`, `gradle_build/export_format`, arquiteturas `arm64-v8a`/`armeabi-v7a` (classe `EditorExportPlatformAndroid`).
- ✅ Renderizador **Compatibility (OpenGL ES 3)** recomendado para alcançar o maior número de aparelhos; 2D vetorial roda bem nele.
- ✅ Plugin oficial de faturamento: **GodotGooglePlayBilling** (organização `godot-sdk-integrations`), compatível com Godot 4.2+ (docs "Android in-app purchases").
- 🟡 **AdMob não tem plugin oficial do Google para Godot**; há plugins da comunidade (ex.: Poing Studios, `cengiz-pz`) que empacotam o SDK oficial do Google Mobile Ads. A organização `godot-sdk-integrations` também lista um repositório `godot-admob` 🟡.
- ✅ Modo `--headless` + `--fixed-fps` + `--import` na linha de comando (fonte `main/main.cpp` 4.7.2) → permite **testes automatizados de física no CI**.
- 🟡 Godot 4.7 trouxe "GABE" (build Android direto do aparelho) e correções de movimento em Android no 4.7.1.

### Unity 6 (C#)
- ✅ Plano **Personal gratuito até US$ 200 mil** de receita/financiamento anual; Runtime Fee **cancelada** (página oficial "Changes to Unity subscription plans and pricing").
- ✅ Pro: preço anual por assento com reajuste anunciado para 2026 (páginas oficiais de preço; valores variam por região) — custo só relevante acima do limite do Personal.
- ✅ Física 2D baseada em **Box2D**; no Unity 6.3 LTS existe a API **LowLevelPhysics2D** sobre **Box2D v3** (manual 6000.3), além do clássico Rigidbody2D/Collider2D.
- ✅ **Google Mobile Ads Unity Plugin oficial** (developers.google.com/admob/unity) e **Unity IAP** oficial.
- 💭 Editor pesado, iteração mais lenta em máquinas modestas; cenas/prefabs em YAML com GUIDs são ruins para revisão de código e geração automática de fases.
- 💭 Histórico de mudança unilateral de termos (Runtime Fee de 2023, revertida) é um **risco de governança**, ainda que hoje o custo seja zero para este projeto.

### Defold (Lua) — avaliado por ter vantagens concretas em mobile
- ✅ Gratuito (licença própria, código aberto), builds muito pequenos, Box2D, extensões oficiais de AdMob/IAP.
- ✅ **Limitação crítica para este jogo:** formas de colisão são definidas no editor; `physics.set_shape()` só **altera** formas já existentes, não cria novas (manual "Collision shapes"). Polígonos precisam ser convexos e há limites para múltiplas formas por objeto 🟡 (fórum). Criar uma linha de forma livre exigiria dezenas de objetos pré-fabricados por traço.
- 💭 Comunidade menor, ferramentas de animação 2D mais limitadas.

### Outras opções consideradas e descartadas
- **Flutter + Flame/Forge2D**, **libGDX + Box2D**, **Kotlin nativo**: viáveis, mas sem editor de cenas/animação, mais código de infraestrutura e nenhuma vantagem decisiva sobre Godot para este escopo 💭.

### Requisitos da Google Play (afetam qualquer motor)
- ✅ Desde 31/08/2026, **novos apps e atualizações devem mirar Android 16 (API 36)** (Google Play "Target API level requirements" / developer.android.com).
- ✅ Publicação em **AAB** obrigatória para apps novos.
- ✅ Biblioteca de Faturamento: ciclo de suporte de 2 anos por versão; versões antigas são bloqueadas para apps novos/atualizações (FAQ oficial de descontinuação). Há divergência entre páginas oficiais sobre a exigência de PBL 7 x PBL 8 em 2026 → **usar PBL 8+** elimina a dúvida.
- ✅ **Política de Famílias:** se o público inclui crianças, anúncios só via **SDKs autocertificados para Famílias**; o programa de autocertificação de novos SDKs está fechado para novos inscritos no momento (Central de Ajuda Play Console). O Google Mobile Ads SDK consta como autocertificado.
- ✅ Brasil: **ECA Digital (Lei 15.211/2025)**, exigível desde 17/03/2026, + **LGPD**. O decreto regulamentador permite oferecer versão sem *loot boxes* a menores 🟡 (escritórios de advocacia). **O GuardiPatas não terá loot boxes nem compras aleatórias.**

## 3. Tabela comparativa

| Critério | Godot 4.7 (GDScript) | Unity 6.3 LTS (C#) | Defold (Lua) |
|---|---|---|---|
| Puzzles 2D com física | ✅ Bom; corpos compostos criados em código com facilidade | ✅ Excelente (Box2D maduro, v3 na API low-level) | 🟡 Box2D, mas formas dinâmicas são o ponto fraco |
| Precisão/estabilidade de colisores | 💭 Boa com cuidados (cápsulas, CCD, nº de formas limitado) | ✅ Referência do gênero | ✅ Box2D |
| Desempenho em Android de entrada | ✅ Compatibility/GLES3, 2D leve | ✅ Bom, runtime maior | ✅ Excelente |
| Memória e bateria | 💭 Baixas para 2D vetorial; `low_processor_mode` nos menus | 💭 Médias | 💭 Muito baixas |
| Desenho de linha com toque | ✅ `Line2D` + `_draw()` + consultas de espaço | ✅ `LineRenderer` + `EdgeCollider2D` | 🟡 Possível, mais trabalhoso |
| Animação 2D | ✅ AnimationPlayer, Skeleton2D, desenho procedural | ✅ 2D Animation, Spine | 🟡 Spine/flipbook |
| Ferramentas para criar fases | ✅ Cenas em texto (`.tscn`) + JSON; fácil gerar e testar | 🟡 Editor ótimo, mas YAML com GUID dificulta automação | 🟡 Editor simples |
| Exportação Android / AAB | ✅ Oficial (AAB via Gradle build) | ✅ Oficial | ✅ Oficial |
| Anúncios | 🟡 Plugins da comunidade sobre SDK oficial do Google | ✅ Plugin oficial do Google | ✅ Extensão oficial |
| Compras | ✅ Plugin oficial do Godot (Google Play Billing) | ✅ Unity IAP oficial | ✅ Extensão oficial |
| Testes automatizados | ✅ Headless + `--fixed-fps` → teste de física no CI (usado neste projeto) | ✅ Unity Test Framework (CI exige licença/ativação) | 🟡 Limitado |
| Tamanho do app | 💭 ~25–40 MB por ABI (estimativa) | 💭 ~20–40 MB (IL2CPP arm64) | ✅ ~3–10 MB |
| Licença / custos | ✅ MIT, R$ 0, sem royalties | ✅ Grátis até US$ 200 mil/ano; depois Pro por assento | ✅ Grátis |
| Riscos comerciais | 💭 Baixos (código aberto, fundação sem fins lucrativos) | 💭 Médio (termos podem mudar; já mudaram em 2023) | 💭 Baixo |
| Manutenção e expansão | ✅ Código e dados em texto, diffs legíveis | ✅ Ecossistema enorme | 🟡 Lua, comunidade menor |
| Comunidade e documentação | ✅ Grande e crescente; releases a cada ~4–6 meses | ✅ Enorme | 🟡 Menor |

## 4. Recomendação

**Godot 4.7.2 + GDScript, renderizador Compatibility, exportação AAB via Gradle, API alvo 36.**

Por quê, especificamente para este jogo:

1. **A mecânica central é "criar um corpo físico de forma livre a cada tentativa".** No Godot isso é natural: um `RigidBody2D` recebe N `CapsuleShape2D` por código, com consultas de espaço (`cast_motion`, `intersect_shape`) para validar o traço. No Defold isso é justamente o ponto fraco.
2. **Testabilidade da física**: o Godot roda headless com passo fixo, então cada fase tem **uma solução registrada que o CI desenha e simula** — se uma mudança de física quebrar uma fase, o teste falha. Isso protege a qualidade dos puzzles, o maior risco do gênero.
3. **Fases como dados e cenas em texto**: diffs legíveis, geração assistida, revisão fácil.
4. **Custo zero e sem risco de mudança de licença**; app leve para o público brasileiro com aparelhos modestos.
5. A vantagem real da Unity (Box2D e SDK de anúncios oficiais) foi pesada: a física 2D do Godot atende este escopo com as mitigações abaixo, e anúncios só entram na Etapa 4 atrás de uma interface isolada (`MonetizationService`), podendo usar um plugin mantido ou um plugin Android próprio (sistema oficial de plugins v2) sobre o SDK oficial do Google.

**Mitigações para a física do Godot** (detalhes em `07-mecanicas-e-fisica.md`): corpo único composto (sem juntas), cápsulas em vez de segmentos finos, no máx. 40 formas por linha, CCD em linhas e vespas, 20 iterações do solver, massa proporcional ao comprimento, folga de 3 px na validação do traço. **Plano B:** se surgir instabilidade insolúvel, trocar o servidor de física 2D por uma extensão Box2D/Rapier (GDExtension) sem reescrever o jogo, porque todo o código usa a API padrão de nós.

## 5. Fontes

- Godot — repositório oficial, tag 4.7.2-stable: https://github.com/godotengine/godot (arquivos `version.py`, `doc/classes/*.xml`, `main/main.cpp`, `scene/resources/audio_stream_wav.cpp`)
- Godot — Exporting for Android (4.7): https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Godot — Gradle builds for Android: https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html
- Godot — Android in-app purchases: https://docs.godotengine.org/es/4.5/_sources/tutorials/platform/android/android_in_app_purchases.rst.txt
- GodotGooglePlayBilling (oficial): https://github.com/godot-sdk-integrations/godot-google-play-billing
- Android Developers — Export Godot projects: https://developer.android.com/games/engines/godot/godot-export
- Notícias Godot 4.7 🟡: https://www.gamingonlinux.com/2026/06/godot-engine-4-7-is-out-bringing-a-new-asset-store-hdr-support-steam-frame-support/ · https://www.warp2search.net/story/godot-471-rc-2-released-29-fixes-crash-patches-and-security-update/
- Unity — preços e Runtime Fee: https://unity.com/products/pricing-updates · https://unity.com/blog/terms-update-runtime-fee-cancellation
- Unity — 2D Physics low-level (Box2D v3), 6.3 LTS: https://docs.unity3d.com/Manual/2d-physics-api/2d-physics-api-introduction.html · https://discussions.unity.com/t/low-level-2d-physics-in-unity-6-3/1683247
- Google Mobile Ads Unity Plugin: https://developers.google.com/admob/unity/quick-start
- Defold — Collision shapes: https://defold.com/manuals/physics-shapes · fórum 🟡: https://forum.defold.com/t/how-to-make-runtime-created-shapes-collide/83005
- Google Play — Target API level: https://developer.android.com/google/play/requirements/target-sdk · https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play Billing — FAQ de descontinuação: https://developer.android.com/google/play/billing/deprecation-faq
- Política de Famílias e SDKs autocertificados: https://support.google.com/googleplay/android-developer/answer/9900633 · https://support.google.com/googleplay/android-developer/answer/12918983
- AdMob — conteúdo para crianças / tratamento direcionado: https://support.google.com/admob/answer/6223431
- ECA Digital (Lei 15.211/2025) 🟡 análises jurídicas: https://www.mattosfilho.com.br/unico/eca-digital-sancionada-lei/ · https://www.mayerbrown.com/es/insights/publications/2026/04/enforcement-of-brazils-eca-digital-introduces-new-obligations-for-companies
