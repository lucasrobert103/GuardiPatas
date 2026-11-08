#!/usr/bin/env bash
# Gera o pacote para a Google Play (AAB assinado com a chave de upload) — versão de testadores.
#
#   bash tools/build_play.sh
#
# Saída: export/GuardiPatas-<versão>-<código>.aab  (é este arquivo que vai para a Play Console)
#
# Na primeira vez cria a CHAVE DE UPLOAD em ~/.guardipatas/guardipatas-upload.jks e pede uma senha.
# Guarde a senha e faça backup do arquivo: sem eles não dá para mandar atualizações do jogo.
#
# Variáveis opcionais:
#   VERSION_CODE=123                    número da versão (padrão: AAMMDDHH, sempre crescente)
#   GUARDIPATAS_KEYSTORE=/caminho.jks   outra chave de upload
#   GUARDIPATAS_KEY_ALIAS=guardipatas   apelido da chave
#   GUARDIPATAS_KEYSTORE_PASSWORD=...   senha (sem ela, o script pergunta)
#   GODOT=/caminho/Godot   ANDROID_HOME=/caminho/sdk

main() {
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
mkdir -p build export
LOG="$ROOT/build/build_play.log"
: > "$LOG"
passo() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }
aviso() { printf '\033[0;33m%s\033[0m\n' "$1"; }
falha() { printf '\n\033[1;31mERRO: %s\033[0m\n' "$1"; [ -s "$LOG" ] && printf 'Detalhes em %s\n' "$LOG"; exit 1; }

# ---------------------------------------------------------------- 1. ferramentas
passo "Conferindo as ferramentas"
if [ -z "${GODOT:-}" ]; then
  for c in godot godot4 "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
           "/Applications/Godot.app/Contents/MacOS/Godot" "/Applications/Godot_mono.app/Contents/MacOS/Godot"; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then GODOT="$c"; break; fi
  done
fi
[ -n "${GODOT:-}" ] || falha "Godot não encontrado. Rode com GODOT=/caminho/do/Godot bash tools/build_play.sh"
GODOT_VERSION="$("$GODOT" --version 2>/dev/null | head -1)"
echo "Godot: $GODOT ($GODOT_VERSION)"
TPL_NAME="$(echo "$GODOT_VERSION" | cut -d. -f1-4)"
case "$TPL_NAME" in *.*.*.*) ;; *) TPL_NAME="$(echo "$GODOT_VERSION" | cut -d. -f1-3)" ;; esac
TPL_CHANNEL="${TPL_NAME##*.}"
TPL_NUMBER="${TPL_NAME%.*}"
if [ "$(uname)" = "Darwin" ]; then
  GODOT_DATA="$HOME/Library/Application Support/Godot"; GODOT_CONFIG="$GODOT_DATA"
else
  GODOT_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/godot"; GODOT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
fi
TPL_DIR="$GODOT_DATA/export_templates/$TPL_NAME"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$SDK" ]; then
  for c in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
    if [ -d "$c" ]; then SDK="$c"; break; fi
  done
fi
[ -n "$SDK" ] && [ -d "$SDK/build-tools" ] || falha "Android SDK com Build-Tools não encontrado. No Android Studio: Settings > Android SDK > SDK Tools > \"Android SDK Build-Tools\" (ou defina ANDROID_HOME)."
export ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK"
echo "Android SDK: $SDK"

