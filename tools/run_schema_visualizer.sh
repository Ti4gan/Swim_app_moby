#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIS="$ROOT/tools/firestore-schema-visualizer"
OUT="$ROOT/docs/firestore-schema"
PROJECT_ID="swim-app-moby"
FIREBASE_CFG="${HOME}/.config/configstore/firebase-tools.json"
CLIENT_ID="563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
CLIENT_SECRET="j9iVZfS8kkCEFUPaAeJV0sAi"

if [[ ! -f "$FIREBASE_CFG" ]]; then
  echo "Сначала: npx firebase-tools login"
  exit 1
fi

mkdir -p "$OUT"
cd "$VIS"

if [[ ! -d venv ]]; then
  python3 -m venv venv
  ./venv/bin/pip install -q -r requirements.txt
fi

REFRESH_TOKEN="$(python3 -c "
import json, sys
p = sys.argv[1]
with open(p) as f:
    t = json.load(f).get('tokens', {}).get('refresh_token')
if not t:
    sys.exit(1)
print(t)
" "$FIREBASE_CFG")" || {
  echo "В firebase-tools.json нет refresh_token. Выполните: npx firebase-tools login"
  exit 1
}

ADC="$(mktemp)"
trap 'rm -f "$ADC"' EXIT
python3 -c "
import json, sys
json.dump({
  'type': 'authorized_user',
  'client_id': sys.argv[1],
  'client_secret': sys.argv[2],
  'refresh_token': sys.argv[3],
}, open(sys.argv[4], 'w'))
" "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "$ADC"

export GOOGLE_APPLICATION_CREDENTIALS="$ADC"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
ARGS=(
  --sample-size 30
  --max-depth 3
  --skip-llm
  --format plantuml
)

echo "Проект: $PROJECT_ID"
echo "Вывод: $OUT"
./venv/bin/python main.py "${ARGS[@]}"

mv -f firestore_schema_*.json "$OUT/" 2>/dev/null || true
PUML_OUT="$OUT/firestore_schema_${TIMESTAMP}.puml"
PNG_OUT="$OUT/firestore_schema_${TIMESTAMP}.png"
PUML_SRC="$(ls -t "$VIS"/firestore_schema_llm_*.puml 2>/dev/null | head -1 || true)"
if [[ -n "${PUML_SRC:-}" ]]; then
  cp -f "$PUML_SRC" "$PUML_OUT"
fi

if [[ -f "$PUML_OUT" ]] && command -v plantuml >/dev/null; then
  plantuml -tpng "$PUML_OUT" -o "$OUT"
  GENERATED="$OUT/$(basename "${PUML_OUT%.puml}").png"
  if [[ -f "$GENERATED" && "$GENERATED" != "$PNG_OUT" ]]; then
    mv -f "$GENERATED" "$PNG_OUT"
  fi
  echo "PNG: $PNG_OUT"
  XMI_OUT="$OUT/firestore_schema_${TIMESTAMP}.xmi"
  plantuml -xmi:star "$PUML_OUT" -o "$OUT"
  XMI_GEN="$OUT/$(basename "${PUML_OUT%.puml}").xmi"
  if [[ -f "$XMI_GEN" && "$XMI_GEN" != "$XMI_OUT" ]]; then
    mv -f "$XMI_GEN" "$XMI_OUT"
  fi
  if [[ -f "$XMI_OUT" ]]; then
    echo "XMI (StarUML): $XMI_OUT"
  fi
fi

mv -f "$VIS"/firestore_schema_llm_*.png "$OUT/" 2>/dev/null || true

echo ""
echo "Готово:"
ls -la "$OUT"
