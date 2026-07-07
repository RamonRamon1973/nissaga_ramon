# La Nissaga Ramon — guia de publicació

Aquesta carpeta conté una aplicació web completa i funcional (l'he provada jo mateix amb les teves 140 persones abans de lliurar-te-la). Et falten **tres passos de "copia i enganxa"** per tenir-la publicada i compartida amb la família.

Ja tens els comptes de GitHub, Vercel i Supabase creats, així que anem directes.

---

## Pas 1 — Crear la base de dades a Supabase

1. Entra al teu compte de Supabase → **New project** (dona-li el nom que vulguis, p. ex. `nissaga-ramon`)
2. Un cop creat, ves a l'apartat **SQL Editor** (al menú de l'esquerra)
3. Obre el fitxer `schema.sql` d'aquesta carpeta, copia'n tot el contingut, enganxa'l a l'editor SQL i prem **Run**
4. Fes el mateix amb el fitxer `seed.sql` (aquest conté les 140 persones i 103 famílies) — copia, enganxa, **Run**
5. Ves a **Project Settings → API** i apunta't dos valors:
   - **Project URL** (una cosa com `https://xxxxxxxx.supabase.co`)
   - **anon public key** (una clau llarga; NO la "service_role", aquesta última mai s'ha de fer pública)

## Pas 2 — Connectar l'aplicació amb la teva base de dades

1. Obre el fitxer `config.js` d'aquesta carpeta amb qualsevol editor de text
2. Substitueix els dos valors placeholder per la URL i la clau que has copiat al pas anterior
3. Desa el fitxer

```js
window.SUPABASE_URL = "https://xxxxxxxx.supabase.co";
window.SUPABASE_ANON_KEY = "eyJhbGc...";
```

## Pas 3 — Pujar-ho a GitHub

1. Crea un repositori nou a GitHub (pot ser privat o públic, tant se val)
2. Puja-hi **tot el contingut d'aquesta carpeta** (per exemple, arrossegant els fitxers des de la interfície web de GitHub, o amb `git push` si hi estàs còmode)

## Pas 4 — Publicar a Vercel

1. A Vercel, **Add New → Project**
2. Selecciona el repositori que acabes de crear a GitHub
3. Vercel detectarà que és un lloc estàtic — **no cal canviar cap configuració**, prem **Deploy**
4. En uns segons tindràs un enllaç del tipus `https://nissaga-ramon.vercel.app` — aquest és el que comparteixes amb la família

---

## (Opcional però recomanat) Evitar que Supabase "s'adormi"

El pla gratuït de Supabase pausa el projecte si ningú hi entra en 7 dies. Aquesta carpeta ja inclou una automatització (`.github/workflows/keepalive.yml`) que fa una petita visita cada pocs dies perquè això no passi mai. Només cal:

1. Al teu repositori de GitHub, ves a **Settings → Secrets and variables → Actions**
2. Crea dos "secrets": `SUPABASE_URL` i `SUPABASE_ANON_KEY`, amb els mateixos valors que vas posar a `config.js`

I ja està — no ho has de tocar mai més.

---

## Actualitzar l'arbre en el futur

Si vols afegir noves persones o corregir dades:
- **Canvis puntuals** (una data, un ofici): fes-ho directament des de Supabase → *Table Editor* → taula `persons` o `families`
- **Canvis grans** (afegir tota una branca nova): torna-m'ho a demanar i et regenero el `seed.sql` actualitzat

## Què conté cada fitxer

| Fitxer | Per a què serveix |
|---|---|
| `index.html`, `styles.css`, `app.js` | L'aplicació en si |
| `config.js` | On poses les teves claus de Supabase |
| `schema.sql` | Crea les taules `persons` i `families` |
| `seed.sql` | Omple les taules amb les 140 persones de la branca Ramon |
| `photos/` | Les 40 fotografies disponibles, optimitzades per a web |
| `data/direct_line.json` | Les 17 generacions que formen "el riu" de la pàgina principal |
| `.github/workflows/keepalive.yml` | Manté Supabase despert automàticament |
