/**
 * @swagger
 * /api/community/groups/public:
 *   get:
 *     tags: [Community]
 *     summary: Liste des groupes publics (pagination)
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10, maximum: 50 }
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *     responses:
 *       200: { description: Liste paginée des groupes publics }
 *
 * /api/community/groups/{id}:
 *   get:
 *     tags: [Community]
 *     summary: Voir un groupe (optionalAuth pour privé)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Groupe trouvé }
 *       403: { description: Groupe privé, non-membre }
 *       404: { description: Groupe non trouvé }
 *
 * /api/community/groups:
 *   post:
 *     tags: [Community]
 *     summary: Créer un groupe (+ image optionnelle)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name: { type: string, minLength: 3, maxLength: 80 }
 *               description: { type: string, maxLength: 500 }
 *               isPublic: { type: boolean, default: true }
 *               requiresSubscription: { type: boolean, default: false }
 *               image: { type: string, format: binary }
 *     responses:
 *       201: { description: Groupe créé }
 *       409: { description: Nom déjà utilisé }
 *
 * /api/community/groups/{id}/join:
 *   post:
 *     tags: [Community]
 *     summary: Rejoindre un groupe
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       201: { description: Rejoint (public=active, privé=pending) }
 *       403: { description: Banni ou subscription requise }
 *       409: { description: Déjà membre ou demande en cours }
 *
 * /api/community/groups/{id}/membership/me:
 *   get:
 *     tags: [Community]
 *     summary: Mon membership dans un groupe
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: "status: none|pending|active|banned + roleInGroup" }
 *
 * /api/community/groups/{id}/subscription/me:
 *   get:
 *     tags: [Community]
 *     summary: Ma subscription dans un groupe
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: isSubscribed, plan, status }
 */

/**
 * @swagger
 * /api/community/groups/{id}/requests:
 *   get:
 *     tags: [Community Management]
 *     summary: Liste des demandes pending (owner/mod/admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Liste des demandes pending }
 *       403: { description: Permissions insuffisantes }
 *
 * /api/community/groups/{id}/requests/{memberId}:
 *   patch:
 *     tags: [Community Management]
 *     summary: Accepter/rejeter une demande (owner/mod/admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *       - in: path
 *         name: memberId
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [action]
 *             properties:
 *               action: { type: string, enum: [accept, reject] }
 *     responses:
 *       200: { description: Demande traitée }
 *       404: { description: Demande non trouvée }
 *
 * /api/community/groups/{id}/members:
 *   post:
 *     tags: [Community Management]
 *     summary: Ajouter un membre directement (owner/mod/admin)
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
 *             required: [userId]
 *             properties:
 *               userId: { type: string }
 *               roleInGroup: { type: string, enum: [member, moderator], default: member }
 *     responses:
 *       201: { description: Membre ajouté }
 *       409: { description: Doublon }
 *
 * /api/community/groups/{id}/members/{memberId}:
 *   patch:
 *     tags: [Community Management]
 *     summary: Modifier un membre (role/status) (owner/mod/admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *       - in: path
 *         name: memberId
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               roleInGroup: { type: string, enum: [member, moderator, owner] }
 *               status: { type: string, enum: [active, banned] }
 *     responses:
 *       200: { description: Membre modifié }
 *       403: { description: Impossible de bannir l'owner }
 *   delete:
 *     tags: [Community Management]
 *     summary: Supprimer un membre (owner/mod/admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *       - in: path
 *         name: memberId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Membre supprimé }
 *       403: { description: Impossible de supprimer l'owner }
 */
