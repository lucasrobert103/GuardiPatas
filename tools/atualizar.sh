#!/usr/bin/env bash
# Baixa a versão mais nova do branch, limpa o cache do Godot, gera um APK de debug NOVO
# e instala no celular conectado por USB. Funciona no macOS (bash 3.2) e no Linux.
#
#   bash tools/atualizar.sh            # atualiza, gera e instala (mantém o progresso no celular)
#   bash tools/atualizar.sh --limpo    # desinstala antes: começa do zero (mostra o aviso dos termos)
#   bash tools/atualizar.sh --sem-git  # não mexe no git (só gera e instala o que está na pasta)
#
# Variáveis opcionais: GODOT=/caminho/Godot  ADB=/caminho/adb  ANDROID_HOME=/caminho/sdk
#
# Não precisa do "Modelo de Build Android" (pasta android/): sem ele, o APK sai dos modelos
# de exportação oficiais do Godot (baixados sozinhos na primeira vez, ~1,3 GB).

# Tudo fica dentro de main(): o git troca este arquivo no meio da execução, então o bash
# precisa ler o script inteiro antes de começar.
main() {
set -euo pipefail

BRANCH="ccr-69427eab-1v26vu"
PACKAGE="br.com.guardipatas"
APK="build/GuardiPatas-debug.apk"
LIMPO=0
GIT=1
for arg in "$@"; do
  case "$arg" in
    --limpo) LIMPO=1 ;;
    --sem-git) GIT=0 ;;
  esac
done

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
LOG="$ROOT/build/atualizar.log"
mkdir -p build
: > "$LOG"
passo() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }
aviso() { printf '\033[0;33m%s\033[0m\n' "$1"; }
falha() { printf '\n\033[1;31mERRO: %s\033[0m\n' "$1"; [ -s "$LOG" ] && printf 'Detalhes em %s\n' "$LOG"; exit 1; }

# ---------------------------------------------------------------- 1. código novo
COMMIT="$(git log -1 --format='%h %s' 2>/dev/null || echo '?')"
if [ "$GIT" = 1 ]; then
  passo "Baixando a versão mais nova de $BRANCH"
  git fetch origin "$BRANCH"
  if [ -n "$(git status --porcelain)" ]; then
    NOME="antes-de-atualizar-$(date +%Y%m%d-%H%M%S)"
    git stash push -u -m "$NOME" >/dev/null
    echo "Suas mudanças locais foram guardadas no stash \"$NOME\" (git stash list)."
  fi
  git checkout -B "$BRANCH" FETCH_HEAD >/dev/null 2>&1
  git reset --hard FETCH_HEAD >/dev/null
  COMMIT="$(git log -1 --format='%h %s')"
  echo "Agora no commit: $COMMIT"
fi

# ---------------------------------------------------------------- 2. ferramentas
if [ -z "${GODOT:-}" ]; then
  for c in godot godot4 \
           "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
           "/Applications/Godot.app/Contents/MacOS/Godot" \
           "/Applications/Godot_mono.app/Contents/MacOS/Godot"; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then GODOT="$c"; break; fi
  done
fi
[ -n "${GODOT:-}" ] || falha "Godot não encontrado. Rode com GODOT=/caminho/do/Godot bash tools/atualizar.sh"
GODOT_VERSION="$("$GODOT" --version 2>/dev/null | head -1)"
echo "Godot: $GODOT ($GODOT_VERSION)"
# 4.7.2.stable.official.xxxx -> 4.7.2.stable (pasta dos modelos) / 4.7.2 + stable (download)
TPL_NAME="$(echo "$GODOT_VERSION" | cut -d. -f1-4)"
case "$TPL_NAME" in
  *.*.*.*) ;;
  *) TPL_NAME="$(echo "$GODOT_VERSION" | cut -d. -f1-3)" ;;   # 4.7.stable (sem patch)
esac
TPL_CHANNEL="${TPL_NAME##*.}"
TPL_NUMBER="${TPL_NAME%.*}"

