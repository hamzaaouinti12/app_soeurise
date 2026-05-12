const multer = require("multer");
const path = require("path");
const fs = require("fs");

const uploadDir = "uploads/stories";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `story_${Date.now()}${ext}`);
  },
});

function fileFilter(req, file, cb) {
  const allowed = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "video/mp4",
    "video/quicktime",
    "video/webm",
  ];
  if (!allowed.includes(file.mimetype)) {
    return cb(new Error("Format non supporté (jpg/png/webp/mp4/mov/webm uniquement)"));
  }
  cb(null, true);
}

const uploadStoryMedia = multer({
  storage,
  fileFilter,
  limits: { fileSize: 50 * 1024 * 1024 },
});

module.exports = { uploadStoryMedia };
