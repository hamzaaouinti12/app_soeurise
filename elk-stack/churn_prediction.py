"""
╔══════════════════════════════════════════════════════════════════╗
║       SOEURISE — Prédiction du Churn (ML)                       ║
║       Algorithme : Random Forest Classifier                      ║
║       Données   : soeurise_data_10000.xlsx                       ║
╚══════════════════════════════════════════════════════════════════╝
"""

import pandas as pd
import numpy as np
import json
import warnings
import sys
warnings.filterwarnings("ignore")

from datetime import datetime, timezone
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import (classification_report, confusion_matrix,
                             accuracy_score, roc_auc_score)
from sklearn.pipeline import Pipeline
import joblib

# ─── Config ──────────────────────────────────────────────────────────────────
EXCEL_FILE  = "C:/Users/MSI/Desktop/projetpfe/soeurise_data_10000.xlsx"
MODEL_FILE  = "churn_model.pkl"
RESULTS_FILE = "churn_results.json"
CHURN_DAYS  = 30   # inactive > 30 jours = churned
NOW         = datetime.now(timezone.utc)

print("=" * 60)
print("  SOEURISE — CHURN PREDICTION ML")
print("=" * 60)

# ─── 1. Chargement des données ────────────────────────────────────────────────
print("\n📂 Chargement du fichier Excel...")
df = pd.read_excel(EXCEL_FILE, engine="openpyxl")
print(f"   ✅ {len(df)} lignes chargées")
print(f"   📋 Colonnes : {list(df.columns)}")

# ─── 2. Préparation des features ──────────────────────────────────────────────
print("\n🔧 Préparation des features...")

# Convertir les dates
df["derniere_connexion"] = pd.to_datetime(df["derniere_connexion"], utc=True, errors="coerce")
df["timestamp"]          = pd.to_datetime(df["timestamp"], utc=True, errors="coerce")

# Feature : jours depuis dernière connexion
df["jours_inactif"] = (NOW - df["derniere_connexion"]).dt.days.fillna(999)

# Feature : ancienneté sur la plateforme (jours depuis inscription)
df["anciennete_jours"] = (NOW - df["timestamp"]).dt.days.fillna(0)

# Feature : ratio likes par post
df["likes_par_post"] = np.where(
    df["nombre_posts"] > 0,
    df["total_likes_recus"] / df["nombre_posts"],
    0
)

# Feature : ratio commentaires par post
df["commentaires_par_post"] = np.where(
    df["nombre_posts"] > 0,
    df["total_commentaires_recus"] / df["nombre_posts"],
    0
)

# Feature : score d'activité social
df["score_social"] = (
    df["total_likes_recus"] +
    df["total_commentaires_recus"] * 2 +
    df["total_reposts_recus"] * 3
)

# Feature : score d'engagement global
df["score_engagement_global"] = (
    df["nombre_posts"] * 2 +
    df["masterclass_achetees"] * 5 +
    df["evenements_inscrits"] * 3 +
    df["taux_engagement"]
)

# Feature : compte Premium = 1, Standard = 0
df["est_premium"] = (df["statut_compte"] == "Premium").astype(int)

# Feature : communauté encodée
le = LabelEncoder()
df["communaute_encoded"] = le.fit_transform(df["communaute_active"].fillna("Autre"))

# ─── 3. Définition de la cible (CHURN) ───────────────────────────────────────
print("\n🎯 Définition de la cible churn...")

# Churn = score comportemental combinant plusieurs signaux
# (on N'utilise PAS jours_inactif pour éviter le data leakage)
df["churn_score_raw"] = 0
df["churn_score_raw"] += (df["nombre_posts"] == 0).astype(int) * 2
df["churn_score_raw"] += (df["masterclass_achetees"] == 0).astype(int) * 2
df["churn_score_raw"] += (df["evenements_inscrits"] == 0).astype(int) * 1
df["churn_score_raw"] += (df["taux_engagement"] < 30).astype(int) * 2
df["churn_score_raw"] += (df["score_social"] == 0).astype(int) * 2
df["churn_score_raw"] += (df["anciennete_jours"] > 300).astype(int) * 1

