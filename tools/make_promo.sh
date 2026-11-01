#!/usr/bin/env bash
# Grava o vídeo de divulgação (1080x1920, 30 fps) e converte para MP4 (H.264 + AAC).
#   tools/make_promo.sh [saida.mp4]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-export/guardipatas-promo.mp4}"
TMP="$(mktemp -d)"
mkdir -p "$(dirname "$OUT")"
# janela grande e JPEG quase sem perda só durante a gravação
cat > override.cfg <<'CFG'
[display]
window/size/window_width_override=1080
window/size/window_height_override=1920
[editor]
movie_writer/mjpeg_quality=0.97
CFG
trap 'rm -f override.cfg; rm -rf "$TMP"' EXIT
xvfb-run -a -s "-screen 0 1200x2000x24" godot --path . --rendering-driver opengl3 \
    --fixed-fps 30 --write-movie "$TMP/promo.avi" res://tools/promo.tscn
ffmpeg -y -v error -i "$TMP/promo.avi" \
    -vf "scale=1080:1920:flags=lanczos,format=yuv420p" \
    -c:v libx264 -preset slow -crf 19 -profile:v high -r 30 \
    -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 \
    -movflags +faststart "$OUT"
echo "vídeo: $OUT"
