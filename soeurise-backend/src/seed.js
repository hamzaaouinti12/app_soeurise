require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("./modules/users/models/User");
const Masterclass = require("./modules/masterclass/models/Masterclass");
const Event = require("./modules/events/models/Event");
const Post = require("./modules/posts/models/Post");
const Group = require("./modules/community/models/Group");
const { MONGO_URI } = require("./config/env");

const masterclasses = [
  {
    title: "Introduction à l'entrepreneuriat",
    description: "Les bases pour démarrer votre projet",
    instructorName: "Fatima Al-Rashid",
    videoUrl: "https://example.com/video1",
    thumbnailUrl: "https://images.unsplash.com/photo-1573164713988-8665fc963095?auto=format&fit=crop&q=80",
  },
  {
    title: "Gestion financière pour femmes",
    description: "Maîtriser ses finances personnelles",
    instructorName: "Aisha Mohammed",
    videoUrl: "https://example.com/video2",
    thumbnailUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80",
  },
  {
    title: "Le Design Thinking pour Créatrices",
    description: "Comment concevoir des produits que vos clients vont adorer",
    instructorName: "Maya Dubois",
    videoUrl: "https://example.com/video3",
    thumbnailUrl: "https://images.unsplash.com/photo-1542744173-05336fcc7ad4?auto=format&fit=crop&q=80",
  },
];

const events = [
  {
    title: "Webinaire: Femmes Leaders",
    dateTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    type: "online",
    location: "Zoom",
    imageUrl: "https://images.unsplash.com/photo-1542744173-8e7e53415bb0?auto=format&fit=crop&q=80",
  },
  {
    title: "Conférence Annuelle Soeurise",
    dateTime: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    type: "physical",
    location: "Casablanca, Maroc",
    imageUrl: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&q=80",
  },
  {
    title: "Atelier Pitch & Networking",
    dateTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    type: "physical",
    location: "Abidjan, Côte d'Ivoire",
    imageUrl: "https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&q=80",
  },
];

async function seedDB() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connecté à MongoDB...");

    // Clear existing
    await User.deleteMany({});
    await Masterclass.deleteMany({});
    await Event.deleteMany({});
    await Post.deleteMany({});
    await Group.deleteMany({});
    console.log("Toutes les collections ont été vidées.");

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash("Password123!", salt);
    const adminHash = await bcrypt.hash("Admin123!", salt);

    // Create Users
    const users = await User.insertMany([
      {
        firstName: "Admin",
        lastName: "Soeurise",
        username: "admin",
        email: "admin@soeurise.com",
        passwordHash: adminHash,
        role: "admin",
        isActive: true,
      },
      {
        firstName: "Sarah",
        lastName: "Mbaye",
        username: "sarah_m",
        email: "sarah@example.com",
        passwordHash,
        role: "user",
        isActive: true,
      },
      {
        firstName: "Leila",
        lastName: "Tazi",
        username: "leila_t",
        email: "leila@example.com",
        passwordHash,
        role: "user",
        isActive: true,
      },
      {
        firstName: "Grace",
        lastName: "Okonkwo",
        username: "grace_o",
        email: "grace@example.com",
        passwordHash,
        role: "user",
        isActive: true,
      },
    ]);
    console.log("✅ Utilisateurs créés.");

    const admin = users[0];
    const user1 = users[1];
    const user2 = users[2];

    // Create Groups (Communities)
    const groups = await Group.insertMany([
      {
        name: "Entrepreneuriat Tech",
        description: "Partagez vos astuces sur le développement et les startups tech.",
        imageUrl: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80",
        createdBy: admin._id,
      },
      {
        name: "Art & Créativité",
        description: "Un espace pour les créatrices et artistes féminines.",
        imageUrl: "https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&q=80",
        createdBy: user1._id,
      },
    ]);
    console.log("✅ Communautés créées.");

    // Create Posts
    await Post.insertMany([
      {
        author: user1._id,
        content: "Je viens de lancer ma boutique en ligne ! Trop hâte de partager cette aventure avec vous.",
        image: "https://images.unsplash.com/photo-1544717297-fa3200782631?auto=format&fit=crop&q=80",
        likesCount: 12,
        commentsCount: 2,
      },
      {
        author: user2._id,
        content: "Quelqu'un a des conseils pour le marketing sur Instagram ?",
        likesCount: 5,
        commentsCount: 8,
      },
      {
        author: admin._id,
        communityId: groups[0]._id,
        content: "Bienvenue dans le groupe Tech ! N'hésitez pas à poser vos questions sur l'IA.",
        likesCount: 45,
        commentsCount: 15,
      },
    ]);
    console.log("✅ Publications créées.");

    // Insert Masterclasses and Events
    await Masterclass.insertMany(masterclasses);
    await Event.insertMany(events);
    console.log("✅ Masterclasses et Événements insérés avec succès !");

    console.log("\nSeeds terminés !");
    console.log("Admin : admin@soeurise.com / Admin123!");
    console.log("User : sarah@example.com / Password123!");

    process.exit(0);
  } catch (err) {
    console.error("Erreur de seeding :", err);
    process.exit(1);
  }
}

seedDB();
