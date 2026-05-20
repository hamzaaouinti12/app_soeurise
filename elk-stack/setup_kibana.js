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

// Lens vizs: references at TOP level (Kibana 8 requirement)
async function createLensViz(title, attributes, dvId) {
  const references = [{ type: "index-pattern", id: dvId, name: "indexpattern-datasource-layer-layer1" }];
  const res = await req("POST", "/api/saved_objects/lens", { attributes, references });
  if (res.b?.id) { console.log(`  ✅ ${title}`); return res.b.id; }
  console.log(`  ⚠️  ${title} [${res.s}]:`, JSON.stringify(res.b).slice(0, 200));
  return null;
}

async function deleteOld() {
  const types = ["lens", "visualization", "dashboard"];
  for (const t of types) {
    const list = await req("GET", `/api/saved_objects/_find?type=${t}&per_page=50`);
    for (const obj of (list.b.saved_objects || [])) {
      await req("DELETE", `/api/saved_objects/${t}/${obj.id}`);
    }
  }
  console.log("Anciens objets supprimés.");
}

async function getDataViewId() {
  const list = await req("GET", "/api/data_views");
  const items = list.b?.data_view || list.b?.items || [];
  const existing = items.find(d => d.title === "soeurise_users");
  if (existing) { console.log("Data view ID:", existing.id); return existing.id; }
  const created = await req("POST", "/api/data_views/data_view", {
    data_view: { title: "soeurise_users", name: "Soeurise Utilisateurs", timeFieldName: "timestamp" },
    override: true,
  });
  const id = created.b?.data_view?.id;
  console.log("Data view créé, ID:", id);
  return id;
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
  await deleteOld();
  const dvId = await getDataViewId();
  console.log("Création des visualisations...");

  const v1 = await createLensViz("Total Utilisateurs",
    makeMetric("👥 Total Utilisateurs", "count", "___records___", "#8b5cf6"), dvId);

  const v2 = await createLensViz("Total Masterclasses",
    makeMetric("🎓 Masterclasses Achetées", "sum", "masterclass_achetees", "#10b981"), dvId);

  const v3 = await createLensViz("Engagement Moyen",
    makeMetric("🔥 Engagement Moyen (%)", "average", "taux_engagement", "#ec4899"), dvId);

  const v4 = await createLensViz("Total Evenements",
    makeMetric("📅 Événements Inscrits", "sum", "evenements_inscrits", "#f59e0b"), dvId);

  // Line chart: Inscriptions par mois
  const v5 = await createLensViz("Croissance Inscriptions", {
    title: "📈 Croissance des Inscriptions par Mois",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-date", "col-count"], columns: {
            "col-date": { label: "Mois", dataType: "date", operationType: "date_histogram", isBucketed: true, scale: "interval", sourceField: "timestamp", params: { interval: "1M", includeEmptyRows: true, dropPartials: false } },
            "col-count": { label: "Inscriptions", dataType: "number", operationType: "count", isBucketed: false, scale: "ratio", sourceField: "___records___" }
          }}}
        }
      },
      visualization: {
        legend: { isVisible: true, position: "right" },
        valueLabels: "hide", fittingFunction: "None", preferredSeriesType: "area",
        layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-count"], xAccessor: "col-date", seriesType: "area", yConfig: [{ forAccessor: "col-count", color: "#8b5cf6" }] }]
      },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  // Bar: Statuts (remplace le donut pour éviter l'erreur Kibana)
  const v6 = await createLensViz("Repartition Statuts", {
    title: "💎 Répartition Standard / Premium",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-statut", "col-count"], columns: {
            "col-statut": { label: "Statut", dataType: "string", operationType: "terms", isBucketed: true, scale: "ordinal", sourceField: "statut_compte", params: { size: 10, orderBy: { type: "column", columnId: "col-count" }, orderDirection: "desc", otherBucket: false, missingBucket: false } },
            "col-count": { label: "Utilisateurs", dataType: "number", operationType: "count", isBucketed: false, scale: "ratio", sourceField: "___records___" }
          }}}
        }
      },
      visualization: {
        legend: { isVisible: false }, valueLabels: "hide", preferredSeriesType: "bar_horizontal",
        layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-count"], xAccessor: "col-statut", seriesType: "bar_horizontal", yConfig: [{ forAccessor: "col-count", color: "#10b981" }] }]
      },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  // Bar: Membres par communauté
  const v7 = await createLensViz("Membres par Communaute", {
    title: "🏘️ Membres par Communauté",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-comm", "col-count"], columns: {
            "col-comm": { label: "Communauté", dataType: "string", operationType: "terms", isBucketed: true, scale: "ordinal", sourceField: "communaute_active", params: { size: 10, orderBy: { type: "column", columnId: "col-count" }, orderDirection: "desc", otherBucket: false, missingBucket: false } },
            "col-count": { label: "Membres", dataType: "number", operationType: "count", isBucketed: false, scale: "ratio", sourceField: "___records___" }
          }}}
        }
      },
      visualization: {
        legend: { isVisible: false }, valueLabels: "hide", preferredSeriesType: "bar_horizontal",
        layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-count"], xAccessor: "col-comm", seriesType: "bar_horizontal", yConfig: [{ forAccessor: "col-count", color: "#8b5cf6" }] }]
      },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  // Bar: Engagement par communauté
  const v8 = await createLensViz("Engagement par Communaute", {
    title: "🔥 Taux d'Engagement par Communauté",
    visualizationType: "lnsXY",
    state: {
      datasourceStates: {
        formBased: {
          layers: { layer1: { columnOrder: ["col-comm", "col-avg"], columns: {
            "col-comm": { label: "Communauté", dataType: "string", operationType: "terms", isBucketed: true, scale: "ordinal", sourceField: "communaute_active", params: { size: 10, orderBy: { type: "column", columnId: "col-avg" }, orderDirection: "desc", otherBucket: false, missingBucket: false } },
            "col-avg": { label: "Engagement moyen (%)", dataType: "number", operationType: "average", isBucketed: false, scale: "ratio", sourceField: "taux_engagement" }
          }}}
        }
      },
      visualization: {
        legend: { isVisible: false }, valueLabels: "hide", preferredSeriesType: "bar_horizontal",
        layers: [{ layerId: "layer1", layerType: "data", accessors: ["col-avg"], xAccessor: "col-comm", seriesType: "bar_horizontal", yConfig: [{ forAccessor: "col-avg", color: "#ec4899" }] }]
      },
      query: { query: "", language: "kuery" }, filters: []
    }
  }, dvId);

  // Build dashboard
  const vIds = [v1, v2, v3, v4, v5, v6, v7, v8];
  const titles = ["👥 Total Utilisateurs","🎓 Masterclasses","🔥 Engagement","📅 Événements","📈 Croissance","💎 Statuts","🏘️ Membres","🔥 Engagement/Comm"];
  const layout = [
    { x:0, y:0, w:6, h:6 }, { x:6, y:0, w:6, h:6 }, { x:12, y:0, w:6, h:6 }, { x:18, y:0, w:6, h:6 },
    { x:0, y:6, w:16, h:14 }, { x:16, y:6, w:8, h:14 },
    { x:0, y:20, w:12, h:14 }, { x:12, y:20, w:12, h:14 },
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
      title: "📊 Soeurise — Analytics Dashboard",
      description: "KPIs et métriques de la plateforme Soeurise",
      panelsJSON: JSON.stringify(panels),
      optionsJSON: JSON.stringify({ useMargins: true, syncColors: true, hidePanelTitles: false }),
      timeRestore: true,
      timeFrom: "2025-01-01T00:00:00.000Z",
      timeTo: "now",
      kibanaSavedObjectMeta: { searchSourceJSON: JSON.stringify({ query: { query: "", language: "kuery" }, filter: [] }) },
    },
    references: refs,
  });

  const dbId = db.b?.id;
  if (dbId) {
    console.log(`\n✅ Dashboard créé !`);
    console.log(`👉 http://localhost:5601/app/dashboards#/view/${dbId}`);
  } else {
    console.log("Erreur dashboard:", JSON.stringify(db.b).slice(0, 400));
  }
}

main().catch(console.error);
