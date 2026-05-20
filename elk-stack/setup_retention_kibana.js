const http = require("http");

const KIBANA = "http://localhost:5601";
const INDEX  = "soeurise_users";

function req(method, path, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: "localhost", port: 5601,
      path, method,
      headers: {
        "Content-Type": "application/json",
        "kbn-xsrf": "true",
        ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}),
      },
    };
    const r = http.request(opts, (res) => {
      let raw = "";
      res.on("data", (c) => (raw += c));
      res.on("end", () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    r.on("error", reject);
    if (data) r.write(data);
    r.end();
  });
}

async function run() {
  console.log("🚀 Création du Dashboard Rétention dans Kibana...\n");

  // ── 1. Data View ─────────────────────────────────────────────────────────
  console.log("1/7  Data View...");
  const dvRes = await req("POST", "/api/data_views/data_view", {
    data_view: {
      title: INDEX,
      name: "Soeurise Users",
      timeFieldName: "timestamp",
    },
    override: true,
  });
  const dvId = dvRes.body?.data_view?.id;
  console.log(`     ✅ Data View id: ${dvId}`);

  // ── helper ────────────────────────────────────────────────────────────────
  async function saveViz(id, title, visState) {
    const r = await req("POST", "/api/saved_objects/visualization/" + id + "?overwrite=true", {
      attributes: {
        title,
        visState: JSON.stringify(visState),
        uiStateJSON: "{}",
        description: "",
        kibanaSavedObjectMeta: {
          searchSourceJSON: JSON.stringify({ query: { query: "", language: "kuery" }, filter: [], index: dvId }),
        },
      },
    });
    console.log(`     ${r.status < 300 ? "✅" : "❌"} ${title}`);
    return id;
  }

  // ── 2. Viz 1 : KPI Actives 30j (metric) ─────────────────────────────────
  console.log("2/7  Visualisations...");
  await saveViz("ret_kpi_active30", "KPI — Actives 30 jours", {
    type: "metric",
    params: { addTooltip: true, addLegend: false, type: "metric",
      metric: { percentageMode: false, useRanges: false, colorSchema: "Green to Red",
        metricColorMode: "None", colorsRange: [{ from: 0, to: 10000 }],
        labels: { show: true }, invertColors: false, style: { bgFill: "#000", bgColor: false, labelColor: false, subText: "", fontSize: 60 } } },
    aggs: [{
      id: "1", enabled: true, type: "count", schema: "metric",
      params: { customLabel: "Actives ≤30j" },
    }],
  });

  // ── 3. Viz 2 : Segments inactivité (pie) ─────────────────────────────────
  await saveViz("ret_segments", "Segments d'Inactivité", {
    type: "pie",
    params: { addTooltip: true, addLegend: true, legendPosition: "right",
      isDonut: true, labels: { show: true, values: true, last_level: true, truncate: 100 } },
    aggs: [
      { id: "1", enabled: true, type: "count", schema: "metric", params: {} },
      { id: "2", enabled: true, type: "range", schema: "segment",
        params: {
          field: "taux_engagement",
          ranges: [{ from: 0, to: 0 }, { from: 1, to: 50 }, { from: 51, to: 100 }],
          customLabel: "Segment",
        },
      },
    ],
  });

  // ── 4. Viz 3 : Dernière connexion — timeline (line) ──────────────────────
  await saveViz("ret_timeline", "Dernière Connexion — Timeline", {
    type: "line",
    params: {
      type: "line", grid: { categoryLines: false }, categoryAxes: [{ id: "CategoryAxis-1", type: "category", position: "bottom", show: true, style: {}, scale: { type: "linear" }, labels: { show: true, filter: true, truncate: 100 }, title: {} }],
      valueAxes: [{ id: "ValueAxis-1", name: "LeftAxis-1", type: "value", position: "left", show: true, style: {}, scale: { type: "linear", mode: "normal" }, labels: { show: true, rotate: 0, filter: false, truncate: 100 }, title: { text: "Utilisatrices" } }],
      seriesParams: [{ show: true, type: "line", mode: "normal", data: { label: "Utilisatrices", id: "1" }, valueAxis: "ValueAxis-1", drawLinesBetweenPoints: true, lineWidth: 2, interpolate: "linear", showCircles: true }],
      addTooltip: true, addLegend: true, legendPosition: "right", times: [], addTimeMarker: false, thresholdLine: { show: false, value: 10, width: 1, style: "full", color: "#E7664C" }, labels: {},
    },
    aggs: [
      { id: "1", enabled: true, type: "count", schema: "metric", params: { customLabel: "Utilisatrices" } },
      { id: "2", enabled: true, type: "date_histogram", schema: "segment",
        params: { field: "derniere_connexion", useNormalizedEsInterval: true, scaleMetricValues: false, interval: "auto", drop_partials: false, min_doc_count: 1, extended_bounds: {}, customLabel: "Mois" } },
    ],
  });

  // ── 5. Viz 4 : Churn par communauté (horizontal bar) ─────────────────────
  await saveViz("ret_churn_community", "Churn Risk par Communauté", {
    type: "histogram",
    params: {
      type: "histogram", grid: { categoryLines: false }, categoryAxes: [{ id: "CategoryAxis-1", type: "category", position: "left", show: true, style: {}, scale: { type: "linear" }, labels: { show: true, filter: true, truncate: 100 }, title: {} }],
      valueAxes: [{ id: "ValueAxis-1", name: "LeftAxis-1", type: "value", position: "bottom", show: true, style: {}, scale: { type: "linear", mode: "normal" }, labels: { show: true, rotate: 0, filter: false, truncate: 100 }, title: { text: "Utilisatrices" } }],
      seriesParams: [{ show: true, type: "histogram", mode: "normal", data: { label: "Utilisatrices", id: "1" }, valueAxis: "ValueAxis-1", drawLinesBetweenPoints: true, lineWidth: 2, showCircles: true }],
      addTooltip: true, addLegend: true, legendPosition: "right", times: [], addTimeMarker: false, thresholdLine: { show: false, value: 10, width: 1, style: "full", color: "#E7664C" }, labels: {}, isHorizontal: true,
    },
    aggs: [
      { id: "1", enabled: true, type: "count", schema: "metric", params: { customLabel: "Utilisatrices" } },
      { id: "2", enabled: true, type: "terms", schema: "segment",
        params: { field: "communaute_active", orderBy: "1", order: "desc", size: 5, otherBucket: false, otherBucketLabel: "Other", missingBucket: false, missingBucketLabel: "Missing", customLabel: "Communauté" } },
    ],
  });

  // ── 6. Viz 5 : Inactives par statut (donut) ──────────────────────────────
  await saveViz("ret_status_donut", "Inactives par Statut Compte", {
    type: "pie",
    params: { addTooltip: true, addLegend: true, legendPosition: "right", isDonut: true, labels: { show: false, values: true, last_level: true, truncate: 100 } },
    aggs: [
      { id: "1", enabled: true, type: "count", schema: "metric", params: {} },
      { id: "2", enabled: true, type: "terms", schema: "segment",
        params: { field: "statut_compte", orderBy: "1", order: "desc", size: 3, otherBucket: false, customLabel: "Statut" } },
    ],
  });

  // ── 7. Viz 6 : Posts distribution — bar ──────────────────────────────────
  await saveViz("ret_posts_bar", "Activité Posts des Inactives", {
    type: "histogram",
    params: {
      type: "histogram", grid: { categoryLines: false },
      categoryAxes: [{ id: "CategoryAxis-1", type: "category", position: "bottom", show: true, style: {}, scale: { type: "linear" }, labels: { show: true, filter: true, truncate: 100 }, title: {} }],
      valueAxes: [{ id: "ValueAxis-1", name: "LeftAxis-1", type: "value", position: "left", show: true, style: {}, scale: { type: "linear", mode: "normal" }, labels: { show: true }, title: { text: "Utilisatrices" } }],
      seriesParams: [{ show: true, type: "histogram", mode: "stacked", data: { label: "Count", id: "1" }, valueAxis: "ValueAxis-1", drawLinesBetweenPoints: true, lineWidth: 2, showCircles: true }],
      addTooltip: true, addLegend: true, legendPosition: "right", times: [], addTimeMarker: false, thresholdLine: { show: false, value: 10, width: 1, style: "full", color: "#E7664C" }, labels: {},
    },
    aggs: [
      { id: "1", enabled: true, type: "count", schema: "metric", params: { customLabel: "Utilisatrices" } },
      { id: "2", enabled: true, type: "histogram", schema: "segment",
        params: { field: "nombre_posts", interval: 10, min_doc_count: false, has_extended_bounds: false, extended_bounds: { min: "", max: "" }, customLabel: "Posts" } },
    ],
  });

  // ── 8. Dashboard ──────────────────────────────────────────────────────────
  console.log("3/7  Création du Dashboard...");
  const panelsJSON = JSON.stringify([
    { panelIndex: "1", gridData: { x: 0,  y: 0,  w: 12, h: 7,  i: "1"  }, type: "visualization", id: "ret_kpi_active30",     embeddableConfig: {} },
    { panelIndex: "2", gridData: { x: 12, y: 0,  w: 24, h: 14, i: "2"  }, type: "visualization", id: "ret_timeline",         embeddableConfig: {} },
    { panelIndex: "3", gridData: { x: 36, y: 0,  w: 12, h: 14, i: "3"  }, type: "visualization", id: "ret_segments",         embeddableConfig: {} },
    { panelIndex: "4", gridData: { x: 0,  y: 14, w: 24, h: 14, i: "4"  }, type: "visualization", id: "ret_churn_community",  embeddableConfig: {} },
    { panelIndex: "5", gridData: { x: 24, y: 14, w: 24, h: 14, i: "5"  }, type: "visualization", id: "ret_status_donut",     embeddableConfig: {} },
    { panelIndex: "6", gridData: { x: 0,  y: 28, w: 48, h: 14, i: "6"  }, type: "visualization", id: "ret_posts_bar",        embeddableConfig: {} },
  ]);

  const dash = await req("POST", "/api/saved_objects/dashboard/retention_dashboard_v1?overwrite=true", {
    attributes: {
      title: "📊 Soeurise — Rétention & Inactivité",
      description: "Analyse complète de la rétention et du risque de churn sur 10 000 utilisatrices",
      panelsJSON,
      optionsJSON: JSON.stringify({ useMargins: true, syncColors: false, hidePanelTitles: false }),
      timeRestore: false,
      kibanaSavedObjectMeta: {
        searchSourceJSON: JSON.stringify({ query: { query: "", language: "kuery" }, filter: [] }),
      },
    },
  });

  if (dash.status < 300) {
    console.log("     ✅ Dashboard créé !");
    console.log("\n" + "=".repeat(60));
    console.log("🎉 DASHBOARD PRÊT !");
    console.log("=".repeat(60));
    console.log(`\n👉 Ouvrez :\n   ${KIBANA}/app/dashboards#/view/retention_dashboard_v1\n`);
  } else {
    console.error("❌ Erreur dashboard:", JSON.stringify(dash.body, null, 2));
  }
}

run().catch(console.error);
