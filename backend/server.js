const express = require('express');
const mysql = require('mysql2/promise');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const app = express();
const port = process.env.PORT || 3001;
const saltRounds = 10;
/*---------------------------------
Middleware
-----------------------------------*/
app.use(cors());
app.use(bodyParser.json());

/*---------------------------------
Connect Db Mysql Workbend
-----------------------------------*/
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

/*---------------------------------
- Start Server
-----------------------------------*/
let server;
/*---------------------------------

-----------------------------------*/
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
/*---------------------------------

-----------------------------------*/
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


    setTimeout(() => {
      console.log('Forcing exit after timeout');
      process.exit(1);
    }, 5000);
  } else {
    process.exit(0);
  }
});


process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);

});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);

});
/*---------------------------------
- Thêm API endpoint để lấy thông 
tin người dùng
-----------------------------------*/
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

/*---------------------------------
-Login Api
-----------------------------------*/
app.post('/api/users/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ status: 'error', message: 'Email and password are required' });
    }

    /*---------------------------------
    Find user by email
    -----------------------------------*/
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
      role: user.role || 'user',
    };

    res.json({ status: 'success', message: 'Login successful', data: userData });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

/*---------------------------------
-Singnup Api
-----------------------------------*/
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

/*---------------------------------
- Create order by (user)
-----------------------------------*/

