const xlsx = require("xlsx");
const { Client } = require("@elastic/elasticsearch");

const INPUT_FILE = "C:/Users/MSI/Desktop/projetpfe/soeurise_data_10000.xlsx";
const INDEX_NAME = "soeurise_users";

const client = new Client({ node: "http://localhost:9200" });

async function cleanRow(row) {
  // Clean and normalize each row
  const parseDate = (val) => {
    if (!val) return null;
    const d = new Date(val);
    return isNaN(d.getTime()) ? null : d.toISOString();
  };

  const toInt = (val) => {
    const n = parseInt(val, 10);
    return isNaN(n) ? 0 : n;
  };

  return {
    timestamp: parseDate(row.timestamp),
    prenom: (row.prenom || "").trim(),
    email: (row.email || "").trim().toLowerCase(),
    statut_compte: (row.statut_compte || "Standard").trim(),
    nombre_posts: toInt(row.nombre_posts),
    total_likes_recus: toInt(row.total_likes_recus),
    total_commentaires_recus: toInt(row.total_commentaires_recus),
    total_reposts_recus: toInt(row.total_reposts_recus),
    communaute_active: (row.communaute_active || "Autre").trim(),
    masterclass_achetees: toInt(row.masterclass_achetees),
    evenements_inscrits: toInt(row.evenements_inscrits),
    derniere_connexion: parseDate(row.derniere_connexion),
    taux_engagement: toInt(row.taux_engagement),
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
        taux_engagement: { type: "integer" },
      },
    },
  });
  console.log(`✅ Index '${INDEX_NAME}' créé avec le bon mapping.`);
}

async function ingestData() {
  console.log(`Lecture du fichier : ${INPUT_FILE}`);
  const workbook = xlsx.readFile(INPUT_FILE);
  const sheetName = workbook.SheetNames[0];
  const rawData = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName]);

  console.log(`${rawData.length} lignes trouvées. Nettoyage en cours...`);
  const cleanedData = await Promise.all(rawData.map(cleanRow));

  // Skip rows with no email or timestamp
  const validData = cleanedData.filter((r) => r.email && r.timestamp);
  console.log(`${validData.length} lignes valides après nettoyage.`);

  // Bulk insert in batches of 500
  const BATCH_SIZE = 500;
  let insertedCount = 0;
  for (let i = 0; i < validData.length; i += BATCH_SIZE) {
    const batch = validData.slice(i, i + BATCH_SIZE);
    const operations = batch.flatMap((doc) => [
      { index: { _index: INDEX_NAME } },
      doc,
    ]);
    const result = await client.bulk({ refresh: false, operations });
    if (result.errors) {
      console.error("Erreurs dans le batch:", result.items.filter((i) => i.index.error));
    }
    insertedCount += batch.length;
    console.log(`  → ${insertedCount}/${validData.length} documents ingérés...`);
  }

  await client.indices.refresh({ index: INDEX_NAME });

  const count = await client.count({ index: INDEX_NAME });
  console.log(`\n✅ Ingestion terminée ! ${count.count} documents indexés dans Elasticsearch.`);
  console.log(`\n👉 Ouvrez Kibana : http://localhost:5601`);
}

async function main() {
  try {
    await createIndex();
    await ingestData();
  } catch (err) {
    console.error("Erreur :", err.meta?.body || err.message || err);
    process.exit(1);
  }
}

main();