# Churn = score comportemental >= 4 (utilisatrice très peu engagée)
df["churn"] = (df["churn_score_raw"] >= 4).astype(int)

churned_count = df["churn"].sum()
stable_count  = len(df) - churned_count
print(f"   • Churned (peu engagées) : {churned_count} ({churned_count/len(df)*100:.1f}%)")
print(f"   • Stable  (engagées)     : {stable_count}  ({stable_count/len(df)*100:.1f}%)")

# ─── 4. Sélection des features ────────────────────────────────────────────────
# ⚠️ jours_inactif est EXCLU pour éviter le data leakage
FEATURES = [
    "nombre_posts",
    "total_likes_recus",
    "total_commentaires_recus",
    "total_reposts_recus",
    "masterclass_achetees",
    "evenements_inscrits",
    "taux_engagement",
    "anciennete_jours",
    "likes_par_post",
    "commentaires_par_post",
    "score_social",
    "score_engagement_global",
    "est_premium",
    "communaute_encoded",
]

X = df[FEATURES].fillna(0)
y = df["churn"]

# ─── 5. Split Train / Test ────────────────────────────────────────────────────
print("\n✂️  Split Train/Test (80% / 20%)...")
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print(f"   Train : {len(X_train)} | Test : {len(X_test)}")

# ─── 6. Entraînement ─────────────────────────────────────────────────────────
print("\n🤖 Entraînement du modèle Random Forest...")
model = RandomForestClassifier(
    n_estimators=200,
    max_depth=10,
    min_samples_split=5,
    min_samples_leaf=2,
    class_weight="balanced",
    random_state=42,
    n_jobs=-1,
)
model.fit(X_train, y_train)
print("   ✅ Modèle entraîné !")

# ─── 7. Évaluation ───────────────────────────────────────────────────────────
print("\n📊 Évaluation du modèle...")
y_pred      = model.predict(X_test)
y_pred_proba = model.predict_proba(X_test)[:, 1]

accuracy = accuracy_score(y_test, y_pred)
auc      = roc_auc_score(y_test, y_pred_proba)
cv_scores = cross_val_score(model, X, y, cv=5, scoring="accuracy")

print(f"\n   📈 Accuracy       : {accuracy*100:.2f}%")
print(f"   📈 AUC-ROC        : {auc:.4f}")
print(f"   📈 CV Score (5x)  : {cv_scores.mean()*100:.2f}% ± {cv_scores.std()*100:.2f}%")
print(f"\n   {classification_report(y_test, y_pred, target_names=['Stable','Churned'])}")

# Importance des features
feat_imp = pd.DataFrame({
    "feature": FEATURES,
    "importance": model.feature_importances_
}).sort_values("importance", ascending=False)
print("\n   🔑 Top 5 features importantes :")
for _, row in feat_imp.head(5).iterrows():
    bar = "█" * int(row["importance"] * 50)
    print(f"   {row['feature']:<30} {bar} {row['importance']:.4f}")

# ─── 8. Prédictions sur toutes les utilisatrices ─────────────────────────────
print("\n🔮 Calcul des prédictions sur 10 000 utilisatrices...")
df["churn_score"]  = model.predict_proba(X)[:, 1]  # probabilité 0.0 → 1.0
df["churn_label"]  = model.predict(X)               # 0 = Stable, 1 = Churned

# Catégorie de risque
def risk_category(score):
    if score >= 0.75: return "Critique"
    if score >= 0.50: return "Élevé"
    if score >= 0.25: return "Moyen"
    return "Faible"

df["risk_level"] = df["churn_score"].apply(risk_category)

