const express = require('express');
const db = require('../config/database');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

const router = express.Router();

// Get all bookings for a user
router.get('/', authenticateToken, (req, res) => {
  try {
    let query;
    let params;

    if (req.user.role === 'admin') {
      query = `
        SELECT b.*,
               u.full_name as user_name, u.phone as user_phone,
               d.full_name as driver_name, d.phone as driver_phone
        FROM bookings b
        LEFT JOIN users u ON b.user_id = u.id
        LEFT JOIN users d ON b.driver_id = d.id
        ORDER BY b.created_at DESC
      `;
      params = [];
    } else if (req.user.role === 'driver') {
      query = `
        SELECT b.*,
               u.full_name as user_name, u.phone as user_phone
        FROM bookings b
        LEFT JOIN users u ON b.user_id = u.id
        WHERE b.driver_id = ? OR (b.driver_id IS NULL AND b.status = 'pending')
        ORDER BY b.created_at DESC
      `;
      params = [req.user.id];
    } else {
      query = `
        SELECT b.*,
               d.full_name as driver_name, d.phone as driver_phone
        FROM bookings b
        LEFT JOIN users d ON b.driver_id = d.id
        WHERE b.user_id = ?
        ORDER BY b.created_at DESC
      `;
      params = [req.user.id];
    }

    db.all(query, params, (err, rows) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          message: 'Lỗi cơ sở dữ liệu'
        });
      }

      res.json({
        success: true,
        bookings: rows
      });
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

// ✅ CREATE BOOKING
router.post('/', authenticateToken, (req, res) => {
  try {
    const {
      pickup_address,
      pickup_lat,
      pickup_lng,
      destination_address,
      destination_lat,
      destination_lng,
      service_type = 'point_to_point',
      duration_hours,
      estimated_price,
      payment_method = 'cash',        // ✅ MỚI
      notes,
      car_type,                       // ✅ MỚI
      distance_km,                    // ✅ MỚI
      estimated_duration,             // ✅ MỚI
      voucher_code,                   // ✅ MỚI
      preferences                     // ✅ MỚI
    } = req.body;

    console.log('  Received booking data:', req.body);

    // ✅ VALIDATION
    if (!pickup_address || !pickup_lat || !pickup_lng) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin điểm đón'
      });
    }

    if (service_type === 'point_to_point' &&
        (!destination_address || !destination_lat || !destination_lng)) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin điểm đến'
      });
    }

    if (service_type === 'hourly' && (!duration_hours || duration_hours < 1)) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn thời gian thuê hợp lệ'
      });
    }

    // ✅ Parse coordinates
    const pickup_latitude = parseFloat(pickup_lat);
    const pickup_longitude = parseFloat(pickup_lng);
    const destination_latitude = destination_lat ? parseFloat(destination_lat) : null;
    const destination_longitude = destination_lng ? parseFloat(destination_lng) : null;

    // ✅ Convert preferences object to JSON string
    const preferencesJSON = preferences ? JSON.stringify(preferences) : null;

    // ✅ INSERT QUERY - ĐẦY ĐỦ FIELDS
    const insertQuery = `
      INSERT INTO bookings (
        user_id,
        pickup_address,
        pickup_latitude,
        pickup_longitude,
        destination_address,
        destination_latitude,
        destination_longitude,
        service_type,
        duration_hours,
        car_type,
        distance_km,
        estimated_duration,
        voucher_code,
        payment_method,
        preferences,
        estimated_price,
        notes,
        status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `;

    const params = [
      req.user.id,
      pickup_address,
      pickup_latitude,
      pickup_longitude,
      destination_address || null,
      destination_latitude,
      destination_longitude,
      service_type,
      service_type === 'hourly' ? duration_hours : null,
      car_type || null,                    // ✅ MỚI
      distance_km || null,                 // ✅ MỚI
      estimated_duration || null,          // ✅ MỚI
      voucher_code || null,                // ✅ MỚI
      payment_method || 'cash',            // ✅ MỚI
      preferencesJSON,                     // ✅ MỚI
      estimated_price || 0,
      notes || ''
    ];

    console.log('💾 Inserting booking with params:', params);

    db.run(insertQuery, params, function(err) {
      if (err) {
        console.error('❌ Database error:', err);
        return res.status(500).json({
          success: false,
          message: 'Không thể tạo chuyến đi',
          error: err.message
        });
      }

      const bookingId = this.lastID;
      console.log('✅ Booking created with ID:', bookingId);

      // Get the created booking
      db.get(
        'SELECT * FROM bookings WHERE id = ?',
        [bookingId],
        (err, booking) => {
          if (err) {
            console.error('❌ Error fetching booking:', err);
            return res.status(500).json({
              success: false,
              message: 'Lỗi server'
            });
          }

          console.log('📤 Sending response:', booking);

          // Emit to nearby drivers via Socket.IO
          if (req.app.io) {
            req.app.io.emit('new_booking', booking);
            console.log('🔔 Emitted new_booking event');
          }

          res.status(201).json({
            success: true,
            message: 'Đặt chuyến thành công!',
            data: {
              id: bookingId,
              ...booking
            }
          });
        }
      );
    });

  } catch (error) {
    console.error('❌ Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server',
      error: error.message
    });
  }
});
// ✅ GET PRICING CALCULATION
router.post('/calculate-price', authenticateToken, (req, res) => {
  try {
    const {
      car_type,
      distance_km,
      duration_minutes,
      voucher_code,
    } = req.body;

    // Validate
    if (!car_type || !distance_km || !duration_minutes) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin tính giá'
      });
    }

    // Get pricing config from database
    db.all(
      'SELECT setting_key, setting_value FROM app_settings WHERE setting_key IN (?, ?, ?)',
      ['base_price_per_km', 'base_price_per_hour', 'driver_commission'],
      (err, settings) => {
        if (err) {
          return res.status(500).json({
            success: false,
            message: 'Lỗi lấy cấu hình giá'
          });
        }

        // Parse settings
        const config = {};
        settings.forEach(s => {
          config[s.setting_key] = parseFloat(s.setting_value);
        });

        // Calculate price based on car_type
        let baseFare, pricePerKm, pricePerMinute;

        switch (car_type) {
          case 'economy':
            baseFare = 10000;
            pricePerKm = 5000;
            pricePerMinute = 500;
            break;
          case 'standard':
            baseFare = 15000;
            pricePerKm = 7000;
            pricePerMinute = 700;
            break;
          case 'premium':
            baseFare = 25000;
            pricePerKm = 10000;
            pricePerMinute = 1000;
            break;
          default:
            baseFare = 10000;
            pricePerKm = 5000;
            pricePerMinute = 500;
        }

        const distanceFare = Math.round(distance_km * pricePerKm);
        const timeFare = Math.round(duration_minutes * pricePerMinute);
        const subtotal = baseFare + distanceFare + timeFare;

        // Check peak hour (simplified)
        const now = new Date();
        const hour = now.getHours();
        let surchargeRate = 0;

        if ((hour >= 6 && hour < 9) || (hour >= 16 && hour < 19)) {
          surchargeRate = 0.20; // 20% peak hour
        } else if (hour >= 22 || hour < 5) {
          surchargeRate = 0.15; // 15% late night
        }

        const surchargeAmount = Math.round(subtotal * surchargeRate);
        const priceAfterSurcharge = subtotal + surchargeAmount;

        // Apply voucher (if any)
        let discount = 0;
        // TODO: Check voucher in database

        const priceAfterDiscount = priceAfterSurcharge - discount;

        // VAT
        const vatAmount = Math.round(priceAfterDiscount * 0.08);
        const finalPrice = priceAfterDiscount + vatAmount;

        res.json({
          success: true,
          data: {
            baseFare,
            distanceFare,
            timeFare,
            subtotal,
            surchargeRate,
            surchargeAmount,
            discount,
            vatAmount,
            finalPrice,
            breakdown: {
              'Giá mở cửa': baseFare,
              'Phí quãng đường': distanceFare,
              'Phí thời gian': timeFare,
              ...(surchargeAmount > 0 && { 'Phụ phí giờ cao điểm': surchargeAmount }),
              ...(discount > 0 && { 'Giảm giá': -discount }),
              'VAT (8%)': vatAmount,
              'Tổng cộng': finalPrice,
            }
          }
        });
      }
    );

  } catch (error) {
    console.error('Calculate price error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

// Accept booking (for drivers)
router.patch('/:id/accept', authenticateToken, authorizeRoles('driver'), (req, res) => {
  try {
    const bookingId = req.params.id;

    db.get(
      'SELECT * FROM bookings WHERE id = ? AND status = "pending" AND driver_id IS NULL',
      [bookingId],
      (err, booking) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({
            success: false,
            message: 'Lỗi cơ sở dữ liệu'
          });
        }

        if (!booking) {
          return res.status(404).json({
            success: false,
            message: 'Không tìm thấy chuyến đi hoặc chuyến đã được nhận'
          });
        }

        db.run(
          'UPDATE bookings SET driver_id = ?, status = "accepted", pickup_time = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [req.user.id, bookingId],
          function(err) {
            if (err) {
              console.error('Database error:', err);
              return res.status(500).json({
                success: false,
                message: 'Không thể nhận chuyến'
              });
            }

            if (req.app.io) {
              req.app.io.emit('booking_status_changed', {
                bookingId: bookingId,
                status: 'accepted',
                userId: booking.user_id,
                driverId: req.user.id
              });
            }

            res.json({
              success: true,
              message: 'Đã nhận chuyến thành công'
            });
          }
        );
      }
    );

  } catch (error) {
    console.error('Accept booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

// Update booking status
router.patch('/:id/status', authenticateToken, (req, res) => {
  try {
    const bookingId = req.params.id;
    const { status } = req.body;

    const validStatuses = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Trạng thái không hợp lệ'
      });
    }

    db.get(
      'SELECT * FROM bookings WHERE id = ?',
      [bookingId],
      (err, booking) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({
            success: false,
            message: 'Lỗi cơ sở dữ liệu'
          });
        }

        if (!booking) {
          return res.status(404).json({
            success: false,
            message: 'Không tìm thấy chuyến đi'
          });
        }

        const canUpdate = (
          req.user.role === 'admin' ||
          (req.user.role === 'driver' && booking.driver_id === req.user.id) ||
          (req.user.role === 'user' && booking.user_id === req.user.id && status === 'cancelled')
        );

        if (!canUpdate) {
          return res.status(403).json({
            success: false,
            message: 'Không có quyền cập nhật chuyến đi này'
          });
        }

        let updateQuery = 'UPDATE bookings SET status = ?, updated_at = CURRENT_TIMESTAMP';
        let params = [status];

        if (status === 'accepted') {
          updateQuery += ', pickup_time = CURRENT_TIMESTAMP';
        } else if (status === 'in_progress') {
          updateQuery += ', start_time = CURRENT_TIMESTAMP';
        } else if (status === 'completed') {
          updateQuery += ', end_time = CURRENT_TIMESTAMP';
        }

        updateQuery += ' WHERE id = ?';
        params.push(bookingId);

        db.run(updateQuery, params, function(err) {
          if (err) {
            console.error('Database error:', err);
            return res.status(500).json({
              success: false,
              message: 'Không thể cập nhật trạng thái'
            });
          }

          if (req.app.io) {
            req.app.io.emit('booking_status_changed', {
              bookingId: bookingId,
              status: status,
              userId: booking.user_id,
              driverId: booking.driver_id
            });
          }

          res.json({
            success: true,
            message: 'Cập nhật trạng thái thành công'
          });
        });
      }
    );

  } catch (error) {
    console.error('Update status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

// Get specific booking
router.get('/:id', authenticateToken, (req, res) => {
  try {
    const bookingId = req.params.id;

    let query = `
      SELECT b.*,
             u.full_name as user_name, u.phone as user_phone,
             d.full_name as driver_name, d.phone as driver_phone
      FROM bookings b
      LEFT JOIN users u ON b.user_id = u.id
      LEFT JOIN users d ON b.driver_id = d.id
      WHERE b.id = ?
    `;

    let params = [bookingId];
    if (req.user.role !== 'admin') {
      query += ' AND (b.user_id = ? OR b.driver_id = ?)';
      params.push(req.user.id, req.user.id);
    }

    db.get(query, params, (err, booking) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          message: 'Lỗi cơ sở dữ liệu'
        });
      }

      if (!booking) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy chuyến đi'
        });
      }

      res.json({
        success: true,
        booking: booking
      });
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

// Cancel booking
router.delete('/:id', authenticateToken, (req, res) => {
  try {
    const bookingId = req.params.id;

    db.get(
      'SELECT * FROM bookings WHERE id = ?',
      [bookingId],
      (err, booking) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({
            success: false,
            message: 'Lỗi cơ sở dữ liệu'
          });
        }

        if (!booking) {
          return res.status(404).json({
            success: false,
            message: 'Không tìm thấy chuyến đi'
          });
        }

        const canCancel = (
          req.user.role === 'admin' ||
          booking.user_id === req.user.id ||
          booking.driver_id === req.user.id
        );

        if (!canCancel) {
          return res.status(403).json({
            success: false,
            message: 'Không có quyền hủy chuyến này'
          });
        }

        if (['completed', 'cancelled'].includes(booking.status)) {
          return res.status(400).json({
            success: false,
            message: 'Không thể hủy chuyến đã hoàn thành hoặc đã hủy'
          });
        }

        db.run(
          'UPDATE bookings SET status = "cancelled", updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [bookingId],
          function(err) {
            if (err) {
              console.error('Database error:', err);
              return res.status(500).json({
                success: false,
                message: 'Không thể hủy chuyến'
              });
            }

            if (req.app.io) {
              req.app.io.emit('booking_status_changed', {
                bookingId: bookingId,
                status: 'cancelled',
                userId: booking.user_id,
                driverId: booking.driver_id
              });
            }

            res.json({
              success: true,
              message: 'Đã hủy chuyến thành công'
            });
          }
        );
      }
    );

  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
});

module.exports = router;