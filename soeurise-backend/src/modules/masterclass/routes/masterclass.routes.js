const express = require("express");
const router = express.Router();
const masterclassController = require("../controllers/masterclass.controller");

// GET /api/masterclass
router.get("/", masterclassController.getAllMasterclasses);

module.exports = router;
