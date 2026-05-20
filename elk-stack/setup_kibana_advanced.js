const http = require("http");

function req(method, path, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: "localhost", port: 5601, path, method,
      headers: { "Content-Type": "application/json", "kbn-xsrf": "true", ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}) },
    };
    const r = http.request(opts, (res) => {
      let b = "";
      res.on("data", c => b += c);
      res.on("end", () => { try { resolve({ s: res.statusCode, b: JSON.parse(b) }); } catch { resolve({ s: res.statusCode, b }); } });
    });
    r.on("error", reject);
    if (data) r.write(data);
    r.end();
  });
}

async function createLensViz(title, attributes, dvId) {
  const references = [{ type: "index-pattern", id: dvId, name: "indexpattern-datasource-layer-layer1" }];
  const res = await req("POST", "/api/saved_objects/lens", { attributes, references });
  if (res.b?.id) { console.log(`  ✅ ${title}`); return res.b.id; }
  console.log(`  ⚠️  ${title} [${res.s}]:`, JSON.stringify(res.b).slice(0, 200));
  return null;
}

async function getDataViewId() {
  const list = await req("GET", "/api/data_views");
  const items = list.b?.data_view || list.b?.items || [];
  const existing = items.find(d => d.title === "soeurise_users");
  if (existing) return existing.id;
  throw new Error("Data view 'soeurise_users' non trouvé. Avez-vous lancé le premier script ?");
}

function makeMetric(label, op, field, color) {
  return {
    title: label,
    visualizationType: "lnsMetric",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col1"], columns: { col1: { label, dataType: "number", operationType: op, isBucketed: false, scale: "ratio", sourceField: field } } } }
        }
      },
      visualization: { layerId: "layer1", layerType: "data", metricAccessor: "col1", color },
      query: { query: "", language: "kuery" }, filters: []
    }
  };
}

async function main() {
  const dvId = await getDataViewId();
  console.log("Création des visualisations d'engagement...");

  const v1 = await createLensViz("Total Posts", makeMetric("📝 Total Posts Créés", "sum", "nombre_posts", "#3b82f6"), dvId);
  const v2 = await createLensViz("Total Likes", makeMetric("❤️ Total Likes", "sum", "total_likes_recus", "#ef4444"), dvId);
  const v3 = await createLensViz("Total Commentaires", makeMetric("💬 Total Commentaires", "sum", "total_commentaires_recus", "#14b8a6"), dvId);
  const v4 = await createLensViz("Total Reposts", makeMetric("🔄 Total Reposts", "sum", "total_reposts_recus", "#8b5cf6"), dvId);

  const v5 = await createLensViz("Posts par Communaute", {
    title: "📊 Volume de Posts par Communauté",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-comm", "col-sum"], columns: {
            "col-comm": { label: "Communauté", dataType: "string", operationType: "terms", isBucketed: true, scale: "ordinal", sourceField: "communaute_active", params: { size: 10, orderBy: { type: "column", columnId: "col-sum" }, orderDirection: "desc", otherBucket: false, missingBucket: false } },
            "col-sum": { label: "Nombre de Posts", dataType: "number", operationType: "sum", isBucketed: false, scale: "ratio", sourceField: "nombre_posts" }
          }}}
        }
      },
      visualization: { legend: { isVisible: false }, valueLabels: "hide", preferredSeriesType: "bar_horizontal", layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-sum"], xAccessor: "col-comm", seriesType: "bar_horizontal", yConfig: [{ forAccessor: "col-sum", color: "#3b82f6" }] }] },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  const v6 = await createLensViz("Activite par Statut", {
    title: "💎 Activité: Premium vs Standard",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-statut", "col-avg"], columns: {
            "col-statut": { label: "Statut", dataType: "string", operationType: "terms", isBucketed: true, scale: "ordinal", sourceField: "statut_compte", params: { size: 10, orderBy: { type: "column", columnId: "col-avg" }, orderDirection: "desc", otherBucket: false, missingBucket: false } },
            "col-avg": { label: "Moyenne Posts par Utilisateur", dataType: "number", operationType: "average", isBucketed: false, scale: "ratio", sourceField: "nombre_posts" }
          }}}
        }
      },
      visualization: { legend: { isVisible: false }, valueLabels: "hide", preferredSeriesType: "bar_horizontal", layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-avg"], xAccessor: "col-statut", seriesType: "bar_horizontal", yConfig: [{ forAccessor: "col-avg", color: "#10b981" }] }] },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  const vIds = [v1, v2, v3, v4, v5, v6];
  const titles = ["Total Posts", "Total Likes", "Total Commentaires", "Total Reposts", "Posts par Communauté", "Activité Premium/Standard"];
  const layout = [
    { x:0, y:0, w:6, h:6 }, { x:6, y:0, w:6, h:6 }, { x:12, y:0, w:6, h:6 }, { x:18, y:0, w:6, h:6 },
    { x:0, y:6, w:12, h:14 }, { x:12, y:6, w:12, h:14 },
  ];

  const panels = [], refs = [];
  let pi = 0;
  for (let i = 0; i < vIds.length; i++) {
    if (!vIds[i]) continue;
    const id = String(pi + 1);
    panels.push({ version: "8.13.0", type: "lens", gridData: { ...layout[i], i: id }, panelIndex: id, embeddableConfig: { title: titles[i], hidePanelTitles: false }, panelRefName: `panel_${id}` });
    refs.push({ name: `panel_${id}`, type: "lens", id: vIds[i] });
    pi++;
  }

  const db = await req("POST", "/api/saved_objects/dashboard", {
    attributes: {
      title: "📖 Soeurise — Engagement & Contenu",
      description: "Analyses de l'activité des utilisateurs, du contenu généré et de l'engagement",
      panelsJSON: JSON.stringify(panels),
      optionsJSON: JSON.stringify({ useMargins: true, syncColors: true, hidePanelTitles: false }),
      timeRestore: true,
      timeFrom: "2025-01-01T00:00:00.000Z",
      timeTo: "now",
      kibanaSavedObjectMeta: { searchSourceJSON: JSON.stringify({ query: { query: "", language: "kuery" }, filter: [] }) },
    },
    references: refs,
  });

  if (db.b?.id) {
    console.log(`\n✅ Nouveau Dashboard "Engagement" créé ! ID: ${db.b.id}`);
  } else {
    console.log("Erreur dashboard:", JSON.stringify(db.b).slice(0, 400));
  }
}

main().catch(console.error);
