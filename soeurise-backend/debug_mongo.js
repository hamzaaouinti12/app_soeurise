const mongoose = require("mongoose");
require("dotenv").config();

async function checkCollections() {
    await mongoose.connect(process.env.MONGO_URI);
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log("Collections:", collections.map(c => c.name));

    const Masterclass = mongoose.model("Masterclass", new mongoose.Schema({}, { strict: false }));
    const data = await Masterclass.find();
    console.log("Masterclass model find result:", data.length);

    process.exit(0);
}

checkCollections();
