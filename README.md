# Puterea Minții — Knowledge Base & Triage System

Infrastructură Supabase pentru ecosistemul PM: RAG semantic search peste sursele triajate + sistem atomic de rezervare ID-uri pentru triaje paralele.

Codul aici e sursa de adevăr pentru schema și Edge Functions Supabase.

Important: în acest repo nu există momentan GitHub Actions active. Un `git push` pe `main` NU aplică automat migrații și NU deployează Edge Functions. Deploy-ul se face manual până când CI/CD este reintrodus explicit.

---

## Structură

```

supabase/

├── config.toml

├── migrations/

│   └── 20260418160257_triage_reservation_system.sql

└── functions/

    ├── _shared/utils.ts              # helpers auth + CORS

    ├── triage-reserve/               # alocare atomică ID-uri

    ├── triage-commit/                # marchează ID-uri folosite

    ├── triage-status/                # counters + active reservations

    └── triage-batch/                 # ingest + commit + delete într-o tranzacție

.github/workflows/

├── deploy-functions.yml              # nu există momentan

└── deploy-migrations.yml             # nu există momentan

```

**Notă:** `knowledge-search` și `knowledge-list` sunt menționate ca funcții live în proiect, dar nu sunt versionate în acest repo. `knowledge-ingest`, `knowledge-delete` și `knowledge-fetch` sunt versionate aici. Când vrem să modificăm funcții live neversionate, le descărcăm întâi cu:

```bash

supabase functions download knowledge-search --project-ref phscathhvjtbcbdbfehs

# etc

```

---

## Setup CI/CD (opțional, momentan neconfigurat)

Pentru a reactiva deploy automat, trebuie create workflow-urile în `.github/workflows/` și apoi configurate secrets în `Settings → Secrets and variables → Actions`:

| Nume | Valoare |

|------|---------|

| `SUPABASE_ACCESS_TOKEN` | Generat la [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) |

| `SUPABASE_PROJECT_REF` | `phscathhvjtbcbdbfehs` |

| `SUPABASE_DB_PASSWORD` | Supabase Dashboard → Project Settings → Database → parola DB |

## Workflow zilnic

### Triaj nou (Claude face automat)

1. `triage-reserve` → alocă ID-uri atomic

2. Analiză sursă pe 17 axe

3. `triage-batch` → ingest toate addendumurile + commit IDs + delete STATUS vechi

### Modificare cod

Editezi fișier (browser GitHub sau local) → commit. Deploy-ul Edge Functions se face manual până când există workflow-uri active.

### Migrare SQL nouă

Creezi `supabase/migrations/YYYYMMDDHHMMSS_descriere.sql` cu formule idempotente (`if not exists`, `on conflict`) → commit. Aplicarea în Supabase se face manual până când există workflow-uri active.

---

## Endpoints live

Base: `https://phscathhvjtbcbdbfehs.supabase.co/functions/v1/`

Auth: `Authorization: Bearer <PM_KNOWLEDGE_KEY>`

| Endpoint | Scop |

|---------|------|

| `knowledge-search` | Semantic search |

| `knowledge-ingest` | Ingest + chunking + embedding |

| `knowledge-list` | List documente |

| `knowledge-delete` | Delete după filename |

| `knowledge-fetch` | Full text document |

| `triage-reserve` | Alocă N ID-uri atomic |

| `triage-commit` | Marchează IDs ca committed |

| `triage-status` | Counters + active reservations |

| `triage-batch` | Ingest + commit + delete (tranzacție) |

## Test rapid

```bash

curl -s -X POST https://phscathhvjtbcbdbfehs.supabase.co/functions/v1/triage-status \

  -H "Authorization: Bearer $PM_KNOWLEDGE_KEY"

```

---

## Counters (19 apr 2026)

N=152 · C=324 · T=305 · B=134 · S=107 · IND=55

Documentație completă workflow triaj: `PROMPT_TRIAJ_SURSE_v6_4_MASTER` (în project knowledge Claude).