if [ "$(uname)" = "Darwin" ]; then
  GODOT_DATA="$HOME/Library/Application Support/Godot"
  GODOT_CONFIG="$GODOT_DATA"
else
  GODOT_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/godot"
  GODOT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
fi
TPL_DIR="$GODOT_DATA/export_templates/$TPL_NAME"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$SDK" ]; then
  for c in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
    if [ -d "$c" ]; then SDK="$c"; break; fi
  done
fi

ADB="${ADB:-}"
if [ -z "$ADB" ]; then
  if [ -n "$SDK" ] && [ -x "$SDK/platform-tools/adb" ]; then ADB="$SDK/platform-tools/adb"
  elif command -v adb >/dev/null 2>&1; then ADB="adb"
  else ADB="$HOME/Library/Android/sdk/platform-tools/adb"; fi
fi

if [ -z "${JAVA_HOME:-}" ]; then
  for c in "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
           "$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home"; do
    if [ -x "$c/bin/java" ]; then export JAVA_HOME="$c"; break; fi
  done
  if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
    JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || true)"
    [ -n "$JAVA_HOME" ] && export JAVA_HOME
  fi
fi
KEYTOOL="keytool"
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/keytool" ]; then KEYTOOL="$JAVA_HOME/bin/keytool"; fi

# ---------------------------------------------------------------- 3. cache do Godot
passo "Limpando o cache do Godot (.godot) e importando de novo"
rm -rf .godot
# no macOS o Godot às vezes fecha com "Abort trap: 6" ao terminar a importação: é inofensivo,
# por isso a importação roda duas vezes e só erros de script interrompem
"$GODOT" --headless --path . --import >>"$LOG" 2>&1 || aviso "(o Godot fechou com erro na 1ª importação; tentando de novo)"
"$GODOT" --headless --path . --import >>"$LOG" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error" "$LOG" >/dev/null; then
  grep -E "SCRIPT ERROR|Parse Error" "$LOG" | head -5
  falha "o projeto tem erro de script"
fi
echo "ok"

# ---------------------------------------------------------------- 4. APK novo
passo "Gerando APK de debug novo em $APK"
GRADLE=0
[ -f android/build/build.gradle ] && GRADLE=1
if [ "$GRADLE" = 0 ]; then
  # sem o Modelo de Build Android: usa os modelos oficiais (android_debug.apk)
  if [ ! -f "$TPL_DIR/android_debug.apk" ]; then
    URL="https://github.com/godotengine/godot/releases/download/${TPL_NUMBER}-${TPL_CHANNEL}/Godot_v${TPL_NUMBER}-${TPL_CHANNEL}_export_templates.tpz"
    echo "Baixando os modelos de exportação do Godot $TPL_NAME (~1,3 GB, só na primeira vez)..."
    echo "$URL"
    TMP_TPZ="$(mktemp -t godot-templates.XXXXXX)"
    curl -fL --progress-bar -o "$TMP_TPZ" "$URL" || falha "não consegui baixar os modelos. No Godot: Editor > Gerenciar Modelos de Exportação > Baixar e Instalar."
    mkdir -p "$TPL_DIR"
    unzip -o -j -q "$TMP_TPZ" 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/android_source.zip' 'templates/version.txt' -d "$TPL_DIR" \
      || falha "o arquivo de modelos baixado está incompleto"
    rm -f "$TMP_TPZ"
  fi
  echo "Modelos: $TPL_DIR"
fi
[ -n "$SDK" ] && [ -d "$SDK/build-tools" ] || falha "Android SDK com Build-Tools não encontrado. No Android Studio: Settings > Android SDK > SDK Tools > marque \"Android SDK Build-Tools\" (ou defina ANDROID_HOME)."
echo "Android SDK: $SDK"
export ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK"