app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items, payment_method } = req.body;

    console.log('Received order request:', JSON.stringify({ user_id, total_amount, items, payment_method }, null, 2));

    if (!user_id || !total_amount || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ status: 'error', message: 'Invalid order data' });
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Nếu thanh toán bằng ví, kiểm tra số dư và trừ tiền
      if (payment_method === 'wallet') {
        // Kiểm tra số dư ví
        const [walletRows] = await connection.query(
          'SELECT * FROM wallets WHERE user_id = ?',
          [user_id]
        );

        // Nếu ví không tồn tại hoặc số dư không đủ
        if (walletRows.length === 0) {
          await connection.rollback();
          return res.status(400).json({
            status: 'error',
            message: 'Ví không tồn tại'
          });
        }

        const wallet = walletRows[0];
        const balance = parseFloat(wallet.balance);

        if (balance < total_amount) {
          await connection.rollback();
          return res.status(400).json({
            status: 'error',
            message: 'Số dư ví không đủ để thanh toán'
          });
        }

        // Trừ tiền từ ví
        await connection.query(
          'UPDATE wallets SET balance = balance - ? WHERE user_id = ?',
          [total_amount, user_id]
        );

        // Tạo giao dịch ví
        await connection.query(
          `INSERT INTO wallet_transactions 
           (user_id, amount, type, status, description, created_at) 
           VALUES (?, ?, 'payment', 'completed', 'Thanh toán đơn hàng', NOW())`,
          [user_id, total_amount]
        );
      }

      // Tạo đơn hàng
      const [orderResult] = await connection.query(
        'INSERT INTO orders (user_id, total_amount, status, payment_method) VALUES (?, ?, ?, ?)',
        [user_id, total_amount, 'pending', payment_method || 'cod']
      );

      const orderId = orderResult.insertId;

      // Thêm các sản phẩm vào đơn hàng
      for (const item of items) {
        await connection.query(
          'INSERT INTO order_items (order_id, product_id, name, price, quantity) VALUES (?, ?, ?, ?, ?)',
          [orderId, item.id, item.name, item.price, item.quantity]
        );
      }

      // Commit transaction
      await connection.commit();

      // Trả về kết quả thành công
      return res.status(201).json({
        status: 'success',
        message: 'Order created successfully',
        order_id: orderId,
        payment_method: payment_method || 'cod'
      });
    } catch (error) {
      // Rollback nếu có lỗi
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

/*---------------------------------
- Api change password
-----------------------------------*/

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
    /*---------------------------------
       - 
    -----------------------------------*/
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
    /*---------------------------------
       - 
    -----------------------------------*/
    // Kiểm tra mật khẩu hiện tại
    const passwordMatch = await bcrypt.compare(currentPassword, user.password);

    if (!passwordMatch) {
      return res.status(401).json({
        status: 'error',
        message: 'Current password is incorrect'
      });
    }
    /*---------------------------------
       - 
       -----------------------------------*/
    // Mã hóa mật khẩu mới
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    /*---------------------------------
    - 
    -----------------------------------*/
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

/*---------------------------------
- Get all orders by (admin)
-----------------------------------*/
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

    query += ' ORDER BY o.id DESC';

    const [orders] = await pool.query(query, params);

    // Lấy chi tiết sản phẩm cho mỗi đơn hàng
    const ordersWithItems = await Promise.all(orders.map(async (order) => {
      const [items] = await pool.query(
        'SELECT oi.*, p.name as product_name FROM order_items oi LEFT JOIN products p ON oi.product_id = p.id WHERE oi.order_id = ?',
        [order.id]
      );

      // Sử dụng tên sản phẩm từ order_items hoặc từ products
      const itemsWithNames = items.map(item => {
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
/*---------------------------------
- Api Update status order
-----------------------------------*/
app.post('/api/orders/:id/status', async (req, res) => {
  try {
    const orderId = req.params.id;
    const { status, reason } = req.body;

    console.log(`Updating order ${orderId} to status: ${status}`);

    // Lấy thông tin đơn hàng
    const [orderRows] = await pool.query(
      'SELECT o.*, u.name as user_name FROM orders o LEFT JOIN users u ON o.user_id = u.id WHERE o.id = ?',
      [orderId]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({ status: 'error', message: 'Order not found' });
    }

    const order = orderRows[0];

    // Lấy thông tin sản phẩm trong đơn hàng
    const [orderItems] = await pool.query(
      'SELECT oi.*, p.name as product_name FROM order_items oi LEFT JOIN products p ON oi.product_id = p.id WHERE oi.order_id = ?',
      [orderId]
    );

    // Tạo mô tả sản phẩm cho thông báo
    let productText = 'Đơn hàng của bạn';
    if (orderItems.length > 0) {
      const firstItem = orderItems[0];
      const productName = firstItem.product_name || firstItem.name || 'Sản phẩm';

      if (orderItems.length > 1) {
        productText = `${productName} và ${orderItems.length - 1} sản phẩm khác`;
      } else {
        productText = productName;
      }
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Nếu trạng thái là 'returned' (đã chấp nhận trả hàng), thực hiện hoàn tiền
      if (status === 'returned') {
        // Kiểm tra phương thức thanh toán của đơn hàng
        if (order.payment_method === 'wallet') {
          // Lấy thông tin người dùng
          const userId = order.user_id;
          const totalAmount = parseFloat(order.total_amount);

          console.log(`Refunding ${totalAmount} to user ${userId}'s wallet`);

          // Cập nhật số dư ví của người dùng
          await connection.query(
            'UPDATE wallets SET balance = balance + ? WHERE user_id = ?',
            [totalAmount, userId]
          );

          // Tạo giao dịch ví với loại 'payment'
          await connection.query(
            `INSERT INTO wallet_transactions 
             (user_id, amount, type, status, description, reference_id, created_at) 
             VALUES (?, ?, 'payment', 'completed', ?, ?, NOW())`,
            [userId, totalAmount, `Hoàn tiền đơn hàng ${productText}`, orderId]
          );

          console.log(`Refund completed for order ${orderId}`);
        } else {
          console.log(`Order ${orderId} used payment method ${order.payment_method}, no wallet refund needed`);
        }
      }

      // Cập nhật trạng thái và lý do trả hàng nếu có
      if ((status === 'returning' || status === 'returned') && reason) {
        await connection.query(
          'UPDATE orders SET status = ?, return_reason = ? WHERE id = ?',
          [status, reason, orderId]
        );
      } else {
        await connection.query(
          'UPDATE orders SET status = ? WHERE id = ?',
          [status, orderId]
        );
      }

      // Cập nhật thời gian giao hàng nếu trạng thái là delivered
      if (status === 'delivered') {
        await connection.query(
          'UPDATE orders SET delivered_at = NOW() WHERE id = ?',
          [orderId]
        );
      }

      // Commit transaction
      await connection.commit();

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
            message = `Yêu cầu trả hàng cho đơn hàng ${productText} của bạn đã bị từ chối.`;
          } else {
            title = 'Đơn hàng đã giao thành công';
            message = `Đơn hàng ${productText} của bạn đã được giao thành công.`;
          }
          break;
        case 'returned':
          title = 'Đơn hàng đã được hoàn trả';
          message = `Đơn hàng ${productText} của bạn đã được hoàn trả thành công. ${order.payment_method === 'wallet' ? 'Số tiền đã được hoàn vào ví của bạn.' : ''}`;
          break;
        case 'cancelled':
          title = 'Đơn hàng đã bị hủy';
          message = `Đơn hàng ${productText} của bạn đã bị hủy.`;
          break;
      }

      // Tạo thông báo nếu có title và message
      if (title && message) {
        await pool.query(
          'INSERT INTO notifications (user_id, title, message, created_at) VALUES (?, ?, ?, NOW())',
          [order.user_id, title, message]
        );
      }

      return res.json({
        status: 'success',
        message: `Order status updated to ${status} successfully`,
        refunded: status === 'returned' && order.payment_method === 'wallet'
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});/*---------------------------------
- 
-----------------------------------*/
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
/*---------------------------------
- Get all products by ID
-----------------------------------*/

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
/*---------------------------------
- Create product by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- Update product by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- Delete product by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- Get all users by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- Create user by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- update  users by admin or user
-----------------------------------*/
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
/*---------------------------------
- Delete all users by admin (admin)
-----------------------------------*/
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
/*---------------------------------
- Get all orders by user (user)
-----------------------------------*/
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
    console.log(`Fetching items for order #${orderId}`);

    // Lấy thông tin chi tiết sản phẩm trong đơn hàng
    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name, p.description, p.price as product_price
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );

    console.log(`Found ${items.length} items for order #${orderId}`);

    // Xử lý và trả về thông tin sản phẩm
    const processedItems = items.map(item => {
      // Chuyển đổi dữ liệu từ MySQL sang JSON
      const processedItem = { ...item };

      // Xử lý đường dẫn ảnh
      if (processedItem.image_path) {
        // Đảm bảo đường dẫn ảnh không bắt đầu bằng '/'
        processedItem.image_path = processedItem.image_path.startsWith('/')
          ? processedItem.image_path.substring(1)
          : processedItem.image_path;

        // Thêm trường ImagePath để tương thích với frontend
        processedItem.ImagePath = processedItem.image_path;
      }

      // Log thông tin sản phẩm để debug
      console.log(`Product in order #${orderId}: ${processedItem.product_name || processedItem.name}, image: ${processedItem.image_path || 'none'}`);

      return processedItem;
    });

    res.json(processedItems);
  } catch (error) {
    console.error('Error getting order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});
/*--------------------------------------
Update  user profile
-----------------------------------------*/
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
/*---------------------------------------- 
------------------------------------------*/
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

/*---------------------------------
- Api notification
-----------------------------------*/
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
/*-------------------------------------
--------------------------------------*/
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

/*
---------------------------------
- Api chat ( user)
-----------------------------------*/

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
/*--------------------------------------
Lấy các mục trong đơn hàng Api
order_History
---------------------------------------*/

app.get('/api/orders/:id/items', async (req, res) => {
  try {
    const orderId = req.params.id;
    /*---------------------------------------
    -----------------------------------------*/
    // Lấy các mục trong đơn hàng
    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );
    // Đảm bảo đường dẫn ảnh đầy đủ
    const itemsWithFullImagePath = items.map(item => {
      // Nếu có image_path, đảm bảo nó không bắt đầu bằng '/'
      if (item.image_path) {
        item.image_path = item.image_path.startsWith('/')
          ? item.image_path.substring(1)
          : item.image_path;
      }
      return item;
    });

    res.json({
      status: 'success',
      data: itemsWithFullImagePath
    });
  } catch (error) {
    console.error('Error getting order items:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// API lấy lịch sử giao dịch
app.get('/api/wallet/transactions/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log(`Getting wallet transactions for user ${userId}`);

    // Lấy lịch sử giao dịch
    const [transactions] = await pool.query(
      `SELECT * FROM wallet_transactions 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );

    // Chuyển đổi amount từ String sang Number
    const formattedTransactions = transactions.map(transaction => {
      return {
        ...transaction,
        amount: parseFloat(transaction.amount)
      };
    });

    console.log(`Found ${transactions.length} transactions for user ${userId}`);
    return res.json({ transactions: formattedTransactions });
  } catch (error) {
    console.error('Error getting wallet transactions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API tạo yêu cầu nạp tiền
app.post('/api/wallet/topup', async (req, res) => {
  try {
    console.log('Received top-up request:', req.body);
    const { user_id, amount, payment_method } = req.body;

    if (!user_id || !amount || !payment_method) {
      console.log('Missing required fields:', { user_id, amount, payment_method });
      return res.status(400).json({ status: 'error', message: 'Missing required fields' });
    }

    // Tạo yêu cầu nạp tiền với trạng thái 'pending'
    const [result] = await pool.query(
      `INSERT INTO wallet_topups 
       (user_id, amount, payment_method, status, created_at) 
       VALUES (?, ?, ?, 'pending', NOW())`,
      [user_id, amount, payment_method]
    );

    console.log(`Created top-up request with ID ${result.insertId}`);

    // Tạo giao dịch ví với trạng thái 'pending'
    await pool.query(
      `INSERT INTO wallet_transactions 
       (user_id, amount, type, status, reference_id, created_at) 
       VALUES (?, ?, 'top_up', 'pending', ?, NOW())`,
      [user_id, amount, result.insertId]
    );

    return res.status(201).json({
      status: 'success',
      message: 'Top-up request created successfully',
      request_id: result.insertId
    });
  } catch (error) {
    console.error('Error creating top-up request:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// API lấy danh sách yêu cầu nạp tiền (cho admin)
app.get('/api/admin/wallet/topups', async (req, res) => {
  try {
    const filter = req.query.filter || 'all';
    console.log(`Getting top-up requests with filter: ${filter}`);

    let query = `
      SELECT t.*, u.name as user_name 
      FROM wallet_topups t
      LEFT JOIN users u ON t.user_id = u.id
    `;

    // Lọc theo trạng thái
    if (filter !== 'all') {
      query += ` WHERE t.status = '${filter}'`;
    }

    query += ` ORDER BY t.created_at DESC`;

    const [topups] = await pool.query(query);
    console.log(`Found ${topups.length} top-up requests with filter: ${filter}`);

    // Chuyển đổi amount từ String sang Number
    const formattedTopups = topups.map(topup => {
      return {
        ...topup,
        amount: parseFloat(topup.amount)
      };
    });

    return res.json({ topups: formattedTopups });
  } catch (error) {
    console.error('Error getting top-up requests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API xác nhận yêu cầu nạp tiền (cho admin)
app.post('/api/admin/wallet/topups/:id/approve', async (req, res) => {
  try {
    const topupId = req.params.id;
    console.log(`Approving top-up request with ID: ${topupId}`);

    // Lấy thông tin yêu cầu nạp tiền
    const [topupRows] = await pool.query(
      'SELECT * FROM wallet_topups WHERE id = ?',
      [topupId]
    );

    if (topupRows.length === 0) {
      return res.status(404).json({ error: 'Top-up request not found' });
    }

    const topup = topupRows[0];

    // Kiểm tra xem yêu cầu đã được xử lý chưa
    if (topup.status !== 'pending') {
      return res.status(400).json({
        error: 'This top-up request has already been processed'
      });
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Cập nhật trạng thái yêu cầu nạp tiền
      await connection.query(
        'UPDATE wallet_topups SET status = "completed", updated_at = NOW() WHERE id = ?',
        [topupId]
      );

      // Cập nhật trạng thái giao dịch ví
      await connection.query(
        'UPDATE wallet_transactions SET status = "completed", updated_at = NOW() WHERE reference_id = ? AND type = "top_up"',
        [topupId]
      );

      // Cập nhật số dư ví
      await connection.query(
        'UPDATE wallets SET balance = balance + ? WHERE user_id = ?',
        [topup.amount, topup.user_id]
      );

      await connection.commit();
      console.log(`Top-up request ${topupId} approved successfully`);

      return res.json({
        status: 'success',
        message: 'Top-up request approved successfully'
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error approving top-up request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API từ chối yêu cầu nạp tiền (cho admin)
app.post('/api/admin/wallet/topups/:id/reject', async (req, res) => {
  try {
    const topupId = req.params.id;
    console.log(`Rejecting top-up request with ID: ${topupId}`);

    // Lấy thông tin yêu cầu nạp tiền
    const [topupRows] = await pool.query(
      'SELECT * FROM wallet_topups WHERE id = ?',
      [topupId]
    );

    if (topupRows.length === 0) {
      return res.status(404).json({ error: 'Top-up request not found' });
    }

    const topup = topupRows[0];

    // Kiểm tra xem yêu cầu đã được xử lý chưa
    if (topup.status !== 'pending') {
      return res.status(400).json({
        error: 'This top-up request has already been processed'
      });
    }

    // Bắt đầu transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Cập nhật trạng thái yêu cầu nạp tiền
      await connection.query(
        'UPDATE wallet_topups SET status = "rejected", updated_at = NOW() WHERE id = ?',
        [topupId]
      );

      // Cập nhật trạng thái giao dịch ví
      await connection.query(
        'UPDATE wallet_transactions SET status = "rejected", updated_at = NOW() WHERE reference_id = ? AND type = "top_up"',
        [topupId]
      );

      await connection.commit();
      console.log(`Top-up request ${topupId} rejected successfully`);

      return res.json({
        status: 'success',
        message: 'Top-up request rejected successfully'
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error rejecting top-up request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Kiểm tra xem route này đã được định nghĩa chưa
app.get('/api/wallet/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log(`Getting wallet balance for user ${userId}`);

    // Kiểm tra xem ví đã tồn tại chưa
    const [walletRows] = await pool.query(
      'SELECT * FROM wallets WHERE user_id = ?',
      [userId]
    );

    // Nếu ví chưa tồn tại, tạo ví mới với số dư 0
    if (walletRows.length === 0) {
      console.log(`Creating new wallet for user ${userId}`);
      await pool.query(
        'INSERT INTO wallets (user_id, balance) VALUES (?, 0)',
        [userId]
      );

      return res.json({ balance: 0 });
    }

    console.log(`Wallet found for user ${userId}, balance: ${walletRows[0].balance}`);
    // Trả về số dư ví dưới dạng số, không phải chuỗi
    return res.json({ balance: parseFloat(walletRows[0].balance) });
  } catch (error) {
    console.error('Error getting wallet balance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Khi lấy danh sách sản phẩm
app.get('/api/products', async (req, res) => {
  try {
    const [products] = await pool.query('SELECT * FROM products');

    // Đảm bảo giá được trả về dưới dạng số
    const formattedProducts = products.map(product => {
      return {
        ...product,
        price: parseFloat(product.price)
      };
    });

    res.json({
      status: 'success',
      data: formattedProducts
    });
  } catch (error) {
    console.error('Error getting products:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});









