const mongoose = require("mongoose");
const { MONGO_URI } = require("../config/env");

async function connectDB() {
  if (!MONGO_URI) throw new Error("MONGO_URI is missing in .env");

  mongoose.set("strictQuery", true);

  await mongoose.connect(MONGO_URI, {
    autoIndex: true,
  });

  console.log("✅ MongoDB connected");
}

module.exports = { connectDB };
