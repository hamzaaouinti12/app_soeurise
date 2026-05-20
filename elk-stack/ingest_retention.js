const xlsx = require("xlsx");
const { Client } = require("@elastic/elasticsearch");

const INPUT_FILE = "C:/Users/MSI/Desktop/projetpfe/soeurise_data_10000.xlsx";
const INDEX_NAME = "soeurise_users";

const client = new Client({ node: "http://localhost:9200" });

const toInt = (val) => { const n = parseInt(val, 10); return isNaN(n) ? 0 : n; };
const parseDate = (val) => {
  if (!val) return null;
  const d = new Date(val);
  return isNaN(d.getTime()) ? null : d.toISOString();
};

async function cleanRow(row) {
  return {
    timestamp:                parseDate(row.timestamp),
    prenom:                   (row.prenom || "").trim(),
    email:                    (row.email || "").trim().toLowerCase(),
    statut_compte:            (row.statut_compte || "Standard").trim(),
    nombre_posts:             toInt(row.nombre_posts),
    total_likes_recus:        toInt(row.total_likes_recus),
    total_commentaires_recus: toInt(row.total_commentaires_recus),
    total_reposts_recus:      toInt(row.total_reposts_recus),
    communaute_active:        (row.communaute_active || "Autre").trim(),
    masterclass_achetees:     toInt(row.masterclass_achetees),
    evenements_inscrits:      toInt(row.evenements_inscrits),
    derniere_connexion:       parseDate(row.derniere_connexion),
    taux_engagement:          toInt(row.taux_engagement),
  };
}

async function createIndex() {
  const exists = await client.indices.exists({ index: INDEX_NAME });
  if (exists) {
    console.log(`Index '${INDEX_NAME}' déjà existant. Suppression...`);
    await client.indices.delete({ index: INDEX_NAME });
  }
  await client.indices.create({
    index: INDEX_NAME,
    mappings: {
      properties: {
        timestamp:                { type: "date" },
        prenom:                   { type: "keyword" },
        email:                    { type: "keyword" },
        statut_compte:            { type: "keyword" },
        nombre_posts:             { type: "integer" },
        total_likes_recus:        { type: "integer" },
        total_commentaires_recus: { type: "integer" },
        total_reposts_recus:      { type: "integer" },
        communaute_active:        { type: "keyword" },
        masterclass_achetees:     { type: "integer" },
        evenements_inscrits:      { type: "integer" },
        derniere_connexion:       { type: "date" },
        taux_engagement:          { type: "integer" },
      },
    },
  });
  console.log(`✅ Index '${INDEX_NAME}' créé.`);
}

async function ingestData() {
  console.log(`📂 Lecture : ${INPUT_FILE}`);
  const workbook = xlsx.readFile(INPUT_FILE);
  const rawData  = xlsx.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);
  console.log(`${rawData.length} lignes trouvées. Nettoyage...`);

  const cleaned = await Promise.all(rawData.map(cleanRow));
  const valid   = cleaned.filter((r) => r.email && r.timestamp);
  console.log(`${valid.length} lignes valides.`);

  const BATCH = 500;
  let inserted = 0;
  for (let i = 0; i < valid.length; i += BATCH) {
    const batch = valid.slice(i, i + BATCH);
    const ops   = batch.flatMap((doc) => [{ index: { _index: INDEX_NAME } }, doc]);
    const res   = await client.bulk({ refresh: false, operations: ops });
    if (res.errors) console.error("Erreurs batch:", res.items.filter((x) => x.index.error));
    inserted += batch.length;
    console.log(`  → ${inserted}/${valid.length}`);
  }

  await client.indices.refresh({ index: INDEX_NAME });
  const count = await client.count({ index: INDEX_NAME });
  console.log(`\n✅ ${count.count} documents indexés !`);

  // ── Compute retention stats ──────────────────────────────────────────────
  console.log("\n📊 Calcul des statistiques de rétention...");
  const now = new Date();

  const inactive30  = valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 30  * 86400000).length;
  const inactive60  = valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 60  * 86400000).length;
  const inactive90  = valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 90  * 86400000).length;
  const zombies     = valid.filter(r => r.nombre_posts === 0 && r.masterclass_achetees === 0 && r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 30 * 86400000).length;
  const active7d    = valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) <= 7  * 86400000).length;
  const active30d   = valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) <= 30 * 86400000).length;

  // Churn risk per community
  const communities = {};
  valid.forEach(r => {
    if (!communities[r.communaute_active]) communities[r.communaute_active] = { total: 0, inactive: 0 };
    communities[r.communaute_active].total++;
    if (r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 30 * 86400000) {
      communities[r.communaute_active].inactive++;
    }
  });

  // Last-login monthly distribution
  const monthDist = {};
  valid.forEach(r => {
    if (!r.derniere_connexion) return;
    const key = new Date(r.derniere_connexion).toISOString().slice(0,7);
    monthDist[key] = (monthDist[key] || 0) + 1;
  });

  // Status breakdown of inactive users
  const inactiveByStatus = { Standard: 0, Premium: 0, Admin: 0 };
  valid.filter(r => r.derniere_connexion && (now - new Date(r.derniere_connexion)) > 30 * 86400000)
       .forEach(r => { inactiveByStatus[r.statut_compte] = (inactiveByStatus[r.statut_compte] || 0) + 1; });

  const stats = {
    total: valid.length,
    active7d, active30d,
    inactive30, inactive60, inactive90,
    zombies,
    communities,
    monthDist,
    inactiveByStatus,
    retentionRate30d: ((active30d / valid.length) * 100).toFixed(1),
    churnRate30d: ((inactive30 / valid.length) * 100).toFixed(1),
  };

  // Write stats to a JSON file for the dashboard
  const fs = require("fs");
  fs.writeFileSync("retention_stats.json", JSON.stringify(stats, null, 2));
  console.log("✅ retention_stats.json généré !");
  console.log(`\n📊 Résumé :`);
  console.log(`  • Actives (7j)  : ${active7d}`);
  console.log(`  • Actives (30j) : ${active30d} (${stats.retentionRate30d}%)`);
  console.log(`  • Inactives >30j: ${inactive30} (${stats.churnRate30d}%)`);
  console.log(`  • Zombies       : ${zombies}`);
  console.log(`\n👉 Ouvrez le dashboard : retention_dashboard.html`);
}

async function main() {
  try {
    await createIndex();
    await ingestData();
  } catch (err) {
    console.error("❌ Erreur :", err.meta?.body || err.message || err);
    process.exit(1);
  }
}

main();
