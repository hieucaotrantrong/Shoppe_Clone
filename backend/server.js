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

// Thêm log chi tiết hơn
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

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

// Khai báo biến server ở phạm vi toàn cục
let server;

// Khởi động server sau khi kiểm tra kết nối
async function startServer() {
  const dbConnected = await testDatabaseConnection();

  if (dbConnected) {
    server = app.listen(port, '0.0.0.0', () => {
      console.log(`Server running on port ${port}`);
      console.log(`Server is accessible at:`);
      console.log(`- Local: http://localhost:${port}`);
      console.log(`- For emulators: http://10.0.2.2:${port}`);
      console.log(`- Network: http://<your-local-ip>:${port}`);
    });
  } else {
    console.log('Server not started due to database connection issues');
  }
}

startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  if (server) {
    server.close(async () => {
      console.log('HTTP server closed');
      await pool.end();
      console.log('Database connections closed');
    });
  }
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  if (server) {
    server.close(async () => {
      console.log('HTTP server closed');
      await pool.end();
      console.log('Database connections closed');
    });
  } else {
    process.exit(0); // Thoát ngay nếu server chưa được khởi tạo
  }
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

// Đăng nhập
app.post('/api/users/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ status: 'error', message: 'Email and password are required' });
    }

    // Tìm người dùng theo email
    const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);

    if (users.length === 0) {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }

    const user = users[0];

    // So sánh mật khẩu
    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }

    // Trả về thông tin người dùng (không bao gồm mật khẩu)
    const userData = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role || 'user', // Mặc định là 'user' nếu không có role
    };

    res.json({ status: 'success', message: 'Login successful', data: userData });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Đăng ký
