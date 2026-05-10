const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { JWT_SECRET } = require("../config/env");
const User = require("../modules/users/models/User");

let io;
const userSockets = new Map(); // userId -> [socketId1, socketId2, ...]

function initSocket(server) {
  io = new Server(server, {
    cors: {
      origin: "*", // Adjust as needed
      methods: ["GET", "POST"],
    },
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;
      if (!token) {
        return next(new Error("Authentication error: No token provided"));
      }

      const decoded = jwt.verify(token, JWT_SECRET);
      const userId = decoded.sub || decoded.userId || decoded.id;
      const user = await User.findById(userId);
      if (!user) {
        return next(new Error("Authentication error: User not found"));
      }

      socket.user = user;
      next();
    } catch (err) {
      console.error("Socket Auth Error:", err.message);
      next(new Error("Authentication error"));
    }
  });

  io.on("connection", (socket) => {
    const userId = socket.user._id.toString();
    console.log(`[Socket] User connected: ${userId} (${socket.id})`);

    // Add to userSockets map
    if (!userSockets.has(userId)) {
      userSockets.set(userId, []);
    }
    userSockets.get(userId).push(socket.id);

    socket.on("disconnect", () => {
      console.log(`[Socket] User disconnected: ${socket.id}`);
      const sockets = userSockets.get(userId);
      if (sockets) {
        const index = sockets.indexOf(socket.id);
        if (index > -1) {
          sockets.splice(index, 1);
        }
        if (sockets.length === 0) {
          userSockets.delete(userId);
        }
      }
    });

    // Handle joining specific rooms (e.g., community rooms)
    socket.on("join_room", (room) => {
      socket.join(room);
      console.log(`[Socket] Socket ${socket.id} joined room ${room}`);
    });

    socket.on("leave_room", (room) => {
      socket.leave(room);
      console.log(`[Socket] Socket ${socket.id} left room ${room}`);
    });
  });

  return io;
}

function getIO() {
  if (!io) {
    throw new Error("Socket.io not initialized!");
  }
  return io;
}

function sendToUser(userId, event, data) {
  const sockets = userSockets.get(userId.toString());
  if (sockets && sockets.length > 0) {
    sockets.forEach((socketId) => {
      io.to(socketId).emit(event, data);
    });
    return true;
  }
  return false;
}

module.exports = { initSocket, getIO, sendToUser };