java_major() {
  "$1/bin/java" -version 2>&1 | grep -m1 'version "' | sed -E 's/.*version "([0-9]+)(\.([0-9]+))?.*/\1 \3/' | awk '{ print ($1 == "1") ? $2 : $1 }'
}
java_ok() { [ -x "$1/bin/java" ] && v="$(java_major "$1")" && [ -n "$v" ] && [ "$v" -ge 17 ] 2>/dev/null && [ "$v" -le 21 ] 2>/dev/null; }
CANDIDATOS=("${JAVA_HOME:-}" "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  "$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home")
if [ -x /usr/libexec/java_home ]; then
  for v in 21 17; do CANDIDATOS+=("$(/usr/libexec/java_home -v "$v" 2>/dev/null || true)"); done
fi
for c in /usr/lib/jvm/java-21-openjdk* /usr/lib/jvm/java-17-openjdk*; do CANDIDATOS+=("$c"); done
JAVA_ESCOLHIDO=""
for c in "${CANDIDATOS[@]}"; do
  if [ -n "$c" ] && java_ok "$c"; then JAVA_ESCOLHIDO="$c"; break; fi
done
[ -n "$JAVA_ESCOLHIDO" ] || falha "Não achei Java 17 a 21. Instale o Android Studio (ele traz o Java certo) e rode de novo."
export JAVA_HOME="$JAVA_ESCOLHIDO"
echo "Java: $JAVA_HOME (versão $(java_major "$JAVA_HOME"))"
KEYTOOL="$JAVA_HOME/bin/keytool"

# ---------------------------------------------------------------- 2. versão
VERSION_NAME="$(grep -m1 '^version/name=' export_presets.cfg | sed -E 's/.*="?([^"]*)"?/\1/')"
CURRENT_CODE="$(grep -m1 '^version/code=' export_presets.cfg | cut -d= -f2)"
CODE="${VERSION_CODE:-$(date +%y%m%d%H)}"
[ "$CODE" -gt "$CURRENT_CODE" ] 2>/dev/null || falha "VERSION_CODE ($CODE) precisa ser maior que $CURRENT_CODE"
OUT="export/GuardiPatas-${VERSION_NAME}-${CODE}.aab"
PACKAGE="$(grep -m1 '^package/unique_name=' export_presets.cfg | sed -E 's/.*="?([^"]*)"?/\1/')"
echo "Versão: $VERSION_NAME (código $CODE)  ·  pacote: $PACKAGE"
if grep -q "^const FREE_FOR_TESTERS := true" src/autoload/store.gd; then
  echo "Loja: TUDO GRÁTIS (versão de testadores, sem Google Play Billing)"
else
  aviso "Loja: FREE_FOR_TESTERS está desligado — esta versão espera compras reais."
fi

# ---------------------------------------------------------------- 3. chave de upload
passo "Chave de upload da Google Play"
KS="${GUARDIPATAS_KEYSTORE:-$HOME/.guardipatas/guardipatas-upload.jks}"
ALIAS="${GUARDIPATAS_KEY_ALIAS:-guardipatas}"
PASS="${GUARDIPATAS_KEYSTORE_PASSWORD:-}"
if [ ! -f "$KS" ]; then
  echo "Ainda não existe chave de upload. Vou criar uma em: $KS"
  echo "Escolha uma senha (mínimo 6 caracteres). ANOTE: ela é pedida em todo build para a loja."
  while [ -z "$PASS" ]; do
    printf "Senha: "; read -r -s P1; echo
    printf "Repita a senha: "; read -r -s P2; echo
    if [ "${#P1}" -lt 6 ]; then aviso "A senha precisa de pelo menos 6 caracteres."; elif [ "$P1" != "$P2" ]; then aviso "As senhas não conferem."; else PASS="$P1"; fi
  done
  mkdir -p "$(dirname "$KS")"
  chmod 700 "$(dirname "$KS")" 2>/dev/null || true
  "$KEYTOOL" -genkeypair -keystore "$KS" -storetype PKCS12 -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$PASS" -keypass "$PASS" -dname "CN=RetroNexa, O=RetroNexa, C=BR" >>"$LOG" 2>&1 \
    || falha "não consegui criar a chave de upload"
  chmod 600 "$KS" 2>/dev/null || true
  aviso "Chave criada. FAÇA BACKUP agora de $KS (e guarde a senha) num lugar seguro, fora do computador."
else
  echo "Usando a chave: $KS"
  if [ -z "$PASS" ]; then printf "Senha da chave de upload: "; read -r -s PASS; echo; fi
fi
"$KEYTOOL" -list -keystore "$KS" -storepass "$PASS" -alias "$ALIAS" >/dev/null 2>&1 \
  || falha "senha errada ou apelido \"$ALIAS\" não existe na chave $KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PASS"

# ---------------------------------------------------------------- 4. projeto e modelos
passo "Preparando o projeto"
rm -rf .godot
# (no macOS o Godot às vezes fecha com "Abort trap" depois de importar: é inofensivo)
( "$GODOT" --headless --path . --import >>"$LOG" 2>&1 ) 2>/dev/null || true
( "$GODOT" --headless --path . --import >>"$LOG" 2>&1 ) 2>/dev/null || true
if grep -E "SCRIPT ERROR|Parse Error" "$LOG" >/dev/null; then
  grep -E "SCRIPT ERROR|Parse Error" "$LOG" | head -5
  falha "o projeto tem erro de script"
fi
if [ ! -f "$TPL_DIR/android_release.apk" ] || [ ! -f "$TPL_DIR/android_source.zip" ]; then
  URL="https://github.com/godotengine/godot/releases/download/${TPL_NUMBER}-${TPL_CHANNEL}/Godot_v${TPL_NUMBER}-${TPL_CHANNEL}_export_templates.tpz"
  echo "Baixando os modelos de exportação do Godot $TPL_NAME (~1,3 GB, só na primeira vez)..."
  TMP_TPZ="$(mktemp -t godot-templates.XXXXXX)"
  curl -fL --progress-bar -o "$TMP_TPZ" "$URL" || falha "não consegui baixar os modelos de exportação"
  mkdir -p "$TPL_DIR"
  unzip -o -j -q "$TMP_TPZ" 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/android_source.zip' 'templates/version.txt' -d "$TPL_DIR" \
    || falha "o arquivo de modelos baixado está incompleto"
  rm -f "$TMP_TPZ"
fi
INSTALL_TEMPLATE=""
[ -f android/build/build.gradle ] || INSTALL_TEMPLATE="--install-android-build-template"
for settings in "$GODOT_CONFIG"/editor_settings-4*.tres; do
  [ -f "$settings" ] || continue
  SDK="$SDK" JAVA="$JAVA_HOME" perl -0pi -e '
    sub put { my ($k, $v) = @_; return if $v eq "";
      if (/^\Q$k\E = .*$/m) { s/^\Q$k\E = .*$/$k = "$v"/m } else { s/(\[resource\]\n)/$1$k = "$v"\n/ } }
    put("export/android/android_sdk_path", $ENV{SDK});
    put("export/android/java_sdk_path", $ENV{JAVA});
  ' "$settings"
done

# ---------------------------------------------------------------- 5. AAB
passo "Gerando o AAB de release (Gradle; a primeira vez demora alguns minutos)"
cp export_presets.cfg build/export_presets.cfg.play
restaurar() { cp build/export_presets.cfg.play export_presets.cfg 2>/dev/null || true; }
trap restaurar EXIT
perl -pi -e "s/^version\\/code=.*/version\\/code=$CODE/; s/^gradle_build\\/use_gradle_build=.*/gradle_build\\/use_gradle_build=true/; s/^gradle_build\\/export_format=.*/gradle_build\\/export_format=1/" export_presets.cfg
rm -f "$OUT"
set +e
"$GODOT" --headless --path . $INSTALL_TEMPLATE --export-release "Android" "$OUT" >>"$LOG" 2>&1
set -e
restaurar
trap - EXIT
if [ ! -f "$OUT" ]; then
  echo "--- o que deu errado ---"
  if grep -q "What went wrong" "$LOG"; then grep -A14 "What went wrong" "$LOG" | head -30
  else grep -iE "error|exception|failed|not found|unsupported|license" "$LOG" | grep -viE "fontconfig|system_font" | tail -12; fi
  falha "o AAB não foi gerado"
fi
if "$JAVA_HOME/bin/jarsigner" -verify "$OUT" >/dev/null 2>&1; then echo "Assinatura: ok"; else aviso "Não consegui conferir a assinatura do AAB (confira na Play Console ao enviar)."; fi

passo "Pronto!"
echo "Arquivo para a Play Console: $ROOT/$OUT ($(du -h "$OUT" | cut -f1))"
echo "Versão $VERSION_NAME, código $CODE. Para o próximo envio, rode de novo (o código sobe sozinho)."
echo
echo "Próximos passos: Play Console > seu app > Testar e lançar > Teste interno (ou fechado)"
echo "  > Criar nova versão > enviar este .aab > adicionar os e-mails dos testadores > Lançar."
}

main "$@"
