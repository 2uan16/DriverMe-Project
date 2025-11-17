const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'driverme_secret_key_2024';

// Generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
};

// Register user
router.post('/register', async (req, res) => {
  try {
    const { email, password, full_name, phone, role = 'user' } = req.body;

    if (!email || !password || !full_name || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ thông tin'
      });
    }

    // Check existing user
    db.get('SELECT id FROM users WHERE email = ?', [email], async (err, existingUser) => {
      if (err) {
        return res.status(500).json({ success: false, message: 'Lỗi server' });
      }

      if (existingUser) {
        return res.status(400).json({ success: false, message: 'Email đã được sử dụng' });
      }

      try {
        const hashedPassword = await bcrypt.hash(password, 10);

        db.run(
          'INSERT INTO users (email, password, full_name, phone, role) VALUES (?, ?, ?, ?, ?)',
          [email, hashedPassword, full_name, phone, role],
          function(err) {
            if (err) {
              return res.status(500).json({ success: false, message: 'Lỗi tạo tài khoản' });
            }

            db.get('SELECT id, email, full_name, phone, role FROM users WHERE id = ?',
              [this.lastID], (err, user) => {
                if (err) {
                  return res.status(500).json({ success: false, message: 'Lỗi server' });
                }

                const token = generateToken(user);
                res.status(201).json({
                  success: true,
                  message: 'Đăng ký thành công',
                  data: { user, token }
                });
              });
          }
        );
      } catch (error) {
        res.status(500).json({ success: false, message: 'Lỗi mã hóa mật khẩu' });
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
});

// Login user
router.post('/login', (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập email và mật khẩu'
      });
    }

    db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
      if (err) {
        return res.status(500).json({ success: false, message: 'Lỗi server' });
      }

      if (!user) {
        return res.status(400).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
      }

      try {
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
          return res.status(400).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
        }

        delete user.password;
        const token = generateToken(user);

        res.json({
          success: true,
          message: 'Đăng nhập thành công',
          data: { user, token }
        });
      } catch (error) {
        res.status(500).json({ success: false, message: 'Lỗi xác thực' });
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
});

module.exports = router;