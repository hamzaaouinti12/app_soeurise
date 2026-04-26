const swaggerJsdoc = require("swagger-jsdoc");

const options = {
    definition: {
        openapi: "3.0.0",
        info: {
            title: "Soeurise API",
            version: "1.0.0",
            description: "API Backend — Gestion utilisateurs, communautés, groupes",
            contact: {
                name: "Soeurise Team",
            },
        },
        servers: [
            {
                url: "http://localhost:4000",
                description: "Serveur local",
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: "http",
                    scheme: "bearer",
                    bearerFormat: "JWT",
                },
            },
            schemas: {
                User: {
                    type: "object",
                    properties: {
                        id: { type: "string" },
                        firstName: { type: "string" },
                        lastName: { type: "string" },
                        username: { type: "string" },
                        email: { type: "string" },
                        avatarUrl: { type: "string" },
                        role: { type: "string", enum: ["user", "admin", "staff"] },
                        isActive: { type: "boolean" },
                        createdAt: { type: "string", format: "date-time" },
                    },
                },
                Group: {
                    type: "object",
                    properties: {
                        id: { type: "string" },
                        name: { type: "string" },
                        description: { type: "string" },
                        imageUrl: { type: "string" },
                        isPublic: { type: "boolean" },
                        requiresSubscription: { type: "boolean" },
                        createdBy: { type: "string" },
                        createdAt: { type: "string", format: "date-time" },
                        updatedAt: { type: "string", format: "date-time" },
                    },
                },
                GroupMember: {
                    type: "object",
                    properties: {
                        id: { type: "string" },
                        groupId: { type: "string" },
                        userId: { type: "string" },
                        roleInGroup: { type: "string", enum: ["owner", "moderator", "member"] },
                        status: { type: "string", enum: ["pending", "active", "banned"] },
                        joinedAt: { type: "string", format: "date-time" },
                    },
                },
                Subscription: {
                    type: "object",
                    properties: {
                        id: { type: "string" },
                        groupId: { type: "string" },
                        userId: { type: "string" },
                        plan: { type: "string", enum: ["free", "premium", "member"] },
                        status: { type: "string", enum: ["active", "inactive"] },
                        startedAt: { type: "string", format: "date-time" },
                        endedAt: { type: "string", format: "date-time" },
                    },
                },
                Pagination: {
                    type: "object",
                    properties: {
                        page: { type: "integer" },
                        limit: { type: "integer" },
                        total: { type: "integer" },
                        totalPages: { type: "integer" },
                    },
                },
                Error: {
                    type: "object",
                    properties: {
                        success: { type: "boolean", example: false },
                        message: { type: "string" },
                    },
                },
            },
        },
        tags: [
            { name: "Auth", description: "Inscription & connexion" },
            { name: "Users", description: "Profil utilisateur" },
            { name: "Admin", description: "Administration (admin only)" },
            { name: "Community", description: "Groupes & communauté" },
            { name: "Community Management", description: "Gestion membres & demandes" },
        ],
    },
    apis: ["./src/docs/swagger/*.js"],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = { swaggerSpec };
