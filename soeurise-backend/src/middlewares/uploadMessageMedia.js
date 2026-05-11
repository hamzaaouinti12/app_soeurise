const multer = require("multer");
const path = require("path");
const fs = require("fs");

const uploadDir = "uploads/messages";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `msg_${Date.now()}${ext}`);
  },
});

function fileFilter(req, file, cb) {
  const allowed = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "audio/mpeg",
    "audio/mp4",
    "audio/aac",
    "audio/wav",
    "audio/ogg",
    "audio/webm",
    "audio/3gpp",
  ];
  if (allowed.includes(file.mimetype)) {
    return cb(null, true);
  }

  if (file.mimetype === "application/octet-stream") {
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedExt = [
      ".jpg",
      ".jpeg",
      ".png",
      ".webp",
      ".mp3",
      ".m4a",
      ".aac",
      ".wav",
      ".ogg",
      ".webm",
      ".3gp",
    ];
    if (allowedExt.includes(ext)) {
      return cb(null, true);
    }
  }

  return cb(new Error("Format non supporte (image ou audio uniquement)"));
}

const uploadMessageMedia = multer({
  storage,
  fileFilter,
  limits: { fileSize: 20 * 1024 * 1024 },
});

module.exports = { uploadMessageMedia };
