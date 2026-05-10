const http = require("http");
const { createApp } = require("./app");
const { connectDB } = require("./db/mongoose");
const { PORT } = require("./config/env");
const { initSocket } = require("./utils/socket");

async function bootstrap() {
  await connectDB();
  const app = createApp();
  const server = http.createServer(app);

  // Initialize Socket.io
  initSocket(server);

  server.listen(PORT, () => {
    console.log(`🚀 API and Socket.io running on http://localhost:${PORT}`);
  });
}

bootstrap().catch((err) => {
  console.error("❌ Boot error:", err);
  process.exit(1);
});
