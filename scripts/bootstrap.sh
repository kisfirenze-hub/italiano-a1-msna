#!/usr/bin/env bash
set -euo pipefail

echo "==> Creazione struttura cartelle"
mkdir -p assets/images assets/qrcodes src/units src/worksheets/u01 src/worksheets/u02 src/worksheets/u03 src/worksheets/u04 src/educatori .github/workflows scripts build/pdf

echo "==> Scrittura README.md"
cat > README.md << 'EOF'
# Italiano A1 – MSNA (Unità 1–4) – PDF con QR, schede e guida educatore

Contenuto
- src/units: Unità 1–4 in Markdown con immagini e QR
- src/worksheets: schede stampabili per ogni unità
- src/educatori/guida-educatore.md: guida completa
- assets/qrcodes: QR code generati da src/qrcodes.csv
- assets/images: immagini (verranno create come segnaposto blu se mancanti)
- scripts: generazione QR, generazione segnaposto e build PDF
- build/pdf: output PDF (dopo il build)
- .github/workflows/build.yml: build automatico e artifact PDF

Requisiti (locale)
- Python 3.9+ (per generare QR e placeholder): pip install -r requirements.txt
- Docker (consigliato) oppure Pandoc + TeX (xelatex) installati localmente

Passi rapidi
1) Inserisci/aggiorna i link audio in src/qrcodes.csv (colonna url).
2) Genera i QR:
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   python scripts/genera_qr.py
3) (Opzionale) Aggiungi immagini CC0/CC-BY in assets/images. Se mancano, verranno creati segnaposto blu automaticamente.
4) Crea i PDF:
   ./scripts/build.sh
   Trovi i PDF in build/pdf/units, build/pdf/worksheets, build/pdf/educatori.

Build automatico (GitHub Actions)
- Al push/PR, Actions genera e allega i PDF come Artifact “pdf-bundle”.
- Puoi scaricarli dalla pagina “Actions” del repository.

Immagini richieste (generate come segnaposto se assenti)
- Unità 1:
  - u1-saluto.jpg (due ragazzi si presentano)
  - u1-mappa-italia-mondo.jpg (mappa con frecce verso Italia)
  - u1-badge-esempio.jpg (badge nome/paese/lingue)
- Unità 2:
  - u2-orologio.jpg (orologio analogico)
  - u2-colazione-italiana.jpg (latte, pane, marmellata)
  - u2-poster-giornata-esempio.jpg (poster a vignette)
- Unità 3:
  - u3-tabella-turni.jpg (tabella turni al muro)
  - u3-spazi-comuni.jpg (cucina/sala/cortile ordinati)
- Unità 4:
  - u4-carrello-cibi.jpg (carrello con alimenti base)
  - u4-etichette-prezzo.jpg (cartellini prezzo chiari)
  - u4-grafico-spesa.jpg (grafico a barre esempio)

Audio (QR)
- Registra gli audio come da trascrizioni nelle unità (cartella suggerita: assets/audio).
- Carica online (es. GitHub Releases/Pages o servizio scolastico) e inserisci gli URL pubblici in src/qrcodes.csv.
- Rigenera i QR.

Note e personalizzazione
- Sostituisci i segnaposto blu con foto CC idonee quando disponibili (con crediti).
- I PDF risultanti sono: 4 unità, 12+ schede, 1 guida educatore.
EOF

echo "==> Scrittura requirements.txt"
cat > requirements.txt << 'EOF'
qrcode[pil]==7.4.2
pillow==10.4.0
pandas==2.2.2
EOF

echo "==> Scrittura scripts/build.sh"
cat > scripts/build.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Build PDFs using Dockerized pandoc+latex to avoid local TeX installs
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/pdf"
UNITS_OUT="$OUT/units"
WS_OUT="$OUT/worksheets"
EDU_OUT="$OUT/educatori"

