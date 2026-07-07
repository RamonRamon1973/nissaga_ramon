// ============================================================
// La Nissaga Ramon — lògica de l'aplicació
// ============================================================

let persons = {};       // id -> person row
let families = {};      // id -> family row
let childrenByFamily = {}; // family_id -> [person ids]
let directLine = [];    // 17 ids, de la generació més antiga a la més recent

function normalize(str){
  return (str || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function lifeSpan(p){
  if (!p) return "";
  const parts = [];
  if (p.birth_date) parts.push(`n. ${p.birth_date}${p.birth_place ? ", " + p.birth_place : ""}`);
  if (p.death_date) parts.push(`m. ${p.death_date}${p.death_place ? ", " + p.death_place : ""}`);
  return parts.join(" – ");
}

function birthYear(p){
  if (!p || !p.birth_date) return "?";
  const m = String(p.birth_date).match(/(1[4-9]\d\d|20\d\d)/);
  return m ? m[1] : p.birth_date;
}

// ---------- Data loading ----------
async function loadData(){
  const supabase = window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY);

  const [{ data: personRows, error: e1 }, { data: familyRows, error: e2 }] = await Promise.all([
    supabase.from("persons").select("*"),
    supabase.from("families").select("*"),
  ]);

  if (e1 || e2) {
    document.getElementById("river-wrap").innerHTML =
      `<p style="text-align:center;color:#B5602F;font-family:'IBM Plex Mono',monospace;font-size:13px;">
       No s'ha pogut connectar amb la base de dades. Revisa que config.js tingui la URL i la clau correctes de Supabase.
       </p>`;
    console.error(e1 || e2);
    return false;
  }

  personRows.forEach(p => persons[p.id] = p);
  familyRows.forEach(f => families[f.id] = f);

  Object.values(persons).forEach(p => {
    if (p.famc_id) {
      if (!childrenByFamily[p.famc_id]) childrenByFamily[p.famc_id] = [];
      childrenByFamily[p.famc_id].push(p.id);
    }
  });

  const dlResp = await fetch("data/direct_line.json");
  directLine = await dlResp.json();

  return true;
}

// ---------- Relationship helpers ----------
function spousesOf(personId){
  // returns list of {family, spouseId}
  const result = [];
  Object.values(families).forEach(f => {
    if (f.husband_id === personId) result.push({ family: f, spouseId: f.wife_id });
    else if (f.wife_id === personId) result.push({ family: f, spouseId: f.husband_id });
  });
  return result;
}
function parentsFamilyOf(personId){
  const p = persons[personId];
  if (!p || !p.famc_id) return null;
  return families[p.famc_id] || null;
}
function siblingsOf(personId){
  const fam = parentsFamilyOf(personId);
  if (!fam) return [];
  return (childrenByFamily[fam.id] || []).filter(id => id !== personId);
}
function childrenOfFamily(familyId){
  return childrenByFamily[familyId] || [];
}

// ---------- River rendering ----------
function renderRiver(){
  const path = document.getElementById("river-path");
  const len = path.getTotalLength();
  const container = document.getElementById("river-nodes");
  container.innerHTML = "";
  const n = directLine.length;
  directLine.forEach((pid, i) => {
    const t = n === 1 ? 0 : i / (n - 1);
    const pt = path.getPointAtLength(t * len);
    const xPct = (pt.x / 960) * 100;
    const yPct = (pt.y / 260) * 100;
    const p = persons[pid];
    if (!p) return;
    const node = document.createElement("div");
    node.className = "gen-node";
    node.style.left = xPct + "%";
    node.style.top = yPct + "%";
    const dot = document.createElement("div");
    dot.className = "dot";
    if (p.photo_file) {
      dot.style.backgroundImage = `url(photos/${p.photo_file})`;
      dot.textContent = "";
    } else {
      dot.textContent = "G" + (i + 1);
    }
    const yr = document.createElement("div");
    yr.className = "yr";
    yr.textContent = birthYear(p);
    node.appendChild(dot);
    node.appendChild(yr);
    node.addEventListener("click", () => openPerson(pid));
    container.appendChild(node);
  });
}

// ---------- Search ----------
function setupSearch(){
  const input = document.getElementById("search-input");
  const resultsBox = document.getElementById("search-results");

  input.addEventListener("input", () => {
    const q = normalize(input.value.trim());
    if (q.length < 2) {
      resultsBox.classList.remove("open");
      resultsBox.innerHTML = "";
      return;
    }
    const matches = Object.values(persons)
      .filter(p => normalize(p.full_name).includes(q))
      .slice(0, 12);

    resultsBox.innerHTML = "";
    if (matches.length === 0) {
      resultsBox.innerHTML = `<div class="search-empty">Cap resultat per a "${input.value}"</div>`;
    } else {
      matches.forEach(p => {
        const item = document.createElement("div");
        item.className = "search-result-item";
        item.innerHTML = `<span class="n">${p.full_name}</span><span class="y">${birthYear(p)}</span>`;
        item.addEventListener("click", () => {
          openPerson(p.id);
          resultsBox.classList.remove("open");
          input.value = "";
        });
        resultsBox.appendChild(item);
      });
    }
    resultsBox.classList.add("open");
  });

  document.addEventListener("click", (e) => {
    if (!e.target.closest(".search-wrap")) resultsBox.classList.remove("open");
  });
}

// ---------- Modal / person card ----------
function personChip(id){
  const p = persons[id];
  if (!p) return "";
  return `<span class="chip" data-id="${id}">${p.full_name} <span style="opacity:.6">(${birthYear(p)})</span></span>`;
}

function openPerson(id){
  const p = persons[id];
  if (!p) return;
  const overlay = document.getElementById("modal-overlay");
  const card = document.getElementById("modal-card");

  const photoHtml = p.photo_file
    ? `<img class="modal-photo" src="photos/${p.photo_file}" alt="${p.full_name}">`
    : `<div class="modal-photo placeholder">${(p.given_name || p.full_name || "?").charAt(0)}</div>`;

  const parentsFam = parentsFamilyOf(id);
  let parentsHtml = "";
  if (parentsFam) {
    const chips = [parentsFam.husband_id, parentsFam.wife_id].filter(Boolean).map(personChip).join("");
    if (chips) parentsHtml = `<div class="modal-section"><h4>Pares</h4><div class="chip-row">${chips}</div></div>`;
  }

  const sibs = siblingsOf(id);
  const sibsHtml = sibs.length
    ? `<div class="modal-section"><h4>Germans</h4><div class="chip-row">${sibs.map(personChip).join("")}</div></div>`
    : "";

  const unions = spousesOf(id);
  let unionsHtml = "";
  if (unions.length) {
    unionsHtml = `<div class="modal-section"><h4>Matrimoni${unions.length > 1 ? "s" : ""} i fills</h4>`;
    unions.forEach(u => {
      const spouse = persons[u.spouseId];
      const marr = u.family.marriage_date || u.family.marriage_place
        ? ` <span style="opacity:.65">(casament: ${[u.family.marriage_date, u.family.marriage_place].filter(Boolean).join(", ")})</span>`
        : "";
      unionsHtml += `<div class="union-block">
        <div class="spouse-line">${spouse ? personChipInline(u.spouseId) : "<i>cònjuge no identificat/da</i>"}${marr}</div>
        ${childrenOfFamily(u.family.id).length ? `<div class="chip-row">${childrenOfFamily(u.family.id).map(personChip).join("")}</div>` : ""}
      </div>`;
    });
    unionsHtml += `</div>`;
  }

  card.innerHTML = `
    <button class="modal-close" id="modal-close">&times;</button>
    <div class="modal-head">
      ${photoHtml}
      <div>
        <div class="modal-name">${p.full_name}</div>
        <div class="modal-meta">${lifeSpan(p) || "dates no documentades"}</div>
        ${p.occupation ? `<div class="modal-occ">${p.occupation}</div>` : ""}
      </div>
    </div>
    ${parentsHtml}
    ${sibsHtml}
    ${unionsHtml}
  `;

  card.querySelectorAll(".chip, b[data-id]").forEach(el => {
    el.addEventListener("click", () => openPerson(el.getAttribute("data-id")));
  });

  overlay.classList.add("open");
  document.getElementById("modal-close").addEventListener("click", closePerson);
}

function personChipInline(id){
  const p = persons[id];
  return `<b data-id="${id}">${p.full_name}</b> <span style="opacity:.65">(${lifeSpan(p) || "dates no documentades"})</span>`;
}

function closePerson(){
  document.getElementById("modal-overlay").classList.remove("open");
}
document.getElementById("modal-overlay").addEventListener("click", (e) => {
  if (e.target.id === "modal-overlay") closePerson();
});
document.addEventListener("keydown", (e) => { if (e.key === "Escape") closePerson(); });

// ---------- Init ----------
(async function init(){
  const ok = await loadData();
  if (!ok) return;
  document.getElementById("stat-persons").textContent = Object.keys(persons).length;
  document.getElementById("stat-photos").textContent = Object.values(persons).filter(p => p.photo_file).length;
  renderRiver();
  setupSearch();
  window.addEventListener("resize", renderRiver);
})();
