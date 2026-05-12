const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const { CORS_ORIGIN } = require("./config/env");

const { notFound } = require("./middlewares/notFound");
const { errorHandler } = require("./middlewares/errorHandler");
const swaggerUi = require("swagger-ui-express");
const { swaggerSpec } = require("./config/swagger");

// Routes
const authRoutes = require("./modules/auth/routes/auth.routes");
const userRoutes = require("./modules/users/routes/users.routes");
const postRoutes = require("./modules/posts/routes/posts.routes");
const wpRoutes = require("./modules/wordpress/routes/wp.routes");
const adminRoutes = require("./modules/admin/routes/admin.routes");
const communityRoutes = require("./modules/community/routes/community.routes");
const masterclassRoutes = require("./modules/masterclass/routes/masterclass.routes");
const eventsRoutes = require("./modules/events/routes/events.routes");
const notificationRoutes = require("./modules/notifications/routes/notifications.routes");
const messageRoutes = require("./modules/messages/routes/messages.routes");
const storyRoutes = require("./modules/stories/routes/stories.routes");
const searchRoutes = require("./modules/search/routes/search.routes");
const reportRoutes = require("./modules/reports/routes/reports.routes");

function createApp() {
  const app = express();

  // Allow uploads (e.g. /uploads/...) to be embedded from another origin (Flutter Web on another port).
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: "cross-origin" },
    })
  );
  app.use(cors({ origin: CORS_ORIGIN === "*" ? true : CORS_ORIGIN }));
  app.use(express.json({ limit: "2mb" }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan("dev"));
  app.use((req, res, next) => {
    console.log(`[DEBUG] Incoming Request: ${req.method} ${req.url}`);
    next();
  });

  // ✅ SERVIR LES IMAGES UPLOADÉES
  const path = require("path");
  app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 300,
      standardHeaders: true,
      legacyHeaders: false,
    })
  );

  app.get("/health", (req, res) =>
    res.json({ ok: true, service: "soeurise-api" })
  );

  // 📚 Swagger API Docs
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

  // API routes
  app.use("/api/auth", authRoutes);
  app.use("/api/users", userRoutes);
  app.use("/api/posts", postRoutes);
  app.use("/api/wp", wpRoutes);
  app.use("/api/admin", adminRoutes);
  app.use("/api/community", communityRoutes);
  app.use("/api/masterclasses", masterclassRoutes);
  app.use("/api/events", eventsRoutes);
  app.use("/api/notifications", notificationRoutes);
  app.use("/api/messages", messageRoutes);
  app.use("/api/stories", storyRoutes);
  app.use("/api/search", searchRoutes);
  app.use("/api/reports", reportRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
