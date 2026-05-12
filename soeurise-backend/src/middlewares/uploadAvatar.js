const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Ensure uploads/avatars directory exists
const uploadsDir = path.join(__dirname, "../../uploads/avatars");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// storage (save in uploads/avatars)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `avatar_${Date.now()}${ext}`);
  },
});

function fileFilter(req, file, cb) {
  const allowedMimes = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
    "image/jpg",
    "application/octet-stream",
  ];
  const allowedExts = [".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"];
  const ext = path.extname(file.originalname || "").toLowerCase();

  if (!allowedMimes.includes(file.mimetype) && !allowedExts.includes(ext)) {
    return cb(new Error("Format non supporte (jpg/png/webp/heic uniquement)"));
  }
  cb(null, true);
}

const uploadAvatar = multer({
  storage,
  fileFilter,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
});

module.exports = { uploadAvatar };
