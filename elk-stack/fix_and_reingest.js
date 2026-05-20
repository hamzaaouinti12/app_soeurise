/**
 * Re-ingest script with fixed UTF-8 encoding + correct community names
 */
const xlsx = require("xlsx");
const { Client } = require("@elastic/elasticsearch");

const INPUT_FILE = "C:/Users/MSI/Desktop/projetpfe/soeurise_data_10000.xlsx";
const INDEX_NAME = "soeurise_users";
const client = new Client({ node: "http://localhost:9200" });

// Mapping to fix broken community names from the generator
const FIX_COMMUNITY = {
  "Spiritualit": "Spiritualité",
  "Bien-tre": "Bien-être",
  "Dveloppement Personnel": "Développement Personnel",
  "Dveloppement": "Développement Personnel",
  "Maternit": "Maternité",
  "Spiritualité": "Spiritualité",
  "Bien-être": "Bien-être",
  "Développement Personnel": "Développement Personnel",
  "Maternité": "Maternité",
  "Oukhty Business": "Oukhty Business",
};

function fixCommunity(val) {
  if (!val) return "Autre";
  const clean = (val || "").trim();
  // Try exact match first
  if (FIX_COMMUNITY[clean]) return FIX_COMMUNITY[clean];
  // Fuzzy match
  for (const key of Object.keys(FIX_COMMUNITY)) {
    if (clean.toLowerCase().includes(key.toLowerCase().slice(0, 5))) {
      return FIX_COMMUNITY[key];
    }
  }
  return clean;
}

function cleanRow(row) {
  const parseDate = (val) => {
    if (!val) return null;
    const d = new Date(val);
    return isNaN(d.getTime()) ? null : d.toISOString();
  };
  const toInt = (val) => { const n = parseInt(val, 10); return isNaN(n) ? 0 : n; };
  const toFloat = (val) => { const n = parseFloat(val); return isNaN(n) ? 0 : Math.round(n * 10) / 10; };

  return {
    timestamp: parseDate(row.timestamp),
    prenom: (row.prenom || "").trim(),
    email: (row.email || "").trim().toLowerCase(),
    statut_compte: (row.statut_compte || "Standard").trim(),
    nombre_posts: toInt(row.nombre_posts),
    total_likes_recus: toInt(row.total_likes_recus),
    total_commentaires_recus: toInt(row.total_commentaires_recus),
    total_reposts_recus: toInt(row.total_reposts_recus),
    communaute_active: fixCommunity(row.communaute_active),
    masterclass_achetees: toInt(row.masterclass_achetees),
    evenements_inscrits: toInt(row.evenements_inscrits),
    derniere_connexion: parseDate(row.derniere_connexion),
    taux_engagement: toFloat(row.taux_engagement),
  };
}

async function run() {
  try {
    // Delete and recreate index
    const exists = await client.indices.exists({ index: INDEX_NAME });
    if (exists) {
      await client.indices.delete({ index: INDEX_NAME });
      console.log("Index supprimé.");
    }
    await client.indices.create({
      index: INDEX_NAME,
      mappings: {
        properties: {
          timestamp: { type: "date" },
          prenom: { type: "keyword" },
          email: { type: "keyword" },
          statut_compte: { type: "keyword" },
          nombre_posts: { type: "integer" },
          total_likes_recus: { type: "integer" },
          total_commentaires_recus: { type: "integer" },
          total_reposts_recus: { type: "integer" },
          communaute_active: { type: "keyword" },
          masterclass_achetees: { type: "integer" },
          evenements_inscrits: { type: "integer" },
          derniere_connexion: { type: "date" },
          taux_engagement: { type: "float" },
        },
      },
    });
    console.log("✅ Index recréé avec le bon mapping.");

    // Read and clean data
    const workbook = xlsx.readFile(INPUT_FILE);
    const raw = xlsx.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);
    const cleaned = raw.map(cleanRow).filter(r => r.email && r.timestamp);
    console.log(`${cleaned.length} lignes valides après nettoyage.`);

    // Bulk insert
    const BATCH = 500;
    for (let i = 0; i < cleaned.length; i += BATCH) {
      const ops = cleaned.slice(i, i + BATCH).flatMap(doc => [{ index: { _index: INDEX_NAME } }, doc]);
      await client.bulk({ refresh: false, operations: ops });
      console.log(`  → ${Math.min(i + BATCH, cleaned.length)}/${cleaned.length}`);
    }
    await client.indices.refresh({ index: INDEX_NAME });
    const count = await client.count({ index: INDEX_NAME });
    console.log(`\n✅ ${count.count} documents réindexés avec succès !`);
    process.exit(0);
  } catch (err) {
    console.error("Erreur:", err.message || err);
    process.exit(1);
  }
}
run();
