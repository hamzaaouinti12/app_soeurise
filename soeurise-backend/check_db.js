const mongoose = require("mongoose");
const Masterclass = require("./src/modules/masterclass/models/Masterclass");
require("dotenv").config();

async function checkData() {
  await mongoose.connect(process.env.MONGO_URI);
  const count = await Masterclass.countDocuments();
  console.log("Number of masterclasses:", count);
  const data = await Masterclass.find();
  console.log("Data:", JSON.stringify(data, null, 2));
  process.exit(0);
}

checkData();
