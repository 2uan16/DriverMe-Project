const db = require('./database');
const bcrypt = require('bcryptjs');

// Create tables
const createTables = () => {
  // Users table
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email VARCHAR(100) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      full_name VARCHAR(100) NOT NULL,
      phone VARCHAR(20) NOT NULL,
      avatar_url VARCHAR(255),
      role TEXT CHECK(role IN ('user', 'driver', 'admin')) DEFAULT 'user',
      is_active BOOLEAN DEFAULT 1,
      is_verified BOOLEAN DEFAULT 0,
      rating DECIMAL(2,1) DEFAULT 5.0,
      total_trips INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Driver profiles table
  db.run(`
    CREATE TABLE IF NOT EXISTS driver_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER REFERENCES users(id),
      license_number VARCHAR(20) UNIQUE NOT NULL,
      license_image VARCHAR(255),
      vehicle_type VARCHAR(50),
      vehicle_brand VARCHAR(50),
      vehicle_model VARCHAR(50),
      vehicle_year INTEGER,
      license_plate VARCHAR(20),
      is_available BOOLEAN DEFAULT 0,
      current_latitude DECIMAL(10,8),
      current_longitude DECIMAL(11,8),
      documents_verified BOOLEAN DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // ✅ BOOKINGS TABLE - ĐẦY ĐỦ COLUMNS
  db.run(`
    CREATE TABLE IF NOT EXISTS bookings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER REFERENCES users(id),
      driver_id INTEGER REFERENCES users(id),
      pickup_address TEXT NOT NULL,
      pickup_latitude DECIMAL(10,8) NOT NULL,
      pickup_longitude DECIMAL(11,8) NOT NULL,
      destination_address TEXT,
      destination_latitude DECIMAL(10,8),
      destination_longitude DECIMAL(11,8),
      service_type TEXT CHECK(service_type IN ('hourly', 'point_to_point')) DEFAULT 'point_to_point',
      duration_hours INTEGER,
      car_type TEXT CHECK(car_type IN ('economy', 'standard', 'premium')),
      distance_km DECIMAL(10,2),
      estimated_duration VARCHAR(50),
      voucher_code VARCHAR(50),
      payment_method TEXT CHECK(payment_method IN ('cash', 'card', 'ewallet')) DEFAULT 'cash',
      preferences TEXT,
      estimated_price DECIMAL(10,2),
      final_price DECIMAL(10,2),
      status TEXT CHECK(status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
      booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      pickup_time TIMESTAMP,
      start_time TIMESTAMP,
      end_time TIMESTAMP,
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Reviews table
  db.run(`
    CREATE TABLE IF NOT EXISTS reviews (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      booking_id INTEGER REFERENCES bookings(id),
      reviewer_id INTEGER REFERENCES users(id),
      reviewee_id INTEGER REFERENCES users(id),
      rating INTEGER CHECK(rating >= 1 AND rating <= 5),
      comment TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Payments table
  db.run(`
    CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      booking_id INTEGER REFERENCES bookings(id),
      amount DECIMAL(10,2) NOT NULL,
      payment_method TEXT CHECK(payment_method IN ('cash', 'card', 'ewallet')) DEFAULT 'cash',
      payment_status TEXT CHECK(payment_status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
      transaction_id VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Notifications table
  db.run(`
    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER REFERENCES users(id),
      title VARCHAR(255) NOT NULL,
      message TEXT NOT NULL,
      type VARCHAR(50),
      is_read BOOLEAN DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // App settings table
  db.run(`
    CREATE TABLE IF NOT EXISTS app_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      setting_key VARCHAR(100) UNIQUE NOT NULL,
      setting_value TEXT NOT NULL,
      description TEXT,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  console.log('📊 Database tables created successfully');
};

// Insert default data
const insertDefaultData = async () => {
  try {
    // Check if admin exists
    db.get('SELECT id FROM users WHERE email = ?', ['admin@driverme.com'], async (err, row) => {
      if (err) {
        console.error('Error checking admin:', err);
        return;
      }

      if (!row) {
        // Create default admin
        const hashedPassword = await bcrypt.hash('admin123', 10);
        db.run(
          'INSERT INTO users (email, password, full_name, phone, role, is_verified) VALUES (?, ?, ?, ?, ?, ?)',
          ['admin@driverme.com', hashedPassword, 'Administrator', '0123456789', 'admin', 1],
          (err) => {
            if (err) {
              console.error('Error creating admin:', err);
            } else {
              console.log('✅ Default admin created: admin@driverme.com / admin123');
            }
          }
        );
      }
    });

    // Insert default settings
    const defaultSettings = [
      ['base_price_per_km', '15000', 'Giá cơ bản mỗi km (VND)'],
      ['base_price_per_hour', '100000', 'Giá cơ bản mỗi giờ (VND)'],
      ['booking_fee', '10000', 'Phí đặt chuyến (VND)'],
      ['driver_commission', '0.2', 'Hoa hồng cho tài xế (20%)'],
      ['max_booking_distance', '50', 'Khoảng cách tối đa để đặt chuyến (km)']
    ];

    defaultSettings.forEach(([key, value, description]) => {
      db.run(
        'INSERT OR IGNORE INTO app_settings (setting_key, setting_value, description) VALUES (?, ?, ?)',
        [key, value, description]
      );
    });

    console.log('✅ Default settings inserted');

  } catch (error) {
    console.error('Error inserting default data:', error);
  }
};

// Create indexes
const createIndexes = () => {
  const indexes = [
    'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
    'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
    'CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_bookings_driver_id ON bookings(driver_id)',
    'CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status)',
    'CREATE INDEX IF NOT EXISTS idx_driver_profiles_user_id ON driver_profiles(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_driver_profiles_available ON driver_profiles(is_available)',
    'CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON reviews(booking_id)',
    'CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id)',
    'CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id)'
  ];

  indexes.forEach(indexSQL => {
    db.run(indexSQL, (err) => {
      if (err) {
        console.error('Error creating index:', err);
      }
    });
  });

  console.log('✅ Database indexes created');
};

// Initialize everything
createTables();
setTimeout(() => {
  insertDefaultData();
  createIndexes();
}, 1000);