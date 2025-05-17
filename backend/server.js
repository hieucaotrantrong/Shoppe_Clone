const express = require('express');
const mysql = require('mysql2/promise');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt'); // Thêm bcrypt
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3001;
const saltRounds = 10; // Số vòng băm cho bcrypt

// Middleware
app.use(cors()); // Thêm middleware CORS
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

let isShuttingDown = false;

process.on('SIGTERM', async () => {
  if (isShuttingDown) return;
  isShuttingDown = true;

  console.log('SIGTERM signal received: closing HTTP server');
  if (server) {
    server.close(async () => {
      console.log('HTTP server closed');
      try {
        await pool.end();
        console.log('Database connections closed');
      } catch (err) {
        console.error('Error closing database connections:', err);
      }
      process.exit(0);
    });

    setTimeout(() => {
      console.log('Forcing exit after timeout');
      process.exit(1);
    }, 5000);
  } else {
    process.exit(0);
  }
});

process.on('SIGINT', async () => {
  if (isShuttingDown) return;
  isShuttingDown = true;

  console.log('SIGINT signal received: closing HTTP server');
  if (server) {
    server.close(async () => {
      console.log('HTTP server closed');
      try {
        await pool.end();
        console.log('Database connections closed');
      } catch (err) {
        console.error('Error closing database connections:', err);
      }
      process.exit(0);
    });

    // Đảm bảo thoát sau 5 giây nếu server không đóng đúng cách
    setTimeout(() => {
      console.log('Forcing exit after timeout');
      process.exit(1);
    }, 5000);
  } else {
    process.exit(0);
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

    console.log('Received order request:', JSON.stringify({ user_id, total_amount, items }, null, 2));

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

      // Thêm các sản phẩm vào đơn hàng
      for (const item of items) {
        // Đảm bảo product_id là số nguyên
        const productId = parseInt(item.product_id || item.id);

        if (isNaN(productId)) {
          throw new Error(`Invalid product ID: ${item.product_id || item.id}`);
        }

        const quantity = parseInt(item.quantity) || 1;
        const price = parseFloat(item.price) || 0;

        // Lấy tên sản phẩm từ request
        const productName = item.name;

        console.log(`Adding item to order #${orderId}:`, {
          product_id: productId,
          name: productName,
          quantity: quantity,
          price: price
        });

        // Kiểm tra xem tên sản phẩm có null không
        if (!productName) {
          console.warn(`Warning: Product name is null for product_id ${productId}`);

          // Nếu tên sản phẩm null, thử lấy từ bảng products
          const [products] = await connection.query(
            'SELECT name FROM products WHERE id = ?',
            [productId]
          );

          if (products.length > 0 && products[0].name) {
            console.log(`Found product name from database: ${products[0].name}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, products[0].name, quantity, price]
            );
          } else {
            // Nếu không tìm thấy, sử dụng ID sản phẩm
            const fallbackName = `Sản phẩm #${productId}`;
            console.log(`Using fallback name: ${fallbackName}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, fallbackName, quantity, price]
            );
          }
        } else {
          // Nếu có tên sản phẩm, sử dụng nó
          await connection.query(
            'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
            [orderId, productId, productName, quantity, price]
          );
        }
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
      console.error('Transaction error:', error);
      throw error;
    }
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ status: 'error', message: error.message });
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
    const { user_id, status } = req.query;

    let query = `
      SELECT o.*, u.name as user_name 
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE 1=1
    `;

    const params = [];

    if (user_id) {
      query += ' AND o.user_id = ?';
      params.push(user_id);
    }

    if (status) {
      query += ' AND o.status = ?';
      params.push(status);
    }

    // Sắp xếp theo id giảm dần (đơn hàng mới nhất trước)
    query += ' ORDER BY o.id DESC';

    console.log('Orders query:', query);

    const [orders] = await pool.query(query, params);
    console.log(`Found ${orders.length} orders`);

    // Lấy chi tiết đơn hàng cho mỗi đơn hàng
    const ordersWithItems = await Promise.all(orders.map(async (order) => {
      // Lấy thông tin chi tiết đơn hàng kèm tên sản phẩm
      const [items] = await pool.query(`
        SELECT oi.*, p.name as product_name, p.image_path 
        FROM order_items oi
        LEFT JOIN products p ON oi.product_id = p.id
        WHERE oi.order_id = ?
      `, [order.id]);

      console.log(`Order #${order.id} has ${items.length} items`);

      // Sử dụng tên sản phẩm từ order_items hoặc từ products
      const itemsWithNames = items.map(item => {
        // In ra thông tin để debug
        console.log(`Item in order #${order.id}:`, {
          id: item.id,
          product_id: item.product_id,
          name: item.name,
          product_name: item.product_name
        });

        // Ưu tiên sử dụng tên từ bảng products nếu có
        return {
          ...item,
          name: item.product_name || item.name || 'Sản phẩm không xác định'
        };
      });

      return {
        ...order,
        items: itemsWithNames
      };
    }));

    res.json({
      status: 'success',
      data: ordersWithItems
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Cập nhật trạng thái đơn hàng
app.put('/api/orders/:id/status', async (req, res) => {
  try {
    const { status, reason } = req.body;
    const orderId = req.params.id;

    console.log(`Updating order #${orderId} status to: ${status}`);
    console.log('Request body:', req.body);

    if (!status) {
      return res.status(400).json({ status: 'error', message: 'Status is required' });
    }

    // Kiểm tra trạng thái hợp lệ
    const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returning', 'returned'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        status: 'error',
        message: `Invalid status. Valid values are: ${validStatuses.join(', ')}`
      });
    }

    // Lấy thông tin đơn hàng hiện tại
    const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (orders.length === 0) {
      return res.status(404).json({ status: 'error', message: 'Order not found' });
    }
    const order = orders[0];

    // Lấy thông tin sản phẩm trong đơn hàng để hiển thị trong thông báo
    const [items] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [orderId]);
    let productText = '';
    if (items.length > 0) {
      if (items.length === 1) {
        productText = items[0].name || `#${items[0].product_id}`;
      } else {
        productText = `(${items.length} sản phẩm)`;
      }
    }

    // Cập nhật trạng thái và lý do trả hàng nếu có
    if (status === 'returning' && reason) {
      await pool.query(
        'UPDATE orders SET status = ?, return_reason = ? WHERE id = ?',
        [status, reason, orderId]
      );
    } else {
      await pool.query(
        'UPDATE orders SET status = ? WHERE id = ?',
        [status, orderId]
      );
    }

    // Cập nhật thời gian giao hàng nếu trạng thái là delivered
    if (status === 'delivered') {
      await pool.query(
        'UPDATE orders SET delivered_at = NOW() WHERE id = ?',
        [orderId]
      );
    }

    // Tạo thông báo cho người dùng về việc cập nhật trạng thái đơn hàng
    let title, message;
    switch (status) {
      case 'processing':
        title = 'Đơn hàng đang được xử lý';
        message = `Đơn hàng ${productText} của bạn đang được xử lý.`;
        break;
      case 'shipped':
        title = 'Đơn hàng đang được giao';
        message = `Đơn hàng ${productText} của bạn đang được giao đến bạn.`;
        break;
      case 'delivered':
        if (order.status === 'returning') {
          title = 'Yêu cầu trả hàng bị từ chối';
          message = `Yêu cầu trả hàng cho đơn hàng ${productText} của bạn đã bị từ chối. Vui lòng liên hệ với chúng tôi để biết thêm chi tiết.`;
        } else {
          title = 'Đơn hàng đã giao thành công';
          message = `Đơn hàng ${productText} của bạn đã được giao thành công. Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!`;
        }
        break;
      case 'cancelled':
        title = 'Đơn hàng đã bị hủy';
        message = `Đơn hàng ${productText} của bạn đã bị hủy.`;
        break;
      case 'returning':
        title = 'Yêu cầu trả hàng đã được ghi nhận';
        message = `Yêu cầu trả hàng cho đơn hàng ${productText} của bạn đã được ghi nhận. Chúng tôi sẽ xem xét và phản hồi sớm.`;
        break;
      case 'returned':
        title = 'Đơn hàng đã được trả thành công';
        message = `Đơn hàng ${productText} của bạn đã được trả thành công. Tiền hoàn trả sẽ được chuyển lại cho bạn trong 3-5 ngày làm việc.`;
        break;
      default:
        title = 'Cập nhật trạng thái đơn hàng';
        message = `Đơn hàng ${productText} của bạn đã được cập nhật sang trạng thái ${status}.`;
    }

    // Thêm thông báo vào database
    await pool.query(
      'INSERT INTO notifications (user_id, title, message, is_read) VALUES (?, ?, ?, ?)',
      [order.user_id, title, message, 0]
    );

    res.json({
      status: 'success',
      message: 'Order status updated successfully',
      data: { id: orderId, status }
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ status: 'error', message: error.message || 'Internal server error' });
  }
});

// Tạo đơn hàng mới
app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items } = req.body;

    console.log('Received order request:', JSON.stringify({ user_id, total_amount, items }, null, 2));

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

      // Thêm các sản phẩm vào đơn hàng
      for (const item of items) {
        // Đảm bảo product_id là số nguyên
        const productId = parseInt(item.product_id || item.id);

        if (isNaN(productId)) {
          throw new Error(`Invalid product ID: ${item.product_id || item.id}`);
        }

        const quantity = parseInt(item.quantity) || 1;
        const price = parseFloat(item.price) || 0;

        // Lấy tên sản phẩm từ request
        const productName = item.name;

        console.log(`Adding item to order #${orderId}:`, {
          product_id: productId,
          name: productName,
          quantity: quantity,
          price: price
        });

        // Kiểm tra xem tên sản phẩm có null không
        if (!productName) {
          console.warn(`Warning: Product name is null for product_id ${productId}`);

          // Nếu tên sản phẩm null, thử lấy từ bảng products
          const [products] = await connection.query(
            'SELECT name FROM products WHERE id = ?',
            [productId]
          );

          if (products.length > 0 && products[0].name) {
            console.log(`Found product name from database: ${products[0].name}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, products[0].name, quantity, price]
            );
          } else {
            // Nếu không tìm thấy, sử dụng ID sản phẩm
            const fallbackName = `Sản phẩm #${productId}`;
            console.log(`Using fallback name: ${fallbackName}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, fallbackName, quantity, price]
            );
          }
        } else {
          // Nếu có tên sản phẩm, sử dụng nó
          await connection.query(
            'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
            [orderId, productId, productName, quantity, price]
          );
        }
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
      console.error('Transaction error:', error);
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

// Cập nhật người dùng (cho admin và người dùng thông thường)
app.put('/api/users/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const { name, email, password, role, profile_image } = req.body;

    if (!name || !email) {
      return res.status(400).json({ status: 'error', message: 'Name and email are required' });
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

    let query = 'UPDATE users SET name = ?, email = ? WHERE id = ?';
    let params = [name, email, userId];

    // Nếu có mật khẩu mới, mã hóa và cập nhật
    if (password) {
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      query = 'UPDATE users SET name = ?, email = ?, password = ? WHERE id = ?';
      params = [name, email, hashedPassword, userId];
    }

    // Nếu có role (cho admin), cập nhật role
    if (role) {
      query = query.replace('WHERE', ', role = ? WHERE');
      params.splice(params.length - 1, 0, role);
    }

    // Nếu có ảnh đại diện mới, cập nhật
    if (profile_image) {
      query = query.replace('WHERE', ', profile_image = ? WHERE');
      params.splice(params.length - 1, 0, profile_image);
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
        role: role || existingUsers[0].role,
        profile_image: profile_image || existingUsers[0].profile_image
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

// Thêm API endpoint để kiểm tra dữ liệu sản phẩm
app.get('/api/debug/products', async (req, res) => {
  try {
    // Lấy tất cả sản phẩm
    const [products] = await pool.query('SELECT * FROM products');
    console.log('All products:', products);

    // Tìm sản phẩm có tên Hamburger
    const [hamburgers] = await pool.query('SELECT * FROM products WHERE name LIKE ?', ['%Hamburger%']);
    console.log('Hamburger products:', hamburgers);

    // Kiểm tra bảng order_items
    const [orderItems] = await pool.query('SELECT * FROM order_items LIMIT 20');
    console.log('Recent order items:', orderItems);

    res.json({
      status: 'success',
      data: {
        allProducts: products,
        hamburgerProducts: hamburgers,
        recentOrderItems: orderItems
      }
    });
  } catch (error) {
    console.error('Error debugging products:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});


// API để xóa bảng food_items và tạo bảng products

// API để kiểm tra và sửa thông tin sản phẩm trong đơn hàng
app.get('/api/debug/check-products', async (req, res) => {
  try {
    // 1. Kiểm tra tất cả các sản phẩm trong bảng products
    const [products] = await pool.query(`
      SELECT id, name FROM products
    `);

    console.log(`Found ${products.length} products in products table`);

    // 2. Kiểm tra các mục đơn hàng và sản phẩm tương ứng
    const [orderItems] = await pool.query(`
      SELECT oi.id, oi.order_id, oi.product_id, oi.name,
             p.id as found_product_id, p.name as product_name
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      LIMIT 50
    `);

    console.log(`Checking ${orderItems.length} order items`);

    // Đếm số lượng mục không tìm thấy sản phẩm
    let missingProductCount = 0;
    for (const item of orderItems) {
      if (!item.found_product_id) {
        missingProductCount++;
        console.log(`Order item #${item.id} has product_id ${item.product_id} but no matching product found`);
      }
    }

    // 3. Kiểm tra xem có sản phẩm nào trong food_items không
    let foodItems = [];
    try {
      const [result] = await pool.query(`
        SELECT id, name FROM food_items
      `);
      foodItems = result;
      console.log(`Found ${foodItems.length} items in food_items table`);
    } catch (error) {
      console.log('Could not query food_items table:', error.message);
    }

    // 4. Cập nhật tên sản phẩm trong order_items nếu không tìm thấy trong products
    let updatedCount = 0;
    for (const item of orderItems) {
      if (!item.product_name) {
        // Tìm tên sản phẩm trong food_items nếu có
        const foodItem = foodItems.find(fi => fi.id === item.product_id);
        if (foodItem) {
          await pool.query(
            'UPDATE order_items SET name = ? WHERE id = ?',
            [foodItem.name, item.id]
          );
          updatedCount++;
          console.log(`Updated order item #${item.id} with name from food_items: ${foodItem.name}`);
        } else {
          // Nếu không tìm thấy, đặt tên mặc định
          await pool.query(
            'UPDATE order_items SET name = ? WHERE id = ?',
            [`Sản phẩm #${item.product_id}`, item.id]
          );
          updatedCount++;
          console.log(`Updated order item #${item.id} with default name: Sản phẩm #${item.product_id}`);
        }
      }
    }

    res.json({
      status: 'success',
      message: `Found ${missingProductCount} order items with missing products. Updated ${updatedCount} items.`,
      data: {
        products: products,
        orderItems: orderItems,
        foodItems: foodItems,
        missingProductCount: missingProductCount,
        updatedCount: updatedCount
      }
    });
  } catch (error) {
    console.error('Error checking products:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API để cập nhật tên sản phẩm trong bảng order_items
app.post('/api/admin/update-order-items', async (req, res) => {
  try {
    // Lấy tất cả các mục đơn hàng
    const [orderItems] = await pool.query(`
      SELECT id, order_id, product_id, name
      FROM order_items
      WHERE name IS NULL OR name = ''
    `);

    console.log(`Found ${orderItems.length} order items without names`);

    // Cập nhật tên sản phẩm cho từng mục
    let updatedCount = 0;
    for (const item of orderItems) {
      // Tìm sản phẩm trong bảng products
      const [products] = await pool.query(
        'SELECT name FROM products WHERE id = ?',
        [item.product_id]
      );

      let productName = null;

      if (products.length > 0 && products[0].name) {
        // Nếu tìm thấy trong products
        productName = products[0].name;
      } else {
        // Nếu không tìm thấy trong products, tìm trong food_items
        try {
          const [foodItems] = await pool.query(
            'SELECT name FROM food_items WHERE id = ?',
            [item.product_id]
          );

          if (foodItems.length > 0 && foodItems[0].name) {
            productName = foodItems[0].name;
          }
        } catch (error) {
          console.log('Could not query food_items table:', error.message);
        }
      }

      // Nếu vẫn không tìm thấy, sử dụng ID sản phẩm
      if (!productName) {
        productName = `Sản phẩm #${item.product_id}`;
      }

      // Cập nhật tên sản phẩm
      await pool.query(
        'UPDATE order_items SET name = ? WHERE id = ?',
        [productName, item.id]
      );

      updatedCount++;
    }

    res.json({
      status: 'success',
      message: `Updated ${updatedCount} order items with product names`,
      data: { total: orderItems.length, updated: updatedCount }
    });
  } catch (error) {
    console.error('Error updating order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Cập nhật API tạo đơn hàng để đảm bảo lưu tên sản phẩm
app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items } = req.body;

    console.log('Received order request:', JSON.stringify({ user_id, total_amount, items }, null, 2));

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

      // Thêm các sản phẩm vào đơn hàng
      for (const item of items) {
        // Đảm bảo product_id là số nguyên
        const productId = parseInt(item.product_id || item.id);

        if (isNaN(productId)) {
          throw new Error(`Invalid product ID: ${item.product_id || item.id}`);
        }

        const quantity = parseInt(item.quantity) || 1;
        const price = parseFloat(item.price) || 0;

        // Lấy tên sản phẩm từ request
        const productName = item.name;

        console.log(`Adding item to order #${orderId}:`, {
          product_id: productId,
          name: productName,
          quantity: quantity,
          price: price
        });

        // Kiểm tra xem tên sản phẩm có null không
        if (!productName) {
          console.warn(`Warning: Product name is null for product_id ${productId}`);

          // Nếu tên sản phẩm null, thử lấy từ bảng products
          const [products] = await connection.query(
            'SELECT name FROM products WHERE id = ?',
            [productId]
          );

          if (products.length > 0 && products[0].name) {
            console.log(`Found product name from database: ${products[0].name}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, products[0].name, quantity, price]
            );
          } else {
            // Nếu không tìm thấy, sử dụng ID sản phẩm
            const fallbackName = `Sản phẩm #${productId}`;
            console.log(`Using fallback name: ${fallbackName}`);
            await connection.query(
              'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
              [orderId, productId, fallbackName, quantity, price]
            );
          }
        } else {
          // Nếu có tên sản phẩm, sử dụng nó
          await connection.query(
            'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES (?, ?, ?, ?, ?)',
            [orderId, productId, productName, quantity, price]
          );
        }
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
      console.error('Transaction error:', error);
      throw error;
    }
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API để cập nhật tên sản phẩm trong bảng order_items
app.post('/api/admin/fix-order-items', async (req, res) => {
  try {
    // Lấy tất cả các mục đơn hàng không có tên
    const [orderItems] = await pool.query(`
      SELECT oi.id, oi.order_id, oi.product_id, oi.name, p.name as product_name
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      WHERE oi.name IS NULL OR oi.name = ''
    `);

    console.log(`Found ${orderItems.length} order items without names`);

    // Cập nhật tên sản phẩm cho từng mục
    let updatedCount = 0;
    for (const item of orderItems) {
      if (item.product_name) {
        await pool.query(
          'UPDATE order_items SET name = ? WHERE id = ?',
          [item.product_name, item.id]
        );
        updatedCount++;
      }
    }

    res.json({
      status: 'success',
      message: `Updated ${updatedCount} order items with product names`,
      data: { total: orderItems.length, updated: updatedCount }
    });
  } catch (error) {
    console.error('Error fixing order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API để cập nhật product_id trong bảng order_items
app.post('/api/admin/fix-order-items-product-id', async (req, res) => {
  try {
    // 1. Lấy danh sách sản phẩm từ bảng products
    const [products] = await pool.query(`
      SELECT id, name, price FROM products
      ORDER BY id ASC
      LIMIT 1
    `);

    if (products.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'No products found in the database'
      });
    }

    // Lấy sản phẩm đầu tiên để sử dụng làm tham chiếu
    const defaultProduct = products[0];
    console.log(`Using default product: ${defaultProduct.name} (ID: ${defaultProduct.id})`);

    // 2. Cập nhật tất cả các mục trong order_items có product_id không tồn tại
    const [result] = await pool.query(`
      UPDATE order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      SET oi.product_id = ?, oi.name = ?
      WHERE p.id IS NULL
    `, [defaultProduct.id, defaultProduct.name]);

    console.log(`Updated ${result.affectedRows} order items with valid product_id`);

    res.json({
      status: 'success',
      message: `Updated ${result.affectedRows} order items with valid product_id`,
      data: {
        defaultProduct: defaultProduct,
        affectedRows: result.affectedRows
      }
    });
  } catch (error) {
    console.error('Error fixing order items product_id:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Cập nhật API lấy danh sách đơn hàng
app.get('/api/orders', async (req, res) => {
  try {
    const { user_id, status } = req.query;

    let query = `
      SELECT o.*, u.name as user_name 
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE 1=1
    `;

    const params = [];

    if (user_id) {
      query += ' AND o.user_id = ?';
      params.push(user_id);
    }

    if (status) {
      query += ' AND o.status = ?';
      params.push(status);
    }

    // Sắp xếp theo id giảm dần (đơn hàng mới nhất trước)
    query += ' ORDER BY o.id DESC';

    console.log('Orders query:', query);

    const [orders] = await pool.query(query, params);
    console.log(`Found ${orders.length} orders`);

    // Lấy chi tiết đơn hàng cho mỗi đơn hàng
    const ordersWithItems = await Promise.all(orders.map(async (order) => {
      // Lấy thông tin chi tiết đơn hàng kèm tên sản phẩm
      const [items] = await pool.query(`
        SELECT oi.*, p.name as product_name, p.image_path 
        FROM order_items oi
        LEFT JOIN products p ON oi.product_id = p.id
        WHERE oi.order_id = ?
      `, [order.id]);

      console.log(`Order #${order.id} has ${items.length} items`);

      // Sử dụng tên sản phẩm từ order_items hoặc từ products
      const itemsWithNames = items.map(item => {
        // In ra thông tin để debug
        console.log(`Item in order #${order.id}:`, {
          id: item.id,
          product_id: item.product_id,
          name: item.name,
          product_name: item.product_name
        });

        // Nếu không có tên sản phẩm, sử dụng ID sản phẩm
        return {
          ...item,
          name: item.name || item.product_name || `Sản phẩm #${item.product_id}`
        };
      });

      return {
        ...order,
        items: itemsWithNames
      };
    }));

    res.json({
      status: 'success',
      data: ordersWithItems
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API lấy danh sách đơn hàng của người dùng
app.get('/users/:id/orders', async (req, res) => {
  try {
    const userId = req.params.id;
    
    console.log(`Getting orders for user ${userId}`);
    
    // Lấy danh sách đơn hàng
    const [orders] = await pool.query(
      `SELECT * FROM orders 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );
    
    console.log(`Found ${orders.length} orders for user ${userId}`);
    
    res.json({
      status: 'success',
      data: orders
    });
  } catch (error) {
    console.error('Error getting user orders:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API để lấy các mục trong đơn hàng
app.get('/orders/:id/items', async (req, res) => {
  try {
    const orderId = req.params.id;
    
    console.log(`Getting items for order ${orderId}`);
    
    // Lấy các mục trong đơn hàng
    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );
    
    console.log(`Found ${items.length} items for order ${orderId}`);
    
    res.json({
      status: 'success',
      data: items
    });
  } catch (error) {
    console.error('Error getting order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Cập nhật thông tin cá nhân (cho người dùng)
app.put('/api/users/profile/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const { name, email, password, profile_image } = req.body;

    if (!name || !email) {
      return res.status(400).json({
        status: 'error',
        message: 'Name and email are required'
      });
    }

    // Kiểm tra người dùng tồn tại
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    // Kiểm tra email đã tồn tại chưa (nếu thay đổi email)
    if (email !== existingUsers[0].email) {
      const [emailCheck] = await pool.query('SELECT * FROM users WHERE email = ? AND id != ?', [email, userId]);

      if (emailCheck.length > 0) {
        return res.status(409).json({
          status: 'error',
          message: 'Email already exists'
        });
      }
    }

    let query = 'UPDATE users SET name = ?, email = ? WHERE id = ?';
    let params = [name, email, userId];

    // Nếu có mật khẩu mới, mã hóa và cập nhật
    if (password) {
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      query = 'UPDATE users SET name = ?, email = ?, password = ? WHERE id = ?';
      params = [name, email, hashedPassword, userId];
    }

    // Nếu có ảnh đại diện mới, cập nhật
    if (profile_image) {
      query = query.replace('WHERE', ', profile_image = ? WHERE');
      params.splice(params.length - 1, 0, profile_image);
    }

    const [result] = await pool.query(query, params);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Profile updated successfully',
      data: {
        id: userId,
        name,
        email,
        profile_image: profile_image || existingUsers[0].profile_image
      }
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Tạo thư mục uploads nếu chưa tồn tại
const uploadDir = path.join(__dirname, 'uploads');
const profileImagesDir = path.join(uploadDir, 'profile_images');

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

if (!fs.existsSync(profileImagesDir)) {
  fs.mkdirSync(profileImagesDir);
}

// Cấu hình multer để lưu file upload
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, profileImagesDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'profile-' + uniqueSuffix + ext);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Giới hạn 5MB
  fileFilter: function (req, file, cb) {
    // Chỉ chấp nhận file ảnh
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

// Phục vụ các file tĩnh từ thư mục uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API endpoint để upload ảnh đại diện
app.post('/api/upload-profile-image', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        status: 'error',
        message: 'No file uploaded'
      });
    }

    const userId = req.body.user_id;
    if (!userId) {
      return res.status(400).json({
        status: 'error',
        message: 'User ID is required'
      });
    }

    // Kiểm tra người dùng tồn tại
    const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);
    if (users.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    // Đường dẫn tương đối đến file ảnh
    const relativePath = '/uploads/profile_images/' + req.file.filename;

    // Cập nhật đường dẫn ảnh đại diện trong cơ sở dữ liệu
    await pool.query(
      'UPDATE users SET profile_image = ? WHERE id = ?',
      [relativePath, userId]
    );

    // Trả về đường dẫn đầy đủ đến ảnh
    const fullUrl = req.protocol + '://' + req.get('host') + relativePath;

    res.json({
      status: 'success',
      message: 'Profile image uploaded successfully',
      image_url: fullUrl
    });
  } catch (error) {
    console.error('Error uploading profile image:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API lấy thông báo của người dùng
app.get('/api/users/:userId/notifications', async (req, res) => {
  try {
    const userId = req.params.userId;

    // Kiểm tra userId
    if (!userId) {
      return res.status(400).json({ status: 'error', message: 'User ID is required' });
    }

    // Lấy thông báo từ database
    const [notifications] = await pool.query(
      `SELECT id, user_id, title, message, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );

    console.log(`Found ${notifications.length} notifications for user ${userId}`);

    res.json({
      status: 'success',
      data: notifications
    });
  } catch (error) {
    console.error('Error fetching user notifications:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API đánh dấu thông báo đã đọc
app.put('/api/notifications/:id/read', async (req, res) => {
  try {
    const notificationId = req.params.id;

    // Cập nhật trạng thái đã đọc
    await pool.query(
      'UPDATE notifications SET is_read = 1 WHERE id = ?',
      [notificationId]
    );

    res.json({
      status: 'success',
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API đánh dấu tất cả thông báo của người dùng đã đọc
app.put('/api/users/:userId/notifications/read-all', async (req, res) => {
  try {
    const userId = req.params.userId;

    // Cập nhật tất cả thông báo của người dùng thành đã đọc
    await pool.query(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ?',
      [userId]
    );

    res.json({
      status: 'success',
      message: 'All notifications marked as read'
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API endpoints cho chat

// Lấy tin nhắn chat của người dùng
app.get('/api/chat/messages/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Thêm log để debug
    console.log(`Getting messages for user ${userId}`);
    
    const [messages] = await pool.query(
      `SELECT * FROM chat_messages 
       WHERE user_id = ? 
       ORDER BY created_at ASC`,
      [userId]
    );
    
    console.log(`Retrieved ${messages.length} messages for user ${userId}`);
    
    // Thêm header để tránh cache
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    
    res.json({
      status: 'success',
      data: messages
    });
  } catch (error) {
    console.error('Error fetching chat messages:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API gửi tin nhắn chat
app.post('/api/chat/messages', async (req, res) => {
  console.log('Received chat message request:', req.body);
  try {
    const { userId, message, sender } = req.body;
    
    if (!userId || !message || !sender) {
      return res.status(400).json({ 
        status: 'error', 
        message: 'Missing required fields' 
      });
    }
    
    const [result] = await pool.query(
      'INSERT INTO chat_messages (user_id, sender, message) VALUES (?, ?, ?)',
      [userId, sender, message]
    );
    
    console.log('Message saved successfully, ID:', result.insertId);
    
    res.json({
      status: 'success',
      message: 'Message sent successfully',
      data: {
        id: result.insertId
      }
    });
  } catch (error) {
    console.error('Error sending chat message:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Lấy danh sách người dùng có tin nhắn (cho admin)
app.get('/api/chat/users', async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT DISTINCT cm.user_id, u.name as user_name,
        (SELECT message FROM chat_messages 
         WHERE user_id = cm.user_id 
         ORDER BY created_at DESC LIMIT 1) as last_message,
        (SELECT created_at FROM chat_messages 
         WHERE user_id = cm.user_id 
         ORDER BY created_at DESC LIMIT 1) as last_message_time,
        (SELECT COUNT(*) FROM chat_messages 
         WHERE user_id = cm.user_id AND sender = 'user' AND is_read = 0) as unread_count
      FROM chat_messages cm
      LEFT JOIN users u ON cm.user_id = u.id
      ORDER BY last_message_time DESC
    `);
    
    res.json({
      status: 'success',
      data: users
    });
  } catch (error) {
    console.error('Error fetching chat users:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Đánh dấu tin nhắn đã đọc
app.post('/api/chat/mark-read', async (req, res) => {
  try {
    const { userId, sender } = req.body;
    
    console.log(`Marking messages as read for user ${userId}, sender ${sender}`);
    
    await pool.query(
      'UPDATE chat_messages SET is_read = TRUE WHERE user_id = ? AND sender = ?',
      [userId, sender]
    );
    
    // Thêm header để tránh cache
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    
    res.json({
      status: 'success',
      message: 'Messages marked as read'
    });
  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// API để lấy chi tiết đơn hàng
app.get('/api/orders/:id/details', async (req, res) => {
  try {
    const orderId = req.params.id;
    
    // Lấy thông tin đơn hàng
    const [orders] = await pool.query(
      'SELECT * FROM orders WHERE id = ?',
      [orderId]
    );
    
    if (orders.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Order not found'
      });
    }
    
    // Lấy các mục trong đơn hàng với thông tin sản phẩm
    const [items] = await pool.query(
      `SELECT oi.*, p.name, p.image_url 
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );
    
    res.json({
      status: 'success',
      data: {
        order: orders[0],
        items: items
      }
    });
  } catch (error) {
    console.error('Error getting order details:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API để lấy các mục trong đơn hàng
app.get('/api/orders/:id/items', async (req, res) => {
  try {
    const orderId = req.params.id;
    
    // Lấy các mục trong đơn hàng
    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );
    
    res.json({
      status: 'success',
      data: items
    });
  } catch (error) {
    console.error('Error getting order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Thêm API endpoint để kiểm tra và sửa thông tin sản phẩm trong đơn hàng
app.get('/api/debug/fix-order-items', async (req, res) => {
  try {
    // 1. Lấy danh sách đơn hàng có trạng thái returning
    const [returningOrders] = await pool.query(`
      SELECT id, status FROM orders 
      WHERE status = 'returning'
    `);
    
    console.log(`Found ${returningOrders.length} orders with returning status`);
    
    // 2. Lấy thông tin chi tiết các mục trong đơn hàng
    let fixedItems = 0;
    for (const order of returningOrders) {
      const orderId = order.id;
      
      // Lấy các mục trong đơn hàng
      const [items] = await pool.query(`
        SELECT id, order_id, product_id, name 
        FROM order_items 
        WHERE order_id = ?
      `, [orderId]);
      
      console.log(`Order #${orderId} has ${items.length} items`);
      
      // Kiểm tra và cập nhật tên sản phẩm nếu cần
      for (const item of items) {
        if (!item.name || item.name === '') {
          // Tìm thông tin sản phẩm
          const [products] = await pool.query(`
            SELECT name FROM products WHERE id = ?
          `, [item.product_id]);
          
          if (products.length > 0) {
            // Cập nhật tên sản phẩm
            await pool.query(`
              UPDATE order_items SET name = ? WHERE id = ?
            `, [products[0].name, item.id]);
            
            fixedItems++;
            console.log(`Fixed item #${item.id} with product name: ${products[0].name}`);
          } else {
            // Nếu không tìm thấy sản phẩm, đặt tên mặc định
            await pool.query(`
              UPDATE order_items SET name = ? WHERE id = ?
            `, [`Sản phẩm #${item.product_id}`, item.id]);
            
            fixedItems++;
            console.log(`Fixed item #${item.id} with default name: Sản phẩm #${item.product_id}`);
          }
        }
      }
    }
    
    res.json({
      status: 'success',
      message: `Fixed ${fixedItems} items in returning orders`,
      data: {
        returningOrders,
        fixedItems
      }
    });
  } catch (error) {
    console.error('Error fixing order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API lấy tất cả đơn hàng
app.get('/api/orders', async (req, res) => {
  try {
    // Lấy danh sách đơn hàng từ database
    const [orders] = await pool.query(`
      SELECT o.*, u.name as user_name
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE 1=1
     ORDER BY o.id DESC
    `);
    
    console.log(`Found ${orders.length} orders`);
    
    // Log trạng thái của các đơn hàng để debug
    orders.forEach(order => {
      console.log(`Order #${order.id}: ${order.status} - ${order.total_amount}`);
    });

    // Lấy chi tiết sản phẩm cho mỗi đơn hàng
    for (const order of orders) {
      const [items] = await pool.query(
        'SELECT * FROM order_items WHERE order_id = ?',
        [order.id]
      );
      order.items = items;
    }
    
    console.log(`Successfully parsed ${orders.length} orders`);
    
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});



