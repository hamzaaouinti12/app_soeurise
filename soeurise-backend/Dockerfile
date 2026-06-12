# ─── Build Stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances de production uniquement
RUN npm ci --omit=dev

# ─── Production Stage ──────────────────────────────────────────────────────────
FROM node:20-alpine

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S soeurise -u 1001

WORKDIR /app

# Copier les node_modules depuis le builder
COPY --from=builder /app/node_modules ./node_modules

# Copier le code source
COPY src ./src
COPY package*.json ./

# Créer le dossier uploads avec les bonnes permissions
RUN mkdir -p uploads && chown -R soeurise:nodejs /app

# Basculer vers l'utilisateur non-root
USER soeurise

# Port exposé (Render utilise la variable PORT dynamiquement)
EXPOSE 4000

# Healthcheck pour Render
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:' + (process.env.PORT || 4000) + '/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

# Démarrer l'application
CMD ["node", "src/server.js"]
