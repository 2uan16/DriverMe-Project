const express = require('express');
const router = express.Router();

// Placeholder routes - sẽ implement sau
router.get('/dashboard', (req, res) => {
  res.json({ success: true, message: 'Admin routes working' });
});

module.exports = router;