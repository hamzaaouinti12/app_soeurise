const { createApp } = require("./app");
const { connectDB } = require("./db/mongoose");
const { PORT } = require("./config/env");

async function bootstrap() {
  await connectDB();
  const app = createApp();

  app.listen(PORT, () => {
    console.log(`🚀 API running on http://localhost:${PORT}`);
  });
}

bootstrap().catch((err) => {
  console.error("❌ Boot error:", err);
  process.exit(1);
});
