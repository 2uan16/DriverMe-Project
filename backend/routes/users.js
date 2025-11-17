const express = require('express');
const router = express.Router();

// Placeholder routes - sẽ implement sau
router.get('/profile', (req, res) => {
  res.json({ success: true, message: 'User routes working' });
});

module.exports = router;