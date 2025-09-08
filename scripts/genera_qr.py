import os
import pandas as pd
import qrcode

CSV = "src/qrcodes.csv"
OUTDIR = "assets/qrcodes"

os.makedirs(OUTDIR, exist_ok=True)

df = pd.read_csv(CSV)
required_cols = {"code_id", "url", "label"}
if not required_cols.issubset(df.columns):
    raise SystemExit(f"src/qrcodes.csv deve contenere colonne: {sorted(required_cols)}")

for _, row in df.iterrows():
    code_id = str(row["code_id"]).strip()
    url = str(row["url"]).strip()
    label = str(row["label"]).strip()
    if not url or not url.lower().startswith("http"):
        print(f"[AVVISO] URL mancante o non valido per {code_id}: '{url}', uso placeholder")
        url = f"https://example.org/placeholder/{code_id}"
    img = qrcode.make(url)
    out = os.path.join(OUTDIR, f"{code_id}.png")
    img.save(out)
    print(f"[OK] QR generato: {out} ({label})")
print("Fatto.")