mkdir -p "$UNITS_OUT" "$WS_OUT" "$EDU_OUT"

# Generate placeholder images (blue) if required images are missing
python3 "$ROOT/scripts/gen_placeholders.py"

# Image/QR assets will be mounted read-only
docker run --rm -v "$ROOT":/work -w /work pandoc/latex:latest \
  bash -lc '
    mkdir -p build/pdf/units build/pdf/worksheets build/pdf/educatori;
    for f in src/units/*.md; do
      base=$(basename "$f" .md)
      pandoc "$f" --from markdown+emoji -V geometry:margin=2.2cm --pdf-engine=xelatex \
        -o "build/pdf/units/${base}.pdf";
    done
    find src/worksheets -name "*.md" -print0 | while IFS= read -r -d "" f; do
      rel=$(echo "$f" | sed "s|src/worksheets/||; s|/|-|g; s|.md$||")
      pandoc "$f" --from markdown -V geometry:margin=1.8cm --pdf-engine=xelatex \
        -o "build/pdf/worksheets/${rel}.pdf";
    done
    pandoc src/educatori/guida-educatore.md --from markdown -V geometry:margin=2cm --pdf-engine=xelatex \
      -o build/pdf/educatori/guida-educatore.pdf
  '

echo "PDF creati in $OUT"
EOF
chmod +x scripts/build.sh

echo "==> Scrittura scripts/genera_qr.py"
cat > scripts/genera_qr.py << 'EOF'
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
    if not url or url.lower().startswith("http") is False:
        print(f"[AVVISO] URL mancante o non valido per {code_id}: '{url}'")
    img = qrcode.make(url or f"https://example.org/placeholder/{code_id}")
    out = os.path.join(OUTDIR, f"{code_id}.png")
    img.save(out)
    print(f"[OK] QR generato: {out} ({label})")
print("Fatto.")
EOF

echo "==> Scrittura scripts/gen_placeholders.py"
cat > scripts/gen_placeholders.py << 'EOF'
import os
from PIL import Image, ImageDraw, ImageFont

REQUIRED_IMAGES = [
    "assets/images/u1-saluto.jpg",
    "assets/images/u1-mappa-italia-mondo.jpg",
    "assets/images/u1-badge-esempio.jpg",
    "assets/images/u2-orologio.jpg",
    "assets/images/u2-colazione-italiana.jpg",
    "assets/images/u2-poster-giornata-esempio.jpg",
    "assets/images/u3-tabella-turni.jpg",
    "assets/images/u3-spazi-comuni.jpg",
    "assets/images/u4-carrello-cibi.jpg",
    "assets/images/u4-etichette-prezzo.jpg",
    "assets/images/u4-grafico-spesa.jpg",
]

os.makedirs("assets/images", exist_ok=True)

BG = (0, 102, 204)  # blu
FG = (255, 255, 255) # bianco
SIZE = (1200, 800)

for path in REQUIRED_IMAGES:
    if os.path.exists(path):
        continue
    img = Image.new("RGB", SIZE, BG)
    draw = ImageDraw.Draw(img)
    text = os.path.basename(path)
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None
    # centrare il testo (approssimazione con textlength)
    tw = draw.textlength(text, font=font)
    th = 14
    x = max(10, (SIZE[0] - tw) / 2)
    y = max(10, (SIZE[1] - th) / 2)
    draw.text((x, y), text, fill=FG, font=font)
    img.save(path, format="JPEG", quality=90)
    print(f"[Placeholder] creato {path}")

print("Segnaposto immagini: ok")
EOF

echo "==> Scrittura src/qrcodes.csv"
cat > src/qrcodes.csv << 'EOF'
code_id,url,label
U1-01,https://example.org/audio/U1-01.mp3,Presentazioni brevi
U1-02,https://example.org/audio/U1-02.mp3,Domande lente e chiare
U2-01,https://example.org/audio/U2-01.mp3,La giornata di Amir
U2-02,https://example.org/audio/U2-02.mp3,Orologio parlante
U3-01,https://example.org/audio/U3-01.mp3,Regole della comunità
U3-02,https://example.org/audio/U3-02.mp3,Chiedere permesso
U4-01,https://example.org/audio/U4-01.mp3,Annunci offerte
U4-02,https://example.org/audio/U4-02.mp3,Alla cassa: prezzi e resto
EOF

echo "==> Scrittura unità (Markdown)"
cat > src/units/unita-01-mi-presento.md << 'EOF'
# Unità 1. Mi presento
Percorso A1 per minori stranieri non accompagnati. Linguaggio semplice, esempi, immagini, attività.

Obiettivi
- Dire nome, età, paese/nazionalità, lingua/e, città dove abito.
- Chiedere le stesse informazioni a un’altra persona.
- Scrivere una breve presentazione.

Parole chiave
- nome, cognome, età, anni, data di nascita, paese, città, nazionalità, lingua, Italia, comunità
- io, tu, lui, lei; mi chiamo…, sono…, ho … anni, parlo…, abito a/in…

Frasi utili (modelli)
- Mi chiamo Amina. Ho 16 anni. Sono del Marocco. Abito a Firenze. Parlo arabo e un po’ di italiano.
- Come ti chiami? Quanti anni hai? Di dove sei? Quali lingue parli?
- Lui/Lei si chiama … Ha … anni. È di … Parla …

Dialogo 1 (saluti e presentazione)
A: Ciao! Mi chiamo Sara. E tu?
B: Ciao! Mi chiamo Omar.
A: Quanti anni hai?
B: Ho 17 anni. E tu?
A: Ho 16 anni. Di dove sei?
B: Sono del Senegal. E tu?
A: Io sono italiana. Benvenuto!

Dialogo 2 (presentare un amico)
A: Ciao educatore, lui è Moussa.
B: Piacere, Moussa! Quanti anni hai?
C: Ho 15 anni. Parlo francese e un po’ di italiano.

Immagini
- ![Due ragazzi si presentano](../../assets/images/u1-saluto.jpg)
- ![Mappa con frecce verso l’Italia](../../assets/images/u1-mappa-italia-mondo.jpg)
- ![Esempio di badge con nome, paese e lingue](../../assets/images/u1-badge-esempio.jpg)

Grammatica facile
- Essere: io sono, tu sei, lui/lei è
- Chiamarsi: io mi chiamo, tu ti chiami, lui/lei si chiama
- Avere (età): io ho 16 anni, tu hai 17 anni, lui/lei ha 15 anni
- Città/paese:
  - Abito a + città (a Roma, a Firenze)
  - Sono del/della + paese (del Senegal, della Guinea)
  - In + paese femminile/plurale (in Italia, in Francia); in + regioni/grandi aree (in Europa)

Pronuncia
- Gli: famiglia [fa-mi-lya], figlio [fi-lyo]
- Gn: bagno [ba-nyo]
- C + i/e = [ci]/[ce]: ciao, cena | Ch + i/e = [ki]/[ke]: chi, parcheggio

Ascolto (QR)
- QR Presentazioni: ![QR U1-01](../../assets/qrcodes/U1-01.png) – Presentazioni brevi
- QR Domande: ![QR U1-02](../../assets/qrcodes/U1-02.png) – Domande lente e chiare
Trascrizioni (per l’educatore)
- U1-01A: “Mi chiamo Youssef. Ho sedici anni. Sono del Marocco. Parlo arabo e un po’ di italiano.”
- U1-01B: “Ciao, sono Lila. Ho quindici anni. Sono della Guinea. Parlo francese.”
- U1-02: “Come ti chiami? Quanti anni hai? Di dove sei? Quali lingue parli?”

Attività
1) Pair-work: scambio di presentazioni
- Obiettivo: dire 4 frasi su di sé.
- Istruzioni: prepara un cartellino nome/paese. Parla con 3 compagni. Usa le frasi modello.
2) Scheda: completa e scrivi
- Mi chiamo ________. Ho ____ anni. Sono di ________. Abito a ________. Parlo ________.
- Scrivi 3 domande per un compagno.
3) Memory: bandiera–paese–lingua (carte da ritagliare)
4) Ascolto (QR U1-01): sbarra le info corrette (nome / età / paese / lingua).
5) Presento un compagno (orale)
- Intervista il compagno. Poi presenta: “Lui/Lei si chiama … Ha … anni. È di … Parla …”

Cultura e convivenza
- Salutare guardando negli occhi e con un sorriso è segno di rispetto.
- In Italia si usa “ciao” tra coetanei e “buongiorno/buonasera” con adulti o persone nuove.

Progetto
- Crea il tuo badge con foto (opzionale), nome, paese, lingue, città.

Verifica (A1)
- Ascolto U1-01 (scelta) • Lettura (5 domande) • Scrittura (5 frasi) • Orale (dialogo guidato)

Note accessibilità
- Frasi brevi, font grande, immagini con alt text, esempi concreti e vicini alla loro esperienza.
EOF

cat > src/units/unita-02-la-mia-giornata.md << 'EOF'
# Unità 2. La mia giornata

Obiettivi
- Dire l’ora e parlare delle attività quotidiane.
- Descrivere la routine in comunità e a scuola.
- Scrivere un semplice orario personale.

Parole chiave
- mattina, pomeriggio, sera, notte
- svegliarsi, alzarsi, lavarsi, vestirsi, fare colazione, andare a scuola, pranzare, studiare, giocare, fare la doccia, cenare, dormire
- alle …, e un quarto (:15), e mezza (:30), meno un quarto (:45)

Frasi utili (modelli)
- Mi sveglio alle 7:00. Faccio colazione alle 7:30.
- Vado a scuola alle 8:15. Rientro alle 14:00.
- Il pomeriggio studio e gioco a calcio.
- Ceno alle 19:30. Vado a dormire alle 22:30.

Immagini e grafici
- [Linea del tempo con attività della giornata – inserire come grafico esterno]
- ![Orologio analogico con lancette](../../assets/images/u2-orologio.jpg)
- ![Colazione italiana](../../assets/images/u2-colazione-italiana.jpg)

Grammatica facile
- Ore con “alle”: alle 7; alle 8 e un quarto (8:15); alle 8 e mezza (8:30); alle 9 meno un quarto (8:45).
- Verbi riflessivi (io): mi sveglio, mi alzo, mi lavo, mi vesto.
- Verbi: vado (andare), faccio (fare), prendo (il bus), studio (studiare), gioco (giocare).
- la mattina, il pomeriggio, la sera.

Pronuncia
- Gn: bagno [ba-nyo]
- Sc: scuola [skuò-la] vs sciare [scià-re]
- Doppie: mattina (tt), lezione (z dolce)

Ascolto (QR)
- QR Giornata: ![QR U2-01](../../assets/qrcodes/U2-01.png) – La giornata di Amir
- QR Orologio: ![QR U2-02](../../assets/qrcodes/U2-02.png) – Orologio parlante
Trascrizioni (per l’educatore)
- U2-01: “Mi sveglio alle sette. Faccio colazione alle sette e mezza. Vado a scuola alle otto e un quarto. Rientro alle due. Il pomeriggio studio e gioco. Ceno alle sette e mezza. Vado a dormire alle dieci e mezza.”
- U2-02: “Sono le sette e un quarto. Sono le otto e mezza. Sono le nove meno un quarto. Sono le due.”

Attività
1) Ordina la giornata (carte)
- Metti in ordine 8 carte con immagini. Poi racconta: “Prima mi sveglio…”
2) Scrivi il tuo orario
- Tabella: Ora | Attività. Inserisci almeno 6 attività con orari.
3) Intervista tra pari
- “A che ora ti svegli/vai a scuola/pranzi/studi/ceni/dormi?”
4) Ascolto (U2-02)
- Scegli l’orario corretto tra tre opzioni.
5) Gioco “Bingo orario”
- Cartelle con 9 orari. L’educatore legge frasi. Chi completa una riga dice “BINGO!”.

Cultura e convivenza
- In molte scuole italiane le lezioni iniziano alle 8–9. In comunità ci sono orari comuni per pasti e silenzio.

Progetto
- Poster “La mia giornata” con immagini e frasi.

Verifica (A1)
- Ascolto U2-01 • Lettura (orario) • Scrittura (6 frasi con orari) • Orale (chiedi/dai 4 orari)
EOF

cat > src/units/unita-03-in-comunita-regole-turni-spazi.md << 'EOF'
# Unità 3. In comunità: regole, turni, spazi comuni

Obiettivi
- Capire e rispettare le regole della comunità.
- Parlare di turni e spazi comuni.
- Chiedere permesso in modo gentile.

Parole chiave
- regola, orario, silenzio, pulizie, turno, calendario, cucina, sala, camera, bagno, lavanderia, cortile
- rispetto, permesso, vietato, obbligatorio
- si deve…, è vietato…, si può…

Frasi utili (modelli)
- Si deve spegnere la luce alle 23:00.
- È vietato fumare in camera.
- Si può usare la sala dalle 16 alle 18.
- Oggi ho il turno di cucina. Domani ho il turno di pulizie.
- Posso usare il telefono? Posso uscire alle 17:00?
- Devo parlare con l’educatore.

Immagini
- ![Tabella turni settimanale al muro](../../assets/images/u3-tabella-turni.jpg)
- ![Spazi comuni ordinati](../../assets/images/u3-spazi-comuni.jpg)

Grammatica facile
- Si deve + infinito: Si deve pulire la cucina.
- È vietato + infinito: È vietato mangiare in camera.
- Si può + infinito: Si può studiare in sala.
- Posso + infinito? (chiedere permesso)
- Devo + infinito (obbligo personale)

Pronuncia
- S impura: studio [stù-dio], spazi [spà-zi]
- Z: pulizie [pulizì-e], spesa [spè-sa]

Ascolto (QR)
- QR Regole: ![QR U3-01](../../assets/qrcodes/U3-01.png) – Regole della comunità
- QR Permesso: ![QR U3-02](../../assets/qrcodes/U3-02.png) – Chiedere permesso
Trascrizioni (per l’educatore)
- U3-01: “Si deve rispettare il silenzio dalle ventidue e trenta. È vietato fumare in camera. Si può usare la cucina dalle diciassette alle diciannove. Si deve pulire dopo aver cucinato…”
- U3-02A: “Posso chiamare mia sorella alle diciotto?” “Sì, puoi, per dieci minuti.”
- U3-02B: “Posso uscire alle diciassette?” “No, oggi no. C’è studio fino alle diciotto.”

Attività
1) Vero/Falso regolamento (8 frasi)
2) Role-play “permesso” (carte-situazione: telefonare, uscire, usare la sala, invitare un amico, doccia lunga)
3) Crea la tabella turni (lun–dom: cucina, pulizie, rifiuti)
4) Cartelli di avviso: “Silenzio”, “È vietato fumare”, “Si deve spegnere la luce”

Cultura e convivenza
- Condividere spazi = rispettare gli altri: parlare a bassa voce, pulire dopo l’uso, ascoltare le regole.
- In caso di conflitto: fermarsi, respirare, parlare con un educatore.

Progetto
- Poster “La nostra comunità” con foto degli spazi e 1 regola per spazio.

Verifica (A1)
- Ascolto U3-01 (V/F) • Lettura (regolamento breve) • Scrittura (5 regole) • Orale (permessi: 3 situazioni)
EOF

cat > src/units/unita-04-al-supermercato.md << 'EOF'
# Unità 4. Al supermercato: cibi, prezzi, lista della spesa

Obiettivi
- Conoscere cibi comuni e reparti del supermercato.
- Chiedere prezzi, leggere etichette e pagare.
- Scrivere una lista della spesa e calcolare il totale.

Parole chiave
- Cibi base: pane, pasta, riso, latte, uova, formaggio, yogurt, pollo, pesce, olio, sale, zucchero, farina, pomodori, mele, banane, patate, cipolle, acqua
- Reparti: frutta e verdura, panetteria, latticini, carne, pesce, bevande, surgelati, igiene
- Acquisto: carrello, cestino, prezzo, offerta, sconto, euro, centesimi, cassa, scontrino, tessera punti
- Quantità: un chilo (1 kg), mezzo chilo (500 g), un litro (1 L), una bottiglia, una confezione, un pacco

Frasi utili (modelli)
- Quanto costa? Costa 1,50 € (un euro e cinquanta centesimi).
- Dov’è il reparto frutta e verdura?
- Vorrei un chilo di mele, per favore.
- È in offerta? Sì, c’è lo sconto del 20%.
- Pago in contanti/con carta. Ecco lo scontrino.

Dialogo 1 (cercare un prodotto)
Cliente: Buongiorno, dov’è la pasta?
Commesso: In corsia tre, a sinistra.
Cliente: Grazie. È in offerta?
Commesso: Sì, questo pacco costa 1,10 €.

Dialogo 2 (alla cassa)
Cassiera: Buongiorno. Ha la tessera punti?
Cliente: Sì, eccola.
Cassiera: Sono 6,30 €. Contanti o carta?
Cliente: Contanti. Ecco 10 €.
Cassiera: Il resto è 3,70 €. Ecco lo scontrino.

Immagini e grafici
- ![Carrello con alimenti essenziali](../../assets/images/u4-carrello-cibi.jpg)
- ![Cartellini prezzo chiari](../../assets/images/u4-etichette-prezzo.jpg)

Grammatica facile
- Numeri e prezzi: virgola per i decimali (1,50 €).
- Vorrei + nome (formula gentile).
- Questo/Questa/Questi/Queste: questo riso; questa pasta; questi pomodori; queste mele.
- Di + quantità: un chilo di mele; mezzo chilo di pane.

Pronuncia
- Ce/Ci – Che/Chi: ceci [ce-ci], chilo [ki-lo]
- G dolce/duro: gelato [je], grana [g]

Ascolto (QR)
- QR Offerte: ![QR U4-01](../../assets/qrcodes/U4-01.png) – Annunci di offerte
- QR Cassa: ![QR U4-02](../../assets/qrcodes/U4-02.png) – Alla cassa: prezzi e resto
Trascrizioni (per l’educatore)
- U4-01: “Pasta a un euro e dieci. Latte a uno e trenta. Mele a due e quaranta al chilo.”
- U4-02: “Totale sei euro e trenta. Contanti o carta? Il resto è tre euro e settanta.”

Attività
1) Volantini veri: trova 5 prezzi e scrivi la lista (prodotto + prezzo).
2) Role-play cliente–commesso: reparto, prezzo, offerta, quantità.
3) Calcolo del resto: paga 5,00 € con 10 €; paga 7,80 € con 20 €.
4) Etichette e quantità: abbina “un chilo/mezzo chilo/una bottiglia/una confezione” alle immagini.
5) Lista della spesa: Prodotto | Quantità | Prezzo | Totale parziale. Somma il totale.

Cultura e convivenza
- In fila alla cassa si aspetta il proprio turno.
- Porta la borsa riutilizzabile per l’ambiente.

Progetto
- “Spesa per una settimana”: budget 25 €. Scegli 8–10 prodotti, calcola il totale e spiega le scelte.

Verifica (A1)
- Ascolto U4-01 (associa prodotto–prezzo) • Lettura (scontrino) • Scrittura (lista 3 giorni) • Orale (prezzi e quantità)
EOF

echo "==> Scrittura guida educatore"
cat > src/educatori/guida-educatore.md << 'EOF'
# Guida per l’educatore – Unità 1–4 (A1 – MSNA)

Obiettivi generali
- Dare strumenti linguistici per la vita quotidiana in Italia (comunità, scuola, città).
- Favorire rispetto delle regole, autonomia e comunicazione essenziale.
- Approccio visivo, multisensoriale e graduale.

Metodologia
- Input comprensibile: frasi brevi, gesti, oggetti reali, immagini grandi.
- Ciclo: modello (ascolto/lettura) → pratica guidata (ripetizione/role-play) → produzione (scrittura/orale).
- Task autentici: moduli veri, volantini, orari reali, prezzi reali.
- Inclusione e sensibilità: evitare contenuti potenzialmente trigger; offrire alternative.

Gestione QR e audio
- Usa src/qrcodes.csv per collegare gli audio (URL pubblici).
- Registra audio lenti, chiari (80–100 wpm), con pause.
- Ripeti elementi chiave 2 volte; inserisci effetti minimi (beep per domande).

Valutazione A1 (criteri sintetici)
- Comprensione: cogliere parole chiave (60%).
- Produzione scritta: frasi semplici SVO, 4–6 frasi corrette su schema.
- Interazione: risposte brevi e pertinenti a domande note.
- Pronuncia: intelligibile; tollerare interferenze fonetiche.

Differenziazione
- Semplifica: immagini e frasi modello da completare.
- Potenzia: aggiungi “perché…” o “poi…” per concatenare frasi.
- Supporto L1: glossari locali (francese/arabo) a margine se disponibili.

Unità 1 – Mi presento
- Obiettivi: presentarsi, chiedere dati base. 
- Materiali: cartellini nome, mappa, carte bandiere/lingue.
- Sequenza consigliata (60–90’):
  1) Warm-up con saluti + immagine (5’)
  2) Ascolto QR U1-01 + comprensione (10’)
  3) Ripetizione frasi modello (10’)
  4) Pair-work presentazioni (15’)
  5) Scheda completamento (10’)
  6) Presento il compagno (10’)
- Valutazione: scheda 5 frasi; orale guidato.

Unità 2 – La mia giornata
- Focus: orari, routine, riflessivi base.
- Materiali: orologio didattico, carte-sequenza.
- Sequenza (60–90’): ascolto U2-02 → gioco Bingo → scrittura orario → intervista.

Unità 3 – In comunità
- Focus: si deve / è vietato / si può; chiedere permesso.
- Sequenza: lettura regolamento (poster) → V/F → role-play permesso → costruzione tabella turni.

Unità 4 – Supermercato
- Focus: cibi, prezzi, quantità, resto.
- Sequenza: volantino reale → role-play → esercizi resto → lista spesa → mini spesa simulata.

Rubriche rapide (0–2 per voce)
- Accuratezza: 0=molti errori; 1=alcuni; 2=corretto.
- Lessico: 0=molto limitato; 1=essenziale; 2=adeguato.
- Interazione: 0=non risponde; 1=risponde con aiuto; 2=gestisce scambio breve.

Soluzioni (schede principali)
- U1 Scheda presentazione: info libere; verifica presenza di 5 informazioni base.
- U2 Orari: 7:00; 7:30; 8:15; 14:00; 19:30; 22:30.
- U3 V/F: dipende dal regolamento distribuito; suggerire correzione della frase.
- U4 Resti: 10–6,30=3,70; 20–7,80=12,20.

Safety e benessere
- Evitare domande potenzialmente sensibili (famiglia, viaggio) se non proposte dallo studente.
- Consentire