# chave de debug padrão do Android (a mesma do Android Studio)
KS="$HOME/.android/debug.keystore"
if [ ! -f "$KS" ]; then
  echo "Criando a chave de debug em $KS"
  mkdir -p "$HOME/.android"
  "$KEYTOOL" -genkeypair -keystore "$KS" -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >>"$LOG" 2>&1 \
    || falha "não consegui criar a chave de debug (precisa do Java: instale o Android Studio)"
fi
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

# o Godot usa o SDK/Java salvos nas configurações do editor: aponta para os encontrados aqui
for settings in "$GODOT_CONFIG"/editor_settings-4*.tres; do
  [ -f "$settings" ] || continue
  cp "$settings" "$settings.bak-atualizar"
  SDK="$SDK" JAVA="${JAVA_HOME:-}" perl -0pi -e '
    sub put { my ($k, $v) = @_; return if $v eq "";
      if (/^\Q$k\E = .*$/m) { s/^\Q$k\E = .*$/$k = "$v"/m } else { s/(\[resource\]\n)/$1$k = "$v"\n/ } }
    put("export/android/android_sdk_path", $ENV{SDK});
    put("export/android/java_sdk_path", $ENV{JAVA});
  ' "$settings"
done

rm -f "$APK"
# o preset do repositório gera AAB para a loja; para o celular troca para APK só durante o export
cp export_presets.cfg build/export_presets.cfg.original
restaurar() { cp build/export_presets.cfg.original export_presets.cfg 2>/dev/null || true; }
trap restaurar EXIT
perl -pi -e 's/^gradle_build\/export_format=.*/gradle_build\/export_format=0/' export_presets.cfg
if [ "$GRADLE" = 0 ]; then
  # sem Gradle o Godot recusa SDK mínimo/alvo personalizados: usa os padrões dele
  perl -pi -e 's/^gradle_build\/use_gradle_build=.*/gradle_build\/use_gradle_build=false/; s/^gradle_build\/min_sdk=.*/gradle_build\/min_sdk=""/; s/^gradle_build\/target_sdk=.*/gradle_build\/target_sdk=""/' export_presets.cfg
fi
set +e
"$GODOT" --headless --path . --export-debug "Android" "$APK" >>"$LOG" 2>&1
set -e
restaurar
trap - EXIT
if [ ! -f "$APK" ]; then
  echo "--- últimas mensagens do Godot ---"
  grep -vE "^\s*$" "$LOG" | tail -25
  falha "o APK não foi gerado"
fi
echo "APK gerado: $APK ($(du -h "$APK" | cut -f1))"

# ---------------------------------------------------------------- 5. celular
[ -x "$ADB" ] || command -v "$ADB" >/dev/null 2>&1 || falha "adb não encontrado (defina ADB=/caminho/adb)"
passo "Instalando no celular"
"$ADB" kill-server >/dev/null 2>&1 || true
"$ADB" start-server >/dev/null 2>&1
echo "Aguardando o celular (cabo USB e depuração USB ativada; aceite o aviso no celular)..."
"$ADB" wait-for-device
"$ADB" devices
"$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
if [ "$LIMPO" = 1 ]; then
  echo "Desinstalando a versão antiga (apaga o progresso do celular)..."
  "$ADB" uninstall "$PACKAGE" >/dev/null 2>&1 || true
fi
if ! "$ADB" install -r -d "$APK"; then
  aviso "A instalação por cima falhou (o APK antigo foi assinado com outra chave). Desinstalando e instalando de novo..."
  "$ADB" uninstall "$PACKAGE" >/dev/null 2>&1 || true
  "$ADB" install "$APK" || falha "o celular recusou o APK"
fi
"$ADB" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

VERSAO="$("$ADB" shell dumpsys package "$PACKAGE" 2>/dev/null | grep -m1 versionName | tr -d ' \r' || true)"
passo "Pronto! O jogo abriu no celular."
echo "Commit: $COMMIT"
echo "No celular: $VERSAO  (o rodapé dos Ajustes mostra a mesma versão)"
}

main "$@"
