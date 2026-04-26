const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Créer le dossier s'il n'existe pas
const destDir = "uploads/groups";
if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, destDir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        cb(null, `group_${Date.now()}${ext}`);
    },
});

function fileFilter(req, file, cb) {
    const allowed = ["image/jpeg", "image/png", "image/webp"];
    if (!allowed.includes(file.mimetype)) {
        return cb(new Error("Format non supporté (jpg/png/webp uniquement)"));
    }
    cb(null, true);
}

const uploadGroupImage = multer({
    storage,
    fileFilter,
    limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
});

module.exports = { uploadGroupImage };
