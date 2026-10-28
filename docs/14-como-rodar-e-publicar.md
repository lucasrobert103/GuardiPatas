# 14 — Como rodar, testar, compilar e publicar

## Requisitos
- **Godot 4.7.2** (versão padrão, não a .NET): https://godotengine.org/download
- Para Android: **JDK 17**, **Android SDK** (Platform-Tools, Build-Tools, Platform 36) e os **export templates 4.7.2** (Editor → Gerenciar Modelos de Exportação).
- Opcional: Python 3 + numpy (só para regenerar áudio), Python 3 (para regenerar fases).

## Rodar no computador
1. Abra o Godot → **Importar** → selecione `project.godot`.
2. Aperte **F5**. O mouse simula o dedo (clique e arraste para desenhar).
   A janela abre em 405×720 (retrato); redimensione para testar outras proporções.

## Testes automatizados
```bash
# importa recursos (1ª vez) e roda todos os testes
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
# só uma fase (útil ao criar/ajustar fases)
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --level=3-3
```
Sai com código 0 se tudo passar. O CI (`.github/workflows/ci.yml`) faz o mesmo no GitHub Actions.

## Regenerar conteúdo
```bash
python3 tools/make_levels.py   # data/levels.json
python3 tools/gen_audio.py     # assets/audio/*.wav (requer numpy)
```

## Exportar para Android (APK de teste)
1. Editor → **Configurações do Editor → Exportar → Android**: caminho do SDK e do JDK.
2. **Projeto → Exportar** → preset **Android** (já incluso em `export_presets.cfg`):
   - `gradle_build/use_gradle_build = true` (exigido para AAB), formato **AAB** (`export_format = 1`);
   - `min_sdk 24`, `target_sdk 36` (requisito atual da Google Play);
   - arquiteturas `arm64-v8a` + `armeabi-v7a`;
   - permissões: só **VIBRATE**; internet desligada;
   - pacote: `br.com.guardipatas` (**troque** para um domínio que você controle antes de publicar — o ID não pode mudar depois).
3. Na 1ª vez: **Projeto → Instalar modelo de build Android** (cria a pasta `android/`, ignorada pelo git).
4. Para APK de teste: mude o formato para APK, conecte o celular com depuração USB e use o ícone Android ("Implantação remota") ou exporte o APK.

## Assinatura e AAB de produção
```bash
keytool -genkeypair -v -keystore guardipatas-upload.keystore -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```
- Preencha `keystore/release*` no preset **localmente** (o arquivo `.keystore` e senhas **não vão para o git** — ver `.gitignore`), ou use variáveis de ambiente `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD`.
- Ative **Play App Signing** no Play Console (a chave acima vira só a *upload key*).
- Exporte: `godot --headless --path . --export-release "Android" export/GuardiPatas.aab`.
- Incremente `version/code` a cada envio.

## Checklist da Google Play (antes do teste fechado)
- [ ] API alvo 36, AAB assinado, `version/code` novo
- [ ] Ícone adaptativo 432×432 (foreground/background) e ícone 512×512 da loja
- [ ] Capturas de tela (telefone e tablet 7"/10"), vídeo opcional, gráfico de destaque 1024×500
- [ ] Classificação de conteúdo (IARC) — esperado Livre
- [ ] Público-alvo e conteúdo: incluir menores de 13 → seguir **Política de Famílias**
- [ ] Segurança de dados: hoje "nenhum dado coletado"
- [ ] Política de privacidade publicada (URL)
- [ ] Teste fechado com ≥ 12 testadores por 14 dias (regra para contas pessoais novas — confira o número vigente no Play Console) e relatório pré-lançamento sem falhas
- [ ] Testar em aparelhos reais: um de entrada (2–3 GB RAM, Android 8–10) e um recente
