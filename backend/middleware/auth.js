const jwt = require('jsonwebtoken');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'driverme_secret_key_2024';

// Authenticate JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token xác thực là bắt buộc'
    });
  }

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token đã hết hạn'
        });
      }
      return res.status(403).json({
        success: false,
        message: 'Token không hợp lệ'
      });
    }

    req.user = decoded;
    next();
  });
};

// Authorize roles
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Vui lòng đăng nhập'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền truy cập'
      });
    }

    next();
  };
};

// Check if user exists and is active
const checkUserStatus = (req, res, next) => {
  db.get(
    'SELECT id, is_active, is_verified FROM users WHERE id = ?',
    [req.user.id],
    (err, user) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Lỗi server'
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'Người dùng không tồn tại'
        });
      }

      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          message: 'Tài khoản đã bị vô hiệu hóa'
        });
      }

      req.userStatus = user;
      next();
    }
  );
};

module.exports = {
  authenticateToken,
  authorizeRoles,
  checkUserStatus
};