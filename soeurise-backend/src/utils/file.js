const fs = require("fs");
const path = require("path");

/**
 * Supprime un fichier de façon sécurisée (ne crash jamais l'API).
 * @param {string} relativePath  – chemin relatif depuis process.cwd(), ex: "/uploads/avatars/avatar_123.png"
 */
async function deleteFileSafe(relativePath) {
  try {
    if (!relativePath) return;

    const filename = path.basename(relativePath);
    const dir = path.dirname(relativePath).replace(/^\//, ""); // "uploads/avatars"
    const absolutePath = path.join(process.cwd(), dir, filename);

    // Sécurité: ne jamais remonter au-dessus de uploads/
    const uploadsDir = path.join(process.cwd(), "uploads");
    if (!absolutePath.startsWith(uploadsDir)) {
      console.warn("⚠️ deleteFileSafe: chemin hors de uploads/ ignoré");
      return;
    }

    if (fs.existsSync(absolutePath)) {
      await fs.promises.unlink(absolutePath);
    }
  } catch (err) {
    console.warn("⚠️ deleteFileSafe failed:", err.message);
  }
}

/**
 * Supprime un fichier avatar par son URL.
 * avatarUrl exemple: /uploads/avatars/avatar_123.png
 * Raccourci vers deleteFileSafe.
 */
async function deleteAvatarFileByUrl(avatarUrl) {
  return deleteFileSafe(avatarUrl);
}

module.exports = { deleteFileSafe, deleteAvatarFileByUrl };
