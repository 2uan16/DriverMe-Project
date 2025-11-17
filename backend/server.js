const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const bookingRoutes = require('./routes/bookings');
const driverRoutes = require('./routes/drivers');
const adminRoutes = require('./routes/admin');

// Import database
const db = require('./config/database');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));
app.use((req, res, next) => {
  req.app.io = io;
  next();
  });

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/admin', adminRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'DriverMe API is running',
    timestamp: new Date().toISOString()
  });
});

// Socket.IO for real-time features
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // User joins with their ID
  socket.on('join', (userId) => {
    connectedUsers.set(userId, socket.id);
    console.log(`User ${userId} joined with socket ${socket.id}`);
  });

  // Driver location updates
  socket.on('update_location', (data) => {
    const { driverId, latitude, longitude } = data;

    // Update driver location in database
    db.run(
      'UPDATE driver_profiles SET current_latitude = ?, current_longitude = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [latitude, longitude, driverId],
      (err) => {
        if (err) {
          console.error('Error updating driver location:', err);
        }
      }
    );

    // Broadcast to nearby users or specific booking
    socket.broadcast.emit('driver_location_updated', {
      driverId,
      latitude,
      longitude
    });
  });

  // Booking updates
  socket.on('booking_update', (data) => {
    const { bookingId, status, userId, driverId } = data;

    // Send to specific user
    if (userId && connectedUsers.has(userId)) {
      io.to(connectedUsers.get(userId)).emit('booking_status_changed', {
        bookingId,
        status
      });
    }

    // Send to specific driver
    if (driverId && connectedUsers.has(driverId)) {
      io.to(connectedUsers.get(driverId)).emit('booking_status_changed', {
        bookingId,
        status
      });
    }
  });

  // Driver availability toggle
  socket.on('toggle_availability', (data) => {
    const { driverId, isAvailable } = data;

    db.run(
      'UPDATE driver_profiles SET is_available = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [isAvailable, driverId],
      (err) => {
        if (err) {
          console.error('Error updating driver availability:', err);
        } else {
          socket.emit('availability_updated', { isAvailable });
        }
      }
    );
  });

  // Disconnect
  socket.on('disconnect', () => {
    // Remove user from connected users
    for (let [userId, socketId] of connectedUsers.entries()) {
      if (socketId === socket.id) {
        connectedUsers.delete(userId);
        break;
      }
    }
    console.log('User disconnected:', socket.id);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🚀 DriverMe Server running on port ${PORT}`);
  console.log(`📱 API Base URL: http://localhost:${PORT}/api`);
  console.log(`🌐 Socket.IO running on port ${PORT}`);

  // Initialize database
  console.log('📊 Initializing database...');
  require('./config/init-db');
});

module.exports = { app, io };