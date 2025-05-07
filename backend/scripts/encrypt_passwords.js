const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');

const saltRounds = 10;

async function encryptPasswords() {
  // Kết nối MySQL
  const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: 'hieu@1010',
    database: 'food_app',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  });

  try {
    // Lấy tất cả người dùng
    const [users] = await pool.query('SELECT id, password FROM users');

    console.log(`Found ${users.length} users to update.`);

    // Mã hóa mật khẩu cho từng người dùng
    for (const user of users) {
      // Kiểm tra xem mật khẩu đã được mã hóa chưa
      if (!user.password.startsWith('$2b$') && !user.password.startsWith('$2a$')) {
        const hashedPassword = await bcrypt.hash(user.password, saltRounds);

        // Cập nhật mật khẩu đã mã hóa
        await pool.query(
          'UPDATE users SET password = ? WHERE id = ?',
          [hashedPassword, user.id]
        );

        console.log(`Updated password for user ID: ${user.id}`);
      } else {
        console.log(`Password for user ID: ${user.id} is already encrypted.`);
      }
    }

    console.log('All passwords have been encrypted successfully.');
  } catch (error) {
    console.error('Error encrypting passwords:', error);
  } finally {
    // Đóng kết nối
    await pool.end();
  }
}

// Chạy hàm
encryptPasswords();