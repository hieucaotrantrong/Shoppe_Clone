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


    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }


    const userData = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role || 'user',
    };

    res.json({ status: 'success', message: 'Login successful', data: userData });
  } catch (error) {

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


    const [existingUsers] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);

    if (existingUsers.length > 0) {
      return res.status(409).json({ status: 'error', message: 'Email already exists' });
    }


    const hashedPassword = await bcrypt.hash(password, saltRounds);
    /*---------------------------------
    Thêm người dùng mặc didngj là user
    -----------------------------------*/

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

    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});
/*---------------------------------
- Quản lí đơn hàng
-----------------------------------*/
/*---------------------------------
- Create order by (user)
-----------------------------------*/

app.post('/api/orders', async (req, res) => {
  try {
    const { user_id, total_amount, items, payment_method, shipping_address, phone } = req.body;


    if (!user_id || !total_amount || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ status: 'error', message: 'Invalid order data' });
    }


    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {

      if (payment_method === 'wallet') {

        const [walletRows] = await connection.query(
          'SELECT * FROM wallets WHERE user_id = ?',
          [user_id]
        );
        /*---------------------------------
        Nếu ví không tồn tại hoặc số dư không đủ
        -----------------------------------*/
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

        /*---------------------------------
        Trừ tiền từ ví
        -----------------------------------*/
        await connection.query(
          'UPDATE wallets SET balance = balance - ? WHERE user_id = ?',
          [total_amount, user_id]
        );
        /*---------------------------------
                Tạo giao dịch ví
        -----------------------------------*/

        await connection.query(
          `INSERT INTO wallet_transactions 
           (user_id, amount, type, status, description, created_at) 
           VALUES (?, ?, 'payment', 'completed', 'Thanh toán đơn hàng', NOW())`,
          [user_id, total_amount]
        );
      }
      /*---------------------------------
         Tạo đơn hàng với thông tin giao hàng
        -----------------------------------*/
      const [orderResult] = await connection.query(
        'INSERT INTO orders (user_id, total_amount, status, payment_method, shipping_address, phone) VALUES (?, ?, ?, ?, ?, ?)',
        [user_id, total_amount, 'pending', payment_method || 'cod', shipping_address, phone]
      );

      const orderId = orderResult.insertId;
      /*---------------------------------
       Thêm các sản phẩm vào đơn hàng
      -----------------------------------*/

      for (const item of items) {
        await connection.query(
          'INSERT INTO order_items (order_id, product_id, name, price, quantity) VALUES (?, ?, ?, ?, ?)',
          [orderId, item.id, item.name, item.price, item.quantity]
        );
      }


      await connection.commit();
      /*---------------------------------
      Trả về kết quả thành công
      ----------------------------------*/
      return res.status(201).json({
        status: 'success',
        message: 'Order created successfully',
        order_id: orderId,
        payment_method: payment_method || 'cod'
      });
    } catch (error) {

      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {

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
    Lấy thông tin người dùng
    -----------------------------------*/

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
     Kiểm tra mật khẩu hiện tại
    -----------------------------------*/

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

    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    /*---------------------------------
    - Cập nhật mật khẩu
    -----------------------------------*/

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


    const ordersWithItems = await Promise.all(orders.map(async (order) => {
      const [items] = await pool.query(
        'SELECT oi.*, p.name as product_name FROM order_items oi LEFT JOIN products p ON oi.product_id = p.id WHERE oi.order_id = ?',
        [order.id]
      );


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




    const [orderRows] = await pool.query(
      'SELECT o.*, u.name as user_name FROM orders o LEFT JOIN users u ON o.user_id = u.id WHERE o.id = ?',
      [orderId]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({ status: 'error', message: 'Order not found' });
    }

    const order = orderRows[0];

    /*----------------------------------------
    Lấy thông tin sản phẩm trong đơn hàng
    -----------------------------------------*/
    const [orderItems] = await pool.query(
      'SELECT oi.*, p.name as product_name FROM order_items oi LEFT JOIN products p ON oi.product_id = p.id WHERE oi.order_id = ?',
      [orderId]
    );
    /*------------------------------------
    Tạo mô tả sản phẩm cho thông báo
    --------------------------------------*/

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


    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {

      if (status === 'returned') {
        /*-----------------------------------
        Kiểm tra phương thức thanh toán của 
        đơn hàng
        ------------------------------------*/

        if (order.payment_method === 'wallet') {

          const userId = order.user_id;
          const totalAmount = parseFloat(order.total_amount);


          /*-----------------------------------
          Cập nhật số dư ví của người dùng
          -------------------------------------*/

          await connection.query(
            'UPDATE wallets SET balance = balance + ? WHERE user_id = ?',
            [totalAmount, userId]
          );
          /*------------------------------------
          Tạo loại giao dịch ví với loaik payment
          -------------------------------------*/

          await connection.query(
            `INSERT INTO wallet_transactions 
             (user_id, amount, type, status, description, reference_id, created_at) 
             VALUES (?, ?, 'payment', 'completed', ?, ?, NOW())`,
            [userId, totalAmount, `Hoàn tiền đơn hàng ${productText}`, orderId]
          );


        } else {

        }
      }
      /*--------------------------------------------
       Cập nhật trạng thái và lý do trả hàng nếu có
      ----------------------------------------------*/

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
      /*---------------------------------
      Cập nhật thời gian giao hàng 
      nếu trạng thái là delivered
      -----------------------------------*/

      if (status === 'delivered') {
        await connection.query(
          'UPDATE orders SET delivered_at = NOW() WHERE id = ?',
          [orderId]
        );
      }

      await connection.commit();
      /*-------------------------------------------
      Tạo thông báo cho người dùng về việc cập nhật
      trạng thái đơn hàng
      ---------------------------------------------*/

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

      /*-------------------------------
      Create notification if title and 
      message available  
      ---------------------------------*/
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

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
- Lấy tất cả sản phẩm với tùy chọn
 lọc theo danh mục và tìm kiếm
-----------------------------------*/

app.get('/api/products', async (req, res) => {
  try {
    const { category, search } = req.query;



    let query = 'SELECT * FROM products WHERE 1=1';
    const params = [];

    // Lọc theo danh mục nếu được cung cấp
    if (category && category !== 'All') {
      query += ' AND category = ?';
      params.push(category);
    }
    /*---------------------------------
     Tìm kiếm theo tên sản phẩm nếu được cung cấp
    -----------------------------------*/

    if (search && search.trim() !== '') {
      query += ' AND name LIKE ?';
      params.push(`%${search.trim()}%`);

    }

    query += ' ORDER BY id DESC';



    const [rows] = await pool.query(query, params);


    res.json({ status: 'success', data: rows });
  } catch (error) {

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

    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});
/*---------------------------------
- Get all users by admin (admin)
-----------------------------------*/
app.get('/api/users', async (req, res) => {
  try {


    const [rows] = await pool.query(
      'SELECT id, name, email, role, created_at FROM users ORDER BY created_at DESC'
    );



    res.json({ status: 'success', data: rows });
  } catch (error) {

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


    const [existingUsers] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);

    if (existingUsers.length > 0) {
      return res.status(409).json({ status: 'error', message: 'Email already exists' });
    }


    const hashedPassword = await bcrypt.hash(password, saltRounds);


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

    /*---------------------------------
    Kiểm tra người dùng tồn tại 
    -----------------------------------*/
    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }


    if (email !== existingUsers[0].email) {
      const [emailCheck] = await pool.query('SELECT * FROM users WHERE email = ? AND id != ?', [email, userId]);

      if (emailCheck.length > 0) {
        return res.status(409).json({ status: 'error', message: 'Email already exists' });
      }
    }

    let query = 'UPDATE users SET name = ?, email = ? WHERE id = ?';
    let params = [name, email, userId];


    if (password) {
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      query = 'UPDATE users SET name = ?, email = ?, password = ? WHERE id = ?';
      params = [name, email, hashedPassword, userId];
    }


    if (role) {
      query = query.replace('WHERE', ', role = ? WHERE');
      params.splice(params.length - 1, 0, role);
    }


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

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
- Delete all users by admin (admin)
-----------------------------------*/
app.delete('/api/users/:id', async (req, res) => {
  try {
    const userId = req.params.id;


    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }


    if (existingUsers[0].role === 'admin') {
      const [adminCount] = await pool.query('SELECT COUNT(*) as count FROM users WHERE role = "admin"');

      if (adminCount[0].count <= 1) {
        return res.status(400).json({
          status: 'error',
          message: 'Cannot delete the last admin user'
        });
      }
    }


    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    res.json({
      status: 'success',
      message: 'User deleted successfully'
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
- Get all orders by user (user)
-----------------------------------*/

app.get('/users/:id/orders', async (req, res) => {
  try {
    const userId = req.params.id;




    const [orders] = await pool.query(
      `SELECT * FROM orders 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );



    res.json({
      status: 'success',
      data: orders
    });
  } catch (error) {

    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});
/*---------------------------------
 API để lấy các mục trong đơn hàng
-----------------------------------*/

app.get('/orders/:id/items', async (req, res) => {
  try {
    const orderId = req.params.id;


    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name, p.description, p.price as product_price
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );




    const processedItems = items.map(item => {

      const processedItem = { ...item };


      if (processedItem.image_path) {

        processedItem.image_path = processedItem.image_path.startsWith('/')
          ? processedItem.image_path.substring(1)
          : processedItem.image_path;


        processedItem.ImagePath = processedItem.image_path;
      }
      return processedItem;
    });

    res.json(processedItems);
  } catch (error) {

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


    const [existingUsers] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (existingUsers.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }


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


    if (password) {
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      query = 'UPDATE users SET name = ?, email = ?, password = ? WHERE id = ?';
      params = [name, email, hashedPassword, userId];
    }


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

    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});
/*---------------------------------
  Tạo thư mục uploads nếu chưa tồn tại
-----------------------------------*/

const uploadDir = path.join(__dirname, 'uploads');
const profileImagesDir = path.join(uploadDir, 'profile_images');

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

if (!fs.existsSync(profileImagesDir)) {
  fs.mkdirSync(profileImagesDir);
}

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
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: function (req, file, cb) {

    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});


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

    const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);
    if (users.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }


    const relativePath = '/uploads/profile_images/' + req.file.filename;


    await pool.query(
      'UPDATE users SET profile_image = ? WHERE id = ?',
      [relativePath, userId]
    );

    const fullUrl = req.protocol + '://' + req.get('host') + relativePath;

    res.json({
      status: 'success',
      message: 'Profile image uploaded successfully',
      image_url: fullUrl
    });
  } catch (error) {

    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

/*---------------------------------
- API lấy thông báo của người dùng
-----------------------------------*/

app.get('/api/users/:userId/notifications', async (req, res) => {
  try {
    const userId = req.params.userId;


    if (!userId) {
      return res.status(400).json({ status: 'error', message: 'User ID is required' });
    }


    const [notifications] = await pool.query(
      `SELECT id, user_id, title, message, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );



    res.json({
      status: 'success',
      data: notifications
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*-------------------------------------
API đánh dấu thông báo đã đọc
--------------------------------------*/
app.put('/api/notifications/:id/read', async (req, res) => {
  try {
    const notificationId = req.params.id;


    await pool.query(
      'UPDATE notifications SET is_read = 1 WHERE id = ?',
      [notificationId]
    );

    res.json({
      status: 'success',
      message: 'Notification marked as read'
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
 API đánh dấu tất cả thông báo của
  người dùng đã đọc
-----------------------------------*/

app.put('/api/users/:userId/notifications/read-all', async (req, res) => {
  try {
    const userId = req.params.userId;

    await pool.query(
      'UPDATE notifications SET is_read = 1 WHERE user_id = ?',
      [userId]
    );

    res.json({
      status: 'success',
      message: 'All notifications marked as read'
    });
  } catch (error) {

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




    const [messages] = await pool.query(
      `SELECT * FROM chat_messages 
       WHERE user_id = ? 
       ORDER BY created_at ASC`,
      [userId]
    );




    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    res.json({
      status: 'success',
      data: messages
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
 API gửi tin nhắn chat
    -----------------------------------*/

app.post('/api/chat/messages', async (req, res) => {

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



    res.json({
      status: 'success',
      message: 'Message sent successfully',
      data: {
        id: result.insertId
      }
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
 Lấy danh sách người dùng có tin 
 nhắn (cho admin)
-----------------------------------*/
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

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
Đánh dấu tin nhắn đã đọc
 -----------------------------------*/

app.post('/api/chat/mark-read', async (req, res) => {
  try {
    const { userId, sender } = req.body;



    await pool.query(
      'UPDATE chat_messages SET is_read = TRUE WHERE user_id = ? AND sender = ?',
      [userId, sender]
    );


    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    res.json({
      status: 'success',
      message: 'Messages marked as read'
    });
  } catch (error) {

    res.status(500).json({ status: 'error', message: error.message });
  }
});


/*---------------------------------
 API để lấy chi tiết đơn hàng 
-----------------------------------*/
app.get('/api/orders/:id/details', async (req, res) => {
  try {
    const orderId = req.params.id;


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
     Lấy các mục trong đơn hàng
    -----------------------------------------*/

    const [items] = await pool.query(
      `SELECT oi.*, p.image_path, p.name as product_name
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [orderId]
    );

    const itemsWithFullImagePath = items.map(item => {

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

    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});
/*---------------------------------
API lấy lịch sử giao dịch
-----------------------------------*/

app.get('/api/wallet/transactions/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;



    const [transactions] = await pool.query(
      `SELECT * FROM wallet_transactions 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );


    const formattedTransactions = transactions.map(transaction => {
      return {
        ...transaction,
        amount: parseFloat(transaction.amount)
      };
    });


    return res.json({ transactions: formattedTransactions });
  } catch (error) {

    res.status(500).json({ error: 'Internal server error' });
  }
});
/*---------------------------------
  API tạo yêu cầu nạp tiền
-----------------------------------*/

app.post('/api/wallet/topup', async (req, res) => {
  try {

    const { user_id, amount, payment_method } = req.body;

    if (!user_id || !amount || !payment_method) {

      return res.status(400).json({ status: 'error', message: 'Missing required fields' });
    }


    const [result] = await pool.query(
      `INSERT INTO wallet_topups 
       (user_id, amount, payment_method, status, created_at) 
       VALUES (?, ?, ?, 'pending', NOW())`,
      [user_id, amount, payment_method]
    );




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

    res.status(500).json({ status: 'error', message: error.message });
  }
});
/*---------------------------------
  API lấy danh sách yêu cầu nạp tiền
  (cho admin)
-----------------------------------*/

app.get('/api/admin/wallet/topups', async (req, res) => {
  try {
    const filter = req.query.filter || 'all';


    let query = `
      SELECT t.*, u.name as user_name 
      FROM wallet_topups t
      LEFT JOIN users u ON t.user_id = u.id
    `;


    if (filter !== 'all') {
      query += ` WHERE t.status = '${filter}'`;
    }

    query += ` ORDER BY t.created_at DESC`;

    const [topups] = await pool.query(query);



    const formattedTopups = topups.map(topup => {
      return {
        ...topup,
        amount: parseFloat(topup.amount)
      };
    });

    return res.json({ topups: formattedTopups });
  } catch (error) {

    res.status(500).json({ error: 'Internal server error' });
  }
});
/*---------------------------------
API xác nhận yêu cầu nạp tiền (cho admin) 
-----------------------------------*/

app.post('/api/admin/wallet/topups/:id/approve', async (req, res) => {
  try {
    const topupId = req.params.id;



    const [topupRows] = await pool.query(
      'SELECT * FROM wallet_topups WHERE id = ?',
      [topupId]
    );

    if (topupRows.length === 0) {
      return res.status(404).json({ error: 'Top-up request not found' });
    }

    const topup = topupRows[0];


    if (topup.status !== 'pending') {
      return res.status(400).json({
        error: 'This top-up request has already been processed'
      });
    }


    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {

      await connection.query(
        'UPDATE wallet_topups SET status = "completed", updated_at = NOW() WHERE id = ?',
        [topupId]
      );


      await connection.query(
        'UPDATE wallet_transactions SET status = "completed", updated_at = NOW() WHERE reference_id = ? AND type = "top_up"',
        [topupId]
      );


      await connection.query(
        'UPDATE wallets SET balance = balance + ? WHERE user_id = ?',
        [topup.amount, topup.user_id]
      );

      await connection.commit();


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

    res.status(500).json({ error: 'Internal server error' });
  }
});
/*---------------------------------
API từ chối yêu cầu nạp tiền (cho admin)
-----------------------------------*/

app.post('/api/admin/wallet/topups/:id/reject', async (req, res) => {
  try {
    const topupId = req.params.id;


    const [topupRows] = await pool.query(
      'SELECT * FROM wallet_topups WHERE id = ?',
      [topupId]
    );

    if (topupRows.length === 0) {
      return res.status(404).json({ error: 'Top-up request not found' });
    }

    const topup = topupRows[0];


    if (topup.status !== 'pending') {
      return res.status(400).json({
        error: 'This top-up request has already been processed'
      });
    }


    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      /*---------------------------------
      Cập nhật trạng thái yêu cầu nạp tiền
    -----------------------------------*/

      await connection.query(
        'UPDATE wallet_topups SET status = "rejected", updated_at = NOW() WHERE id = ?',
        [topupId]
      );


      await connection.query(
        'UPDATE wallet_transactions SET status = "rejected", updated_at = NOW() WHERE reference_id = ? AND type = "top_up"',
        [topupId]
      );

      await connection.commit();


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

    res.status(500).json({ error: 'Internal server error' });
  }
});

/*---------------------------------
API lấy số dư ví của người dùng
-----------------------------------*/
app.get('/api/wallet/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;



    const [walletRows] = await pool.query(
      'SELECT * FROM wallets WHERE user_id = ?',
      [userId]
    );


    if (walletRows.length === 0) {

      await pool.query(
        'INSERT INTO wallets (user_id, balance) VALUES (?, 0)',
        [userId]
      );

      return res.json({ balance: 0 });
    }



    return res.json({ balance: parseFloat(walletRows[0].balance) });
  } catch (error) {

    res.status(500).json({ error: 'Internal server error' });
  }
});
/*---------------------------------
  Khi lấy danh sách sản phẩm
----------------------------------*/

app.get('/api/products', async (req, res) => {
  try {
    const [products] = await pool.query('SELECT * FROM products');


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

    res.status(500).json({ status: 'error', message: error.message });
  }
});

