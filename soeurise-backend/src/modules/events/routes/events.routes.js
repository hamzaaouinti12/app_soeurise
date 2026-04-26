const express = require("express");
const router = express.Router();
const eventsController = require("../controllers/events.controller");

const { requireAuth } = require("../../../middlewares/auth");
const { requireAdmin } = require("../../../middlewares/requireAdmin");

// GET /api/events
router.get("/", eventsController.getAllEvents);

// POST /api/events (Private/Admin)
router.post("/", requireAuth, requireAdmin, eventsController.createEvent);

module.exports = router;
