const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const reportsController = require("../controllers/reports.controller");

router.use(requireAuth);

router.post("/", reportsController.createReport);

module.exports = router;
