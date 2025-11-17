const db = require('./database');

// Migration: Thêm columns mới vào bảng bookings
const migrateBookings = () => {
  console.log('🔄 Starting migration: Add new columns to bookings...');

  const migrations = [
    {
      name: 'Add car_type column',
      sql: `ALTER TABLE bookings ADD COLUMN car_type TEXT CHECK(car_type IN ('economy', 'standard', 'premium'))`,
    },
    {
      name: 'Add distance_km column',
      sql: `ALTER TABLE bookings ADD COLUMN distance_km DECIMAL(10,2)`,
    },
    {
      name: 'Add estimated_duration column',
      sql: `ALTER TABLE bookings ADD COLUMN estimated_duration VARCHAR(50)`,
    },
    {
      name: 'Add voucher_code column',
      sql: `ALTER TABLE bookings ADD COLUMN voucher_code VARCHAR(50)`,
    },
    {
      name: 'Add payment_method column',
      sql: `ALTER TABLE bookings ADD COLUMN payment_method TEXT CHECK(payment_method IN ('cash', 'card', 'ewallet')) DEFAULT 'cash'`,
    },
    {
      name: 'Add preferences column',
      sql: `ALTER TABLE bookings ADD COLUMN preferences TEXT`,
    },
  ];

  let completed = 0;

  migrations.forEach((migration, index) => {
    db.run(migration.sql, (err) => {
      if (err) {
        // Column might already exist
        if (err.message.includes('duplicate column name')) {
          console.log(`✅ ${migration.name} - Already exists`);
        } else {
          console.error(`❌ ${migration.name} - Error:`, err.message);
        }
      } else {
        console.log(`✅ ${migration.name} - Success`);
      }

      completed++;
      if (completed === migrations.length) {
        console.log('✅ Migration completed!');
        process.exit(0);
      }
    });
  });
};

migrateBookings();