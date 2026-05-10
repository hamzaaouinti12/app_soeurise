const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { uploadStoryMedia } = require("../../../middlewares/uploadStoryMedia");
const storiesController = require("../controllers/stories.controller");

router.use(requireAuth);

router.get("/", storiesController.getActiveStories);
router.get("/user/:userId", storiesController.getUserStories);
router.post("/", uploadStoryMedia.single("media"), storiesController.createStory);
router.post("/:id/view", storiesController.addView);
router.post("/:id/reactions", storiesController.reactToStory);
router.delete("/:id", storiesController.deleteStory);

module.exports = router;
