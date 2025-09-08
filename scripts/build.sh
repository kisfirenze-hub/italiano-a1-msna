#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/pdf"
UNITS_OUT="$OUT/units"
WS_OUT="$OUT/worksheets"
EDU_OUT="$OUT/educatori"

mkdir -p "$UNITS_OUT" "$WS_OUT" "$EDU_OUT"

# Build via Dockerized pandoc/latex for portability
docker run --rm -v "$ROOT":/work -w /work pandoc/latex:latest \
  bash -lc '
    mkdir -p build/pdf/units build/pdf/worksheets build/pdf/educatori;
    # Genera QR (se non già presenti)
    python3 - <<PY
import os, pandas as pd, qrcode
CSV="src/qrcodes.csv"; OUT="assets/qrcodes"; os.makedirs(OUT, exist_ok=True)
df=pd.read_csv(CSV)
for _,r in df.iterrows():
    code_id=str(r["code_id"]).strip(); url=str(r["url"]).strip()
    if not url.startswith("http"): url=f"https://example.org/placeholder/{code_id}"
    qrcode.make(url).save(os.path.join(OUT, f"{code_id}.png"))
PY
    # Unità
    for f in src/units/*.md; do
      base=$(basename "$f" .md)
      pandoc "$f" --from markdown+emoji -V geometry:margin=2.2cm --pdf-engine=xelatex \
        -o "build/pdf/units/${base}.pdf";
    done
    # Schede
    find src/worksheets -name "*.md" -print0 | while IFS= read -r -d "" f; do
      rel=$(echo "$f" | sed "s|src/worksheets/||; s|/|-|g; s|.md$||")
      pandoc "$f" --from markdown -V geometry:margin=1.8cm --pdf-engine=xelatex \
        -o "build/pdf/worksheets/${rel}.pdf";
    done
    # Guida educatore
    pandoc src/educatori/guida-educatore.md --from markdown -V geometry:margin=2cm --pdf-engine=xelatex \
      -o build/pdf/educatori/guida-educatore.pdf
  '

echo "PDF creati in $OUT"