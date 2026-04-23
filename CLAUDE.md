# CLAUDE.md

**Acest fișier e citit automat de Claude Code for VS Code când deschizi folder-ul acestui repo.**
Conține reguli specifice pentru PsyMind.app.

---

## Project: PsyMind.app

**Descriere:** App internațional pentru crearea, evaluarea și optimizarea sugestiilor hipnotice.
**Stack:** vanilla HTML (`index.html` root) + `api/*.js` Vercel Serverless ESM + Supabase + Resend + Stripe.
**NO Next.js. NO build step.**

---

## Reguli obligatorii

### 1. Always inspect existing files before editing.
Deschide fișierul, citește contextul. Nu scrie pe presupunere.

### 2. Never assume framework if project is vanilla.
Acest proiect e vanilla. Nu introduce React, Vue, Next.js, Vite, Angular etc. sub nicio formă fără aprobare explicită scrisă.

### 3. Plan first.
Înainte de edit:
- Identifică fișierele afectate
- Explică planul în 3-5 linii
- Așteaptă doar dacă ambiguitatea blochează execuția

### 4. Edit only relevant files.
Nu atinge fișiere în afara scope-ului. Zero „while I'm here, let me also refactor X".

### 5. Preserve naming conventions.
- Funcție evaluator: `runEval()` (NU `evaluate()` — conflict `Document.evaluate`)
- API handlers: `export default async function handler(req, res)`
- Module JS externe: `lowercase-kebab.js`

### 6. Do not introduce dependencies unless explicitly approved.
`package.json` e minimal (`"type":"module"`, `node>=18`, zero deps). Keep it that way unless Eugen OK's.

### 7. After edit:
- Run syntax checks if available (`node --check api/file.js`)
- List files changed (exact paths)
- Explain risks
- List manual checks needed (ex. „test generator flow în browser")

### 8. For large changes, split into phases.
Dacă task-ul afectează >3 fișiere sau >200 linii, propui plan în faze; execuți pe bucăți cu aprobare între ele.

### 9. If task conflicts with another active branch/chat, warn first.
Check `git log --oneline -5`. Dacă ultimele commits sunt foarte recente sau arată muncă paralelă → atenționezi.

---

## PsyMind.app — reguli specifice

### Frontend
- **Main file:** `index.html` în root (~611 KB). Nu crea `index.html` în alt folder.
- **Pagini auxiliare:** `start.html`, `privacy.html`, `embed.html`.
- **Module JS extrase:** `supabase-auth.js`, `course_recommender_v2.js`, `lead.js`, `log-eval.js`, `verify-otp.js`, `sw.js`, `manifest.json`.
- **Main eval function:** `runEval()`, **NU** `evaluate()`.

### Backend
- `api/*.js` Vercel Serverless. **ESM** (`export default async function handler`).
- Endpoints existente: `evaluate`, `generate`, `daily-affirmation`, `meditation-audio` (+ `_meditation-audio`), `transcribe`, `send-suggestions/-result/-verification`, `verify-otp`, `create-checkout`, `stripe-webhook`, `contact`, `lead`, `locale`, `config`, `log-eval`.
- NU adăuga endpoint-uri fără aprobare.

### Supabase
- Project ref: `phscathhvjtbcbdbfehs`
- Auth: OTP email
- Client importat din CDN UMD: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js`
- **`SUPABASE_SERVICE_ROLE_KEY` NICIODATĂ în client.** Doar în `api/*.js`.

### Secrete
- Toate în Vercel env vars.
- `.env.local` în `.gitignore`.
- Zero hardcodat în cod.

### Mobile-first
- 80%+ useri pe telefon.
- Zero `100vw` (cauzează overflow orizontal mobile).
- Touch targets ≥44×44px.
- Inputs `font-size ≥16px` (altfel iOS zoom la focus).

### i18n
- UI English-first. Zero strings RO hardcodate în UI.
- Content generat urmează limba input user.
- Limbi: live `en`. Plan: `fr`, `es`, `pt`, `it`, `ro`, `hi`, `zh`.

### Livrări
- Dacă schimbare funcțională frontend → **livrezi `index.html` COMPLET**.
- Dacă schimbare funcțională backend → **livrezi `api/*.js` COMPLET**.
- Dacă schimbare afectează UI + prompt + scoring → le tratezi împreună în aceeași livrare.

---

## Known bugs — do NOT reintroduce

Vezi lista completă în `psymind-instructions/ERROR_CATALOG.md`. Top 5:

1. **Nu adăuga event listeners pe `hashchange`** care resetează wizard state.
2. **Post-OTP verify → hidratare IMEDIATĂ** (fără `window.location.reload`).
3. **Cleanup overlay-uri stale** pe TOATE căile (success, error, cancel).
4. **Parsing răspuns model defensiv** (try/catch + fallback pentru JSON malformat).
5. **`sessionStorage` post-auth intent:** set ÎNAINTE de OTP redirect, citit DUPĂ hidratare.

---

## Checklist pre-livrare rapid

- [ ] `node --check` trece pentru fișierele `api/*.js` modificate
- [ ] HTML: DIV balance, overlay-uri ÎNAINTE de script care le folosește
- [ ] Zero `console.log` rezidual
- [ ] Zero `100vw`
- [ ] `runEval()` nu `evaluate()`
- [ ] `export default` pentru `api/*.js`
- [ ] Secrete serverside only
- [ ] RO hardcodat zero în UI

---

## Workflow Claude Code

1. Eugen spune task-ul.
2. Claude citește fișierele relevante.
3. Claude propune plan (3-5 linii).
4. Eugen aprobă.
5. Claude face edits in-place.
6. Claude rulează syntax checks.
7. Claude listează: files changed, what changed, risks, manual tests needed.
8. Eugen face `git commit` + `git push` (sau Claude cu aprobare).
9. Vercel face redeploy automat.

---

Referințe complete în: repo `psymind-instructions` (privat).
