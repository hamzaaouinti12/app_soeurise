/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Inscription d'un nouvel utilisateur
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [firstName, lastName, username, email, password, passwordConfirm]
 *             properties:
 *               firstName: { type: string, minLength: 2, maxLength: 50 }
 *               lastName: { type: string, minLength: 2, maxLength: 50 }
 *               username: { type: string, minLength: 3, maxLength: 30 }
 *               email: { type: string, format: email }
 *               password: { type: string, minLength: 8 }
 *               passwordConfirm: { type: string }
 *     responses:
 *       201: { description: Inscription réussie }
 *       400: { description: Validation error }
 *       409: { description: Email ou username déjà utilisé }
 *
 * /api/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Connexion d'un utilisateur
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, format: email }
 *               password: { type: string }
 *     responses:
 *       200: { description: Connexion réussie, token JWT retourné }
 *       401: { description: Identifiants invalides }
 */

/**
 * @swagger
 * /api/users/me:
 *   get:
 *     tags: [Users]
 *     summary: Mon profil
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Profil utilisateur }
 *       401: { description: Non authentifié }
 *   put:
 *     tags: [Users]
 *     summary: Modifier mon profil
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [firstName, lastName, username, email]
 *             properties:
 *               firstName: { type: string }
 *               lastName: { type: string }
 *               username: { type: string }
 *               email: { type: string }
 *     responses:
 *       200: { description: Profil modifié }
 *       400: { description: Validation error }
 *       409: { description: Username/email déjà utilisé }
 *
 * /api/users/me/avatar:
 *   put:
 *     tags: [Users]
 *     summary: Uploader/modifier mon avatar
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               avatar: { type: string, format: binary }
 *     responses:
 *       200: { description: Avatar mis à jour }
 *       400: { description: Aucun fichier envoyé }
 *   delete:
 *     tags: [Users]
 *     summary: Supprimer mon avatar
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Avatar supprimé }
 */

/**
 * @swagger
 * /api/admin/users:
 *   get:
 *     tags: [Admin]
 *     summary: Liste des utilisateurs (pagination)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10 }
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *     responses:
 *       200: { description: Liste paginée }
 *
 * /api/admin/users/{id}:
 *   get:
 *     tags: [Admin]
 *     summary: Détail d'un utilisateur
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Utilisateur trouvé }
 *       404: { description: Non trouvé }
 *   delete:
 *     tags: [Admin]
 *     summary: Supprimer un utilisateur
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Supprimé }
 *       403: { description: Auto-suppression interdite }
 *
 * /api/admin/users/{id}/role:
 *   patch:
 *     tags: [Admin]
 *     summary: Modifier le rôle
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               role: { type: string, enum: [user, admin, staff] }
 *     responses:
 *       200: { description: Rôle modifié }
 *
 * /api/admin/users/{id}/status:
 *   patch:
 *     tags: [Admin]
 *     summary: Activer/désactiver
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               isActive: { type: boolean }
 *     responses:
 *       200: { description: Statut modifié }
 */
