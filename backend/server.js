const express = require('express');
const mysql = require('mysql2/promise');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt'); // Thêm bcrypt

const app = express();
const port = process.env.PORT || 3001;
const saltRounds = 10; // Số vòng băm cho bcrypt

// Middleware
app.use(cors({
  origin: '*', // Cho phép tất cả các nguồn trong quá trình phát triển
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(bodyParser.json());

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

// API routes...

// Kiểm tra kết nối cơ sở dữ liệu khi khởi động
async function testDatabaseConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('Database connection successful');
    connection.release();
    return true;
  } catch (error) {
    console.error('Database connection failed:', error);
    return false;
  }
}

// Khởi động server sau khi kiểm tra kết nối
async function startServer() {
  const dbConnected = await testDatabaseConnection();

  if (dbConnected) {
    const server = app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });

    // Graceful shutdown handlers...
  } else {
    console.log('Server not started due to database connection issues');
  }
}

startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(async () => {
    console.log('HTTP server closed');
    await pool.end();
    console.log('Database connections closed');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  server.close(async () => {
    console.log('HTTP server closed');
    await pool.end();
    console.log('Database connections closed');
  });
});

// Thêm xử lý lỗi tổng quát
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  // Không tắt server ngay lập tức khi có lỗi
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Không tắt server ngay lập tức khi có lỗi
});

// Thêm xử lý lỗi khi khởi động server
const server = app.listen(port, () => {
  console.log(`Server running on port ${port}`);
}).on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${port} is already in use. Try using a different port.`);
  } else {
    console.error('Error starting server:', error);
  }
});

// Thêm API endpoint để lấy thông tin người dùng
app.get('/api/users/:id', async (req, res) => {
  try {
    const userId = req.params.id;

    const [users] = await pool.query(
      'SELECT id, name, email, role FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.json({
      status: 'success',
      data: users[0]
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API đăng nhập
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Email and password are required'
      });
    }

    // Lấy thông tin người dùng từ email
    const [users] = await pool.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    const user = users[0];

    // So sánh mật khẩu đã nhập với mật khẩu đã mã hóa
    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    // Không trả về mật khẩu
    delete user.password;

    res.json({
      status: 'success',
      message: 'Login successful',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API đăng ký
app.post('/api/register', async (req, res) => {
  try {
    const { name, email, password, role = 'user' } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Name, email and password are required'
      });
    }

    // Kiểm tra email đã tồn tại chưa
    const [existingUsers] = await pool.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        status: 'error',
        message: 'Email already exists'
      });
    }

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Chỉ cho phép role 'user' hoặc 'admin'
    const validRole = role === 'admin' ? 'admin' : 'user';

    // Thêm người dùng mới với mật khẩu đã mã hóa
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, validRole]
    );

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        id: result.insertId,
        name,
        email,
        role: validRole
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API tạo đơn hàng mới
app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items } = req.body;

    if (!user_id || !total_amount || !items || !Array.isArray(items)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid order data'
      });
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Tạo đơn hàng
      const [orderResult] = await connection.query(
        'INSERT INTO orders (user_id, total_amount) VALUES (?, ?)',
        [user_id, total_amount]
      );

      const orderId = orderResult.insertId;

      // Thêm các món ăn vào đơn hàng
      for (const item of items) {
        await connection.query(
          'INSERT INTO order_items (order_id, food_id, quantity, price) VALUES (?, ?, ?, ?)',
          [orderId, item.food_id, item.quantity, item.price]
        );
      }

      // Commit transaction
      await connection.commit();
      connection.release();

      res.status(201).json({
        status: 'success',
        message: 'Order created successfully',
        data: {
          order_id: orderId,
          user_id,
          total_amount,
          items
        }
      });
    } catch (error) {
      // Rollback nếu có lỗi
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API thay đổi mật khẩu
app.put('/api/users/:id/password', async (req, res) => {
  try {
    const userId = req.params.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        status: 'error',
        message: 'Current password and new password are required'
      });
    }

    // Lấy thông tin người dùng
    const [users] = await pool.query(
      'SELECT * FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const user = users[0];

    // Kiểm tra mật khẩu hiện tại
    const passwordMatch = await bcrypt.compare(currentPassword, user.password);

    if (!passwordMatch) {
      return res.status(401).json({
        status: 'error',
        message: 'Current password is incorrect'
      });
    }

    // Mã hóa mật khẩu mới
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Cập nhật mật khẩu
    await pool.query(
      'UPDATE users SET password = ? WHERE id = ?',
      [hashedPassword, userId]
    );

    res.json({
      status: 'success',
      message: 'Password updated successfully'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});





