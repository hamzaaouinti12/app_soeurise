const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Ensure the directory exists
const uploadDir = "uploads/posts";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// storage (save in uploads/posts)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `post_${Date.now()}${ext}`);
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

const uploadPostImage = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

module.exports = { uploadPostImage };