app.post('/api/users/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ status: 'error', message: 'All fields are required' });
    }

    // Kiểm tra email đã tồn tại chưa
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);

    if (existingUsers.length > 0) {
      return res.status(409).json({ status: 'error', message: 'Email already exists' });
    }

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Thêm người dùng mới vào cơ sở dữ liệu (mặc định role là 'user')
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, 'user']
    );

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        id: result.insertId,
        name,
        email,
        role: 'user'
      }
    });
  } catch (error) {
    console.error('Error during registration:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
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
          'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [orderId, item.product_id, item.quantity, item.price]
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

// API endpoints cho đơn hàng

// Lấy tất cả đơn hàng (cho admin)
app.get('/api/orders', async (req, res) => {
  try {
    console.log('Fetching all orders...');
    
    // Kiểm tra cấu trúc bảng orders
    const [orderColumns] = await pool.query('SHOW COLUMNS FROM orders');
    console.log('Orders table columns:', orderColumns.map(col => col.Field));
    
    // Xác định tên cột thời gian
    let timeColumn = 'order_date';
    if (orderColumns.some(col => col.Field === 'created_at')) {
      timeColumn = 'created_at';
    }
    
    console.log(`Using time column: ${timeColumn}`);
    
    // Truy vấn với tên cột thời gian đúng
    const query = `
      SELECT o.*, u.name as user_name
      FROM orders o
      JOIN users u ON o.user_id = u.id
      ORDER BY o.${timeColumn} DESC
    `;
    
    console.log('Executing query:', query);
    const [rows] = await pool.query(query);
    console.log(`Found ${rows.length} orders`);
    
    // Lấy chi tiết đơn hàng cho mỗi đơn hàng
    for (let i = 0; i < rows.length; i++) {
      const order = rows[i];
      console.log(`Fetching items for order #${order.id}`);
      
      const [orderItems] = await pool.query(`
        SELECT oi.*
        FROM order_items oi
        WHERE oi.order_id = ?
      `, [order.id]);
      
      console.log(`Found ${orderItems.length} items for order #${order.id}`);
      
      // Đảm bảo mỗi item có tên
      for (let j = 0; j < orderItems.length; j++) {
        if (!orderItems[j].name) {
          orderItems[j].name = 'Sản phẩm không xác định';
        }
      }
      
      rows[i].items = orderItems;
    }
    
    res.json({ status: 'success', data: rows });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Cập nhật trạng thái đơn hàng
app.put('/api/orders/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const orderId = req.params.id;
    
    console.log(`Updating order #${orderId} status to: ${status}`);

    if (!status) {
      return res.status(400).json({ status: 'error', message: 'Status is required' });
    }

    // Kiểm tra trạng thái hợp lệ
    const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ status: 'error', message: 'Invalid status' });
    }

    const [result] = await pool.query(
      'UPDATE orders SET status = ? WHERE id = ?',
      [status, orderId]
    );
    
    console.log('Update result:', result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'Order not found' });
    }

    res.json({
      status: 'success',
      message: 'Order status updated successfully',
      data: { id: orderId, status }
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Tạo đơn hàng mới
app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items } = req.body;
    
    console.log('Received order request:', { user_id, total_amount, items });
    
    if (!user_id || !total_amount || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ status: 'error', message: 'Invalid order data' });
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Tạo đơn hàng
      const [orderResult] = await connection.query(
        'INSERT INTO orders (user_id, total_amount, status) VALUES (?, ?, ?)',
        [user_id, total_amount, 'pending']
      );
      
      const orderId = orderResult.insertId;
      
      // Kiểm tra xem product_id có tồn tại trong bảng food_items không
      for (const item of items) {
        const productId = item.product_id;
        
        // Kiểm tra trong bảng food_items thay vì products
        const [productCheck] = await connection.query(
          'SELECT id FROM food_items WHERE id = ?',
          [productId]
        );
        
        if (productCheck.length === 0) {
          throw new Error(`Product with ID ${productId} does not exist in food_items table`);
        }
        
        await connection.query(
          'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [orderId, productId, item.quantity, item.price]
        );
      }
      
      // Commit transaction
      await connection.commit();
      connection.release();
      
      res.status(201).json({ 
        status: 'success', 
        message: 'Order created successfully',
        data: { order_id: orderId }
      });
    } catch (error) {
      // Rollback nếu có lỗi
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API endpoints cho sản phẩm (products)

// Lấy tất cả sản phẩm với tùy chọn lọc theo danh mục và tìm kiếm
app.get('/api/products', async (req, res) => {
  try {
    const { category, search } = req.query;
    
    console.log(`Fetching products with category: ${category}, search: ${search}`);
    
    let query = 'SELECT * FROM products WHERE 1=1';
    const params = [];
    
    // Lọc theo danh mục nếu được cung cấp
    if (category && category !== 'All') {
      query += ' AND category = ?';
      params.push(category);
    }
    
    // Tìm kiếm theo tên sản phẩm nếu được cung cấp
    if (search && search.trim() !== '') {
      query += ' AND name LIKE ?';
      params.push(`%${search.trim()}%`);
      console.log(`Searching for products with name like: %${search.trim()}%`);
    }
    
    query += ' ORDER BY id DESC';
    
    console.log('Executing query:', query, 'with params:', params);
    
    const [rows] = await pool.query(query, params);
    
    console.log(`Found ${rows.length} products`);
    
    res.json({ status: 'success', data: rows });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Lấy sản phẩm theo ID
app.get('/api/products/:id', async (req, res) => {
  try {
    const productId = req.params.id;

    const [rows] = await pool.query(
      'SELECT * FROM products WHERE id = ?',
      [productId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ status: 'error', message: 'Product not found' });
    }

    res.json({ status: 'success', data: rows[0] });
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Tạo sản phẩm mới
app.post('/api/products', async (req, res) => {
  try {
    const { name, price, description, image_path, category } = req.body;

    if (!name || !price) {
      return res.status(400).json({ status: 'error', message: 'Name and price are required' });
    }

    const [result] = await pool.query(
      'INSERT INTO products (name, price, description, image_path, category) VALUES (?, ?, ?, ?, ?)',
      [name, price, description || '', image_path || '', category || 'Other']
    );

    res.status(201).json({
      status: 'success',
      message: 'Product created successfully',
      data: {
        id: result.insertId,
        name,
        price,
        description,
        image_path,
        category
      }
    });
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Cập nhật sản phẩm
app.put('/api/products/:id', async (req, res) => {
  try {
    const productId = req.params.id;
    const { name, price, description, image_path, category } = req.body;

    if (!name || !price) {
      return res.status(400).json({ status: 'error', message: 'Name and price are required' });
    }

    const [result] = await pool.query(
      'UPDATE products SET name = ?, price = ?, description = ?, image_path = ?, category = ? WHERE id = ?',
      [name, price, description || '', image_path || '', category || 'Other', productId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'Product not found' });
    }

    res.json({
      status: 'success',
      message: 'Product updated successfully',
      data: {
        id: productId,
        name,
        price,
        description,
        image_path,
        category
      }
    });
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Xóa sản phẩm
app.delete('/api/products/:id', async (req, res) => {
  try {
    const productId = req.params.id;

    const [result] = await pool.query(
      'DELETE FROM products WHERE id = ?',
      [productId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'Product not found' });
    }

    res.json({
      status: 'success',
      message: 'Product deleted successfully',
      data: { id: productId }
    });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// Lấy tất cả người dùng (cho admin)
app.get('/api/users', async (req, res) => {
  try {
    console.log('Fetching all users...');
    
    const [rows] = await pool.query(
      'SELECT id, name, email, role, created_at FROM users ORDER BY created_at DESC'
    );
    
    console.log(`Found ${rows.length} users`);
    
    res.json({ status: 'success', data: rows });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Tạo người dùng mới (cho admin)
app.post('/api/users', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ status: 'error', message: 'All fields are required' });
    }

    // Kiểm tra email đã tồn tại chưa
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);

    if (existingUsers.length > 0) {
      return res.status(409).json({ status: 'error', message: 'Email already exists' });
    }

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Thêm người dùng mới vào cơ sở dữ liệu
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, role]
    );

    res.status(201).json({
      status: 'success',
      message: 'User created successfully',
      data: {
        id: result.insertId,
        name,
        email,
        role
      }
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Cập nhật người dùng (cho admin)
app.put('/api/users/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const { name, email, password, role } = req.body;

    if (!name || !email || !role) {
      return res.status(400).json({ status: 'error', message: 'Name, email and role are required' });
    }

    // Kiểm tra người dùng tồn tại
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    // Kiểm tra email đã tồn tại chưa (nếu thay đổi email)
    if (email !== existingUsers[0].email) {
      const [emailCheck] = await pool.query('SELECT * FROM users WHERE email = ? AND id != ?', [email, userId]);

      if (emailCheck.length > 0) {
        return res.status(409).json({ status: 'error', message: 'Email already exists' });
      }
    }

    let query = 'UPDATE users SET name = ?, email = ?, role = ? WHERE id = ?';
    let params = [name, email, role, userId];

    // Nếu có mật khẩu mới, mã hóa và cập nhật
    if (password) {
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      query = 'UPDATE users SET name = ?, email = ?, password = ?, role = ? WHERE id = ?';
      params = [name, email, hashedPassword, role, userId];
    }

    const [result] = await pool.query(query, params);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    res.json({
      status: 'success',
      message: 'User updated successfully',
      data: {
        id: userId,
        name,
        email,
        role
      }
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Xóa người dùng (cho admin)
app.delete('/api/users/:id', async (req, res) => {
  try {
    const userId = req.params.id;

    // Kiểm tra người dùng tồn tại
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    // Kiểm tra xem có phải admin cuối cùng không
    if (existingUsers[0].role === 'admin') {
      const [adminCount] = await pool.query('SELECT COUNT(*) as count FROM users WHERE role = "admin"');
      
      if (adminCount[0].count <= 1) {
        return res.status(400).json({ 
          status: 'error', 
          message: 'Cannot delete the last admin user' 
        });
      }
    }

    // Xóa người dùng
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    res.json({
      status: 'success',
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

















