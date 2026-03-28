import pandas as pd
import sqlite3
import os

CSV_PATH = 'assets/warsh.csv'
DB_PATH  = 'assets/db/quran_warsh.db'

os.makedirs('assets/db', exist_ok=True)

# ── 1. Load CSV ──────────────────────────────────────────────────────────────
df = pd.read_csv(CSV_PATH, sep=',', encoding='utf-8')

print(f"Loaded {len(df)} rows")
print(df.head(3))

# ── 2. Connect to SQLite ─────────────────────────────────────────────────────
conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

# ── 3. Create verses table (direct from CSV columns) ─────────────────────────
c.execute('''
  CREATE TABLE IF NOT EXISTS verses (
    id          INTEGER PRIMARY KEY,
    juz         INTEGER NOT NULL,
    page        INTEGER NOT NULL,
    sura_no     INTEGER NOT NULL,
    sura_name_en TEXT NOT NULL,
    sura_name_ar TEXT NOT NULL,
    line_start  INTEGER NOT NULL,
    line_end    INTEGER NOT NULL,
    aya_no      INTEGER NOT NULL,
    aya_text    TEXT NOT NULL
  )
''')

# ── 4. Create surahs table (derived from verses) ────────────────────────────
c.execute('''
  CREATE TABLE IF NOT EXISTS surahs (
    sura_no      INTEGER PRIMARY KEY,
    sura_name_en TEXT NOT NULL,
    sura_name_ar TEXT NOT NULL,
    verses_count INTEGER NOT NULL,
    page_start   INTEGER NOT NULL,
    juz_start    INTEGER NOT NULL,
    has_basmala  INTEGER NOT NULL DEFAULT 1
  )
''')

# ── 5. Insert verses ─────────────────────────────────────────────────────────
df_renamed = df.rename(columns={'jozz': 'juz'})

# Force numeric columns to Python int so SQLite sees them as INTEGER
int_cols = ['id', 'juz', 'page', 'sura_no', 'line_start', 'line_end', 'aya_no']
for col in int_cols:
    df_renamed[col] = df_renamed[col].astype(int)

df_renamed.to_sql('verses', conn, if_exists='replace', index=False)
print("Inserted verses ✓")

# ── 6. Build surahs from verses data ─────────────────────────────────────────
surahs_df = df.groupby('sura_no').agg(
    sura_name_en=('sura_name_en', 'first'),
    sura_name_ar=('sura_name_ar', 'first'),
    verses_count=('aya_no', 'max'),
    page_start=('page', 'min'),
    juz_start=('jozz', 'min'),
).reset_index()

# Surah 9 (At-Tawbah) has no Basmala
surahs_df['has_basmala'] = surahs_df['sura_no'].apply(lambda x: 0 if x == 9 else 1)

surahs_df.to_sql('surahs', conn, if_exists='replace', index=False)
print("Inserted surahs ✓")

# ── 7. Create indexes for fast queries ───────────────────────────────────────
c.execute('CREATE INDEX IF NOT EXISTS idx_verses_page   ON verses(page)')
c.execute('CREATE INDEX IF NOT EXISTS idx_verses_sura   ON verses(sura_no)')
c.execute('CREATE INDEX IF NOT EXISTS idx_verses_juz    ON verses(juz)')
c.execute('CREATE INDEX IF NOT EXISTS idx_verses_search ON verses(aya_text)')

# ── 8. Set version for future DB updates ────────────────────────────────────
c.execute('PRAGMA user_version = 1')

conn.commit()
conn.close()

db_size = os.path.getsize(DB_PATH) / 1024
print(f"\\nDone! DB saved to: {DB_PATH}")
print(f"Size: {db_size:.1f} KB")
print("\\nVerify with: sqlite3 assets/db/quran_warsh.db \\'SELECT * FROM verses LIMIT 5\\'")
