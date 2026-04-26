# Soeurise Backend — Checklist de Production

## Variables d'environnement requises

| Variable | Description | Exemple |
|----------|-------------|---------|
| `PORT` | Port du serveur | `4000` |
| `MONGO_URI` | URI MongoDB | `mongodb://localhost:27017/soeurise` |
| `JWT_SECRET` | Clé secrète JWT (min 32 chars) | `super_secret_key_32_chars_min` |
| `JWT_EXPIRES_IN` | Durée de validité du token | `7d` |
| `CORS_ORIGIN` | Origines autorisées | `https://soeurise.com` |
| `NODE_ENV` | Environnement | `production` |

## Sécurité

### ✅ Implémenté
- [x] `helmet()` — headers HTTP sécurisés
- [x] `cors()` — origines contrôlées via `CORS_ORIGIN`
- [x] Rate limiting — 300 req / 15 min par IP
- [x] JWT Bearer auth + vérification `isActive`
- [x] `passwordHash` jamais exposé (via `toPublic()`)
- [x] `deleteFileSafe()` — protection path traversal (interdit hors `uploads/`)
- [x] Joi validation — tous les endpoints
- [x] `stripUnknown: true` — champs non autorisés automatiquement ignorés
- [x] RBAC — admin, owner, moderator, member
- [x] Owner protection — impossible de bannir/supprimer l'owner d'un groupe

### 🔧 Recommandations production
- [ ] Utiliser HTTPS (reverse proxy Nginx/Caddy)
- [ ] `JWT_SECRET` ≥ 64 caractères, généré aléatoirement
- [ ] `CORS_ORIGIN` — jamais `*` en production
- [ ] Rate limit auth endpoints — plus restrictif (ex: 10 req / 15 min)
- [ ] Ajouter `express-mongo-sanitize` pour prévenir NoSQL injection
- [ ] Ajouter `hpp` pour prévenir HTTP Parameter Pollution
- [ ] Logs structurés (Winston) au lieu de `console.log`
- [ ] Monitoring (PM2 / Docker healthcheck)
- [ ] Backup MongoDB automatisé (mongodump / Atlas)

## Architecture

```
src/
├── app.js                     # Express setup + routes
├── server.js                  # Server startup
├── config/
│   ├── env.js                 # Variables d'environnement
│   ├── db.js                  # Connexion MongoDB
│   └── swagger.js             # Configuration OpenAPI
├── middlewares/
│   ├── auth.js                # requireAuth (JWT)
│   ├── optionalAuth.js        # optionalAuth (JWT optionnel)
│   ├── requireGroupRole.js    # Permissions groupe (admin bypass)
│   ├── uploadAvatar.js        # Multer avatars
│   ├── uploadGroupImage.js    # Multer images groupes
│   ├── errorHandler.js        # Gestion erreurs centralisée
│   └── notFound.js            # 404
├── utils/
│   ├── pagination.js          # parsePagination, formatPagination
│   ├── file.js                # deleteFileSafe, deleteAvatarFileByUrl
│   ├── jwt.js                 # signToken, verifyToken
│   └── hash.js                # hashPassword, comparePassword
├── modules/
│   ├── auth/                  # Register, Login
│   ├── users/                 # Profil, Avatar
│   ├── admin/                 # CRUD users (admin only)
│   ├── community/             # Groupes, Membres, Subscriptions
│   ├── posts/                 # (stub)
│   └── wordpress/             # (stub)
└── docs/
    └── swagger/               # JSDoc annotations OpenAPI
```

## Endpoints (24 total)

| Module | Méthode | Route | Auth |
|--------|---------|-------|------|
| Auth | POST | `/api/auth/register` | ❌ |
| Auth | POST | `/api/auth/login` | ❌ |
| Users | GET | `/api/users/me` | ✅ |
| Users | PUT | `/api/users/me` | ✅ |
| Users | PUT | `/api/users/me/avatar` | ✅ |
| Users | DELETE | `/api/users/me/avatar` | ✅ |
| Admin | GET | `/api/admin/users` | admin |
| Admin | GET | `/api/admin/users/:id` | admin |
| Admin | PATCH | `/api/admin/users/:id/role` | admin |
| Admin | PATCH | `/api/admin/users/:id/status` | admin |
| Admin | DELETE | `/api/admin/users/:id` | admin |
| Community | GET | `/api/community/groups/public` | ❌ |
| Community | GET | `/api/community/groups/:id` | optionnel |
| Community | POST | `/api/community/groups` | ✅ |
| Community | POST | `/api/community/groups/:id/join` | ✅ |
| Community | GET | `…/membership/me` | ✅ |
| Community | GET | `…/subscription/me` | ✅ |
| Mgmt | GET | `…/requests` | owner/mod |
| Mgmt | PATCH | `…/requests/:memberId` | owner/mod |
| Mgmt | POST | `…/members` | owner/mod |
| Mgmt | PATCH | `…/members/:memberId` | owner/mod |
| Mgmt | DELETE | `…/members/:memberId` | owner/mod |

## Démarrage

```bash
# Développement
npm run dev

# Production
NODE_ENV=production node src/server.js

# Documentation API interactive
open http://localhost:4000/api-docs
```
