const router = require("express").Router();

router.get("/", (req, res) => {
  res.json({ module: "posts", status: "ok" });
});

module.exports = router;
