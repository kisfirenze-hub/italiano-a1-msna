# Italiano A1 – MSNA (Unità 1–4) – PDF con QR, schede e guida educatore

Contenuto
- src/units: Unità 1–4 in Markdown con immagini e QR
- src/worksheets: schede stampabili per ogni unità
- src/educatori/guida-educatore.md: guida completa
- assets/qrcodes: QR code (generati automaticamente)
- assets/images: immagini (attualmente segnaposto blu in SVG)
- scripts: generazione QR e build PDF
- build/pdf: output PDF (dopo il build)
- .github/workflows/build.yml: build automatico e artifact PDF

Requisiti (locale)
- Python 3.9+ (per generare QR): `pip install -r requirements.txt`
- Docker (consigliato) oppure Pandoc + TeX (xelatex) installati localmente

Passi rapidi
1) Inserisci/aggiorna i link audio in `src/qrcodes.csv` (colonna url).
2) Genera i QR (locale):
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   python scripts/genera_qr.py
3) Aggiungi immagini reali sostituendo i segnaposto in `assets/images/`.
4) Crea i PDF:
   ./scripts/build.sh
   Trovi i PDF in build/pdf/units, build/pdf/worksheets, build/pdf/educatori.

Build automatico (GitHub Actions)
- Già configurato in `.github/workflows/build.yml`.
- Al push o alla PR, Actions genera i PDF e li allega come artifact “pdf-bundle”.

Immagini
- Ora sono segnaposto blu (SVG) con i nomi richiesti (u1-…, u2-…, etc.).
- Puoi sostituirli con immagini CC0/CC-BY (Unsplash, Pexels, Wikimedia). Mantieni i nomi file per non rompere i link.

Audio (QR)
- Carica gli audio su uno spazio pubblico (es. GitHub Releases/Pages).
- Aggiorna `src/qrcodes.csv` con gli URL pubblici e rilancia la build (i QR si rigenerano).

Note
- I file delle unità puntano a immagini .svg (segnaposto). Se carichi .jpg/.png, aggiorna anche i link nei file o mantieni i nomi .svg.
- Per qualsiasi aiuto, dimmi e posso aprire direttamente una PR nella prossima risposta.