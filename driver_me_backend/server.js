const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

// Load Firebase configuration
try {
  const firebase = require('./config/firebase');
  console.log('Firebase configuration loaded successfully');
} catch (error) {
  console.error('Firebase configuration error:', error.message);
}

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));

// Root route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'DriverMe Backend API is running!',
    timestamp: new Date().toISOString()
  });
});

// Other test routes
app.get('/api/users/test', (req, res) => {
  res.json({ success: true, message: 'Users routes working!' });
});

app.get('/api/drivers/test', (req, res) => {
  res.json({ success: true, message: 'Drivers routes working!' });
});

app.get('/api/trips/test', (req, res) => {
  res.json({ success: true, message: 'Trips routes working!' });
});

app.get('/api/admin/test', (req, res) => {
  res.json({ success: true, message: 'Admin routes working!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`API URL: http://localhost:${PORT}`);
});