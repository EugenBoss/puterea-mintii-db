# Puterea Minții — Knowledge Base & Triage System

Infrastructură Supabase pentru ecosistemul PM: RAG semantic search peste sursele triajate + sistem atomic de rezervare ID-uri pentru triaje paralele.

Codul aici e sursa de adevăr. La `git push` pe `main`, GitHub Actions deployează automat pe Supabase.

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

├── deploy-functions.yml              # auto-deploy Edge Functions

└── deploy-migrations.yml             # auto-apply SQL migrations

```

**Nu sunt încă versionate în repo:** `knowledge-search`, `knowledge-ingest`, `knowledge-list`, `knowledge-delete`, `knowledge-fetch`. Sunt live pe Supabase și stabile. Când vrem să le modificăm, le descărcăm cu:

```bash

supabase functions download knowledge-search --project-ref phscathhvjtbcbdbfehs

# etc

```

---

## Setup CI/CD (o singură dată)

`Settings → Secrets and variables → Actions → New repository secret`:

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

Editezi fișier (browser GitHub sau local) → commit → Actions deployează în ~30 sec.

### Migrare SQL nouă

Creezi `supabase/migrations/YYYYMMDDHHMMSS_descriere.sql` cu formule idempotente (`if not exists`, `on conflict`) → commit → Actions aplică.

---

## Endpoints live

Base: `https://phscathhvjtbcbdbfehs.supabase.co/functions/v1/`

Auth: `Authorization: Bearer pm_knowledge_2026_secure`

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

  -H "Authorization: Bearer pm_knowledge_2026_secure"

```

---

## Counters (19 apr 2026)

N=152 · C=324 · T=305 · B=134 · S=107 · IND=55

Documentație completă workflow triaj: `PROMPT_TRIAJ_SURSE_v6_4_MASTER` (în project knowledge Claude).