# Raison principale du churn
def main_reason(row):
    reasons = []
    if row["jours_inactif"] > 60:   reasons.append("Inactive +60j")
    elif row["jours_inactif"] > 30: reasons.append("Inactive +30j")
    if row["nombre_posts"] == 0:    reasons.append("Aucun post")
    if row["masterclass_achetees"] == 0: reasons.append("Aucune masterclass")
    if row["taux_engagement"] < 20: reasons.append("Faible engagement")
    if row["score_social"] == 0:    reasons.append("Aucune interaction")
    return " · ".join(reasons[:2]) if reasons else "Profil actif"

df["churn_reason"] = df.apply(main_reason, axis=1)

# ─── 9. Statistiques finales ─────────────────────────────────────────────────
stats = {
    "model_accuracy":  round(accuracy * 100, 2),
    "model_auc":       round(auc, 4),
    "cv_score":        round(cv_scores.mean() * 100, 2),
    "total_users":     len(df),
    "churn_critique":  int((df["risk_level"] == "Critique").sum()),
    "churn_eleve":     int((df["risk_level"] == "Élevé").sum()),
    "churn_moyen":     int((df["risk_level"] == "Moyen").sum()),
    "churn_faible":    int((df["risk_level"] == "Faible").sum()),
    "churn_total_predicted": int(df["churn_label"].sum()),
    "stable_total":    int((df["churn_label"] == 0).sum()),
    "avg_churn_score": round(df["churn_score"].mean(), 4),
    "feature_importance": feat_imp.head(10).to_dict("records"),
    "risk_by_community": df.groupby("communaute_active")["churn_score"].mean().round(4).to_dict(),
    "risk_by_status":    df.groupby("statut_compte")["churn_score"].mean().round(4).to_dict(),
    "confusion_matrix":  confusion_matrix(y_test, y_pred).tolist(),
    "generated_at":      datetime.now().isoformat(),
    # Top 10 utilisatrices à risque critique
    "top_at_risk": df[df["risk_level"] == "Critique"].nlargest(10, "churn_score")[
        ["prenom", "email", "churn_score", "jours_inactif", "churn_reason", "communaute_active"]
    ].to_dict("records"),
}

# Distribution des scores par décile
score_dist = {}
for i in range(0, 10):
    lo, hi = i/10, (i+1)/10
    cnt = int(((df["churn_score"] >= lo) & (df["churn_score"] < hi)).sum())
    score_dist[f"{int(lo*100)}-{int(hi*100)}%"] = cnt
stats["score_distribution"] = score_dist

print("\n📊 Résumé des prédictions :")
print(f"   🔴 Critique  (≥75%) : {stats['churn_critique']:>5} utilisatrices")
print(f"   🟠 Élevé     (≥50%) : {stats['churn_eleve']:>5} utilisatrices")
print(f"   🟡 Moyen     (≥25%) : {stats['churn_moyen']:>5} utilisatrices")
print(f"   🟢 Faible    (<25%) : {stats['churn_faible']:>5} utilisatrices")

# ─── 10. Sauvegarde ──────────────────────────────────────────────────────────
print(f"\n💾 Sauvegarde des résultats...")
with open(RESULTS_FILE, "w", encoding="utf-8") as f:
    json.dump(stats, f, ensure_ascii=False, indent=2, default=str)
print(f"   ✅ {RESULTS_FILE}")

joblib.dump(model, MODEL_FILE)
print(f"   ✅ {MODEL_FILE}")

# CSV des prédictions
df[["prenom","email","statut_compte","communaute_active",
    "churn_score","churn_label","risk_level","churn_reason",
    "jours_inactif","nombre_posts","taux_engagement"]].to_csv(
    "churn_predictions.csv", index=False, encoding="utf-8-sig"
)
print(f"   ✅ churn_predictions.csv")

print("\n" + "=" * 60)
print("  ✅ CHURN PREDICTION TERMINÉ !")
print(f"  🎯 Accuracy : {accuracy*100:.2f}%  |  AUC : {auc:.4f}")
print(f"  🔴 {stats['churn_critique']} utilisatrices en risque CRITIQUE")
print("=" * 60)
print("\n👉 Lance maintenant : python churn_dashboard.py")
