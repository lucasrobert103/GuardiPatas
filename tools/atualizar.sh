#!/usr/bin/env bash
# Baixa a versão mais nova do branch, limpa o cache do Godot, gera um APK de debug NOVO
# e instala no celular conectado por USB. Funciona no macOS (bash 3.2) e no Linux.
#
#   bash tools/atualizar.sh            # atualiza, gera e instala (mantém o progresso no celular)
#   bash tools/atualizar.sh --limpo    # desinstala antes: começa do zero (mostra o aviso dos termos)
#   GODOT=/caminho/Godot bash tools/atualizar.sh   # se o Godot estiver em outro lugar
set -euo pipefail

# Tudo fica dentro de main(): o git troca este arquivo no meio da execução, então o bash
# precisa ler o script inteiro antes de começar.
main() {
BRANCH="ccr-69427eab-1v26vu"
PACKAGE="br.com.guardipatas"
APK="build/GuardiPatas-debug.apk"
LIMPO=0
if [ "${1:-}" = "--limpo" ]; then LIMPO=1; fi

cd "$(dirname "$0")/.."
passo() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }
falha() { printf '\n\033[1;31mERRO: %s\033[0m\n' "$1"; exit 1; }

# ---------------------------------------------------------------- 1. código novo
passo "Baixando a versão mais nova de $BRANCH"
git fetch origin "$BRANCH"
if [ -n "$(git status --porcelain)" ]; then
  NOME="antes-de-atualizar-$(date +%Y%m%d-%H%M%S)"
  git stash push -u -m "$NOME" >/dev/null
  echo "Suas mudanças locais foram guardadas no stash \"$NOME\" (git stash list)."
fi
git checkout -B "$BRANCH" "origin/$BRANCH"
git reset --hard "origin/$BRANCH"
COMMIT="$(git log -1 --format='%h %s')"
echo "Agora no commit: $COMMIT"

# ---------------------------------------------------------------- 2. Godot
if [ -z "${GODOT:-}" ]; then
  for c in godot godot4 \
           "/Applications/Godot.app/Contents/MacOS/Godot" \
           "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
           "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then GODOT="$c"; break; fi
  done
fi
[ -n "${GODOT:-}" ] || falha "Godot não encontrado. Rode com GODOT=/caminho/do/Godot bash tools/atualizar.sh"
echo "Godot: $GODOT ($("$GODOT" --version 2>/dev/null | head -1))"

passo "Limpando o cache do Godot (.godot) e importando de novo"
rm -rf .godot
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --import 2>&1 | grep -E "SCRIPT ERROR|Parse Error" && falha "o projeto tem erro de script" || true

# ---------------------------------------------------------------- 3. APK novo
passo "Gerando APK de debug novo em $APK"
[ -d android/build ] || falha "falta o template Android (pasta android/build). No Godot: Projeto > Instalar Modelo de Build Android."
mkdir -p build
rm -f "$APK"
# o preset gera AAB para a loja; para instalar no celular trocamos para APK só durante o export
cp export_presets.cfg export_presets.cfg.bak
trap 'mv -f export_presets.cfg.bak export_presets.cfg 2>/dev/null || true' EXIT
perl -pi -e 's/^gradle_build\/export_format=1/gradle_build\/export_format=0/' export_presets.cfg
"$GODOT" --headless --path . --export-debug "Android" "$APK" 2>&1 | tail -20
mv -f export_presets.cfg.bak export_presets.cfg
trap - EXIT
[ -f "$APK" ] || falha "o APK não foi gerado (veja as mensagens acima)."
echo "APK gerado: $APK ($(du -h "$APK" | cut -f1), $(date -r "$APK" '+%d/%m %H:%M:%S' 2>/dev/null || date))"

# ---------------------------------------------------------------- 4. celular
ADB="${ADB:-}"
if [ -z "$ADB" ]; then
  if command -v adb >/dev/null 2>&1; then ADB="adb"; else ADB="$HOME/Library/Android/sdk/platform-tools/adb"; fi
fi
[ -x "$ADB" ] || command -v "$ADB" >/dev/null 2>&1 || falha "adb não encontrado (defina ADB=/caminho/adb)"

passo "Instalando no celular"
"$ADB" kill-server >/dev/null 2>&1 || true
"$ADB" start-server >/dev/null
echo "Aguardando o celular (USB com depuração ativada)..."
"$ADB" wait-for-device
"$ADB" devices
"$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
if [ "$LIMPO" = 1 ]; then
  echo "Desinstalando a versão antiga (apaga o progresso do celular)..."
  "$ADB" uninstall "$PACKAGE" >/dev/null 2>&1 || true
fi
if ! "$ADB" install -r -d "$APK"; then
  echo "A instalação por cima falhou (assinatura diferente?). Desinstalando e instalando de novo..."
  "$ADB" uninstall "$PACKAGE" >/dev/null 2>&1 || true
  "$ADB" install "$APK"
fi
"$ADB" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

VERSAO="$("$ADB" shell dumpsys package "$PACKAGE" 2>/dev/null | grep -m1 versionName | tr -d ' \r')"
passo "Pronto!"
echo "Commit: $COMMIT"
echo "No celular: $VERSAO  (em Ajustes, no fim da tela, aparece a mesma versão)"
}

main "$@"
