# AI_WORKFLOW_RULES.md

Reguli pentru orice AI cu acces direct la acest repo (Codex, Claude Code, Claude VS Code, ChatGPT cu GitHub connector).

---

## Înainte să editezi cod:

1. **Read relevant files first.** Nu începe cu write.
2. **Summarize current state.** Ce fac fișierele pe care urmează să le modifici.
3. **Identify exact files to modify.** Nu atinge nimic în afara scope-ului.
4. **Make a short plan.** Arată planul user-ului înainte să execuți.
5. **Ask only if ambiguous.** Max 2 întrebări. Dacă nu e ambiguu, procedezi.
6. **Prefer minimal targeted edits.** Nu rewrite-uri complete.
7. **Do not rewrite whole files** unless required (ex. `index.html` la schimbare funcțională majoră — conform regulii din PROJECT_INSTRUCTIONS).

## După edits:

1. **Report factually:**
   - Files changed (exact paths)
   - What changed (1-2 linii per fișier)
   - Risks identified
   - Tests/checks needed (și run the ones available: `node --check`, linting)
2. **Warn if another active task** may touch the same files (paralel chat-uri).
3. **Keep DONE / CURRENT / NEXT** status în mesaj.

---

## Project-specific rules (PsyMind.app)

### Stack (non-negociabil)
- Frontend: **vanilla HTML one-file** (`index.html` în root, ~611 KB).
- Backend: `api/*.js` Vercel Serverless Functions, **ESM** (`export default`).
- **No framework JS.** Zero Next.js, React, Vue, Vite, Angular etc.
- **No build step.** Ce comiți e ce rulează.

### Funcții frontend
- Funcția de evaluare se numește **`runEval()`**, NU `evaluate()` (conflict cu `Document.evaluate`).

### Livrări
- Când frontend se schimbă funcțional → **livrezi `index.html` COMPLET**.
- Când backend se schimbă → **livrezi `api/*.js` COMPLET**.
- Dacă schimbările afectează UI + prompt + scoring + logică → le tratezi împreună.

### Convenții
- Secrete **NICIODATĂ** în client. Toate vin din `process.env.*` în serverless functions.
- Client folosește DOAR `SUPABASE_ANON_KEY` (publishable).
- `SUPABASE_SERVICE_ROLE_KEY` **NICIODATĂ** în `index.html`.

### i18n
- UI English-first. Zero RO hardcodat.
- Content generat urmează limba input user.

### Mobile-first
- Zero `100vw` (overflow orizontal).
- Touch targets ≥44×44px.
- Inputs `font-size ≥16px` (evită zoom iOS).

### Criterii evaluator
- Framework v4.0: 5 basic (gate) + 14 advanced.
- UI actual: 3/9 criterii (pre-v4.0). Ridicarea UI → task dedicat, nu casual.

### Known bug patterns (do NOT reintroduce)
Vezi `ERROR_CATALOG.md` din repo `psymind-instructions`. Pe scurt:
- Nu adăuga event listeners pe `hashchange` care resetează wizard state.
- Post-OTP verify → hidratare imediată (fără reload).
- Cleanup overlay-uri pe TOATE căile.
- Parsing răspuns model cu try/catch + fallback.
- `sessionStorage` post-auth: set înainte redirect, get după hidratare.

---

## Conflict warning

Dacă observi că există chat-uri paralele (Codex + Claude + ChatGPT) lucrând pe același fișier simultan:
- **Avertizezi user-ul explicit.**
- **Refuzi să livrezi** până nu confirmă care chat e „owner" al task-ului.
- Sugerezi branch-uri git separate pentru paralelism real.

---

## Status tracking în mesaj

În fiecare răspuns mai lung (task cu >1 pas), pui la final:

```
### Status
- DONE: [ce am livrat]
- CURRENT: [ce lucrez acum]
- NEXT: [ce urmează]
```

---

Referințe complete: [psymind-instructions](https://github.com/EugenBoss/psymind-instructions) (repo privat).
