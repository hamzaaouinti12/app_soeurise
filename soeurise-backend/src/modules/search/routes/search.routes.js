const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const searchController = require("../controllers/search.controller");

router.use(requireAuth);

router.get("/", searchController.searchAll);

module.exports = router;
