import express from 'express';
import cors from 'cors';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import bodyParser from 'body-parser';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import pool from './db.js'; // ✅ ต้องใส่ .js ด้วย

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
// app.use('/images', express.static(path.join(__dirname, 'images')));


// ✅ 1. ต้องวางไว้บนสุดก่อน /loan/:id
app.get('/loan/payments', async (req, res) => {
  const status = req.query.status;

  try {
    const [rows] = await pool.query(
      `SELECT * FROM loan_payments WHERE status = ?`,
      [status]
    );
    res.json(rows);
  } catch (err) {
    console.error("Error fetching payments:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// ✅ 2. อันนี้ต้องวางไว้ล่าง
app.get('/loan/payments', async (req, res) => {
  const { status, id_user } = req.query;

  try {
    const [rows] = await pool.query(
      `SELECT * FROM loan_payments WHERE status = ? AND id_user = ?`,
      [status, id_user]
    );
    res.json(rows);
  } catch (err) {
    console.error("Error fetching payments:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ POST /loan/approve
// POST /loan/approve
app.post('/loan/approve', async (req, res) => {
  const { id_payment, status } = req.body;

  try {
    // 1. ดึงข้อมูล payment จาก id_payment
    const [paymentRows] = await pool.query(
      `SELECT id_user, amount FROM loan_payments WHERE id_payment = ?`,
      [id_payment]
    );

    if (paymentRows.length === 0) {
      return res.status(404).json({ message: "ไม่พบข้อมูลการชำระเงิน" });
    }

    const { id_user, amount } = paymentRows[0];

    // 2. อัปเดตสถานะใน loan_payments
    await pool.query(
      `UPDATE loan_payments SET status = ? WHERE id_payment = ?`,
      [status, id_payment]
    );

    // 3. ถ้าสถานะเป็น S001 (อนุมัติ) → หักยอดใน loan
    if (status === 'S001') {
      await pool.query(
        `UPDATE loan
         SET loan_amount = loan_amount - ?
         WHERE id_user = ? AND id_status = 'S001'`,
        [amount, id_user]
      );
    }

    res.json({ message: "อัปเดตสำเร็จ" });

  } catch (err) {
    console.error("Error updating status:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาดในเซิร์ฟเวอร์" });
  }
});









app.post('/check-id', async (req, res) => {
  const { id_user } = req.body;
  try {
    const [rows] = await pool.query(
      'SELECT * FROM users WHERE id_user = ?',
      [id_user]
    );

    if (rows.length > 0) {
      res.json({ found: true, user: rows[0] });
    } else {
      res.json({ found: false });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// API: เปลี่ยนเบอร์โทร
app.post('/change-phone', async (req, res) => {
  const { id_user, new_phone_number } = req.body;

  try {
    const [result] = await pool.query(
      'UPDATE users SET phone_number = ? WHERE id_user = ?',
      [new_phone_number, id_user]
    );

    if (result.affectedRows > 0) {
      res.json({ success: true, message: 'เปลี่ยนเบอร์โทรเรียบร้อยแล้ว' });
    } else {
      res.json({ success: false, message: 'ไม่พบผู้ใช้งานในระบบ' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Database error' });
  }
});

app.post('/add-phone', async (req, res) => {
  const { id_user, phone_number } = req.body;

  try {
    const [userRows] = await pool.query(
      'SELECT * FROM users WHERE id_user = ?',
      [id_user]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ success: false, message: 'ไม่พบสมาชิก' });
    }

    const user = userRows[0];

    if (user.phone_number) {
      return res.status(400).json({ success: false, message: 'สมาชิกมีเบอร์อยู่แล้ว' });
    }

    await pool.query(
      'UPDATE users SET phone_number = ? WHERE id_user = ?',
      [phone_number, id_user]
    );

    return res.json({ success: true, message: 'เพิ่มเบอร์เรียบร้อยแล้ว' });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Database error' });
  }
});

app.post('/update-phone', async (req, res) => {
  const { id_user, phone_number } = req.body;
  try {
    const [result] = await pool.query(
      'UPDATE users SET phone_number = ? WHERE id_user = ?',
      [phone_number, id_user]
    );
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/check-pin', async (req, res) => {
  const { id_user, pin } = req.body;

  try {
    const sql = 'SELECT * FROM pin_users WHERE id_user = ? AND pin_user = ?';
    const [result] = await pool.query(sql, [id_user, pin]);

    if (result.length > 0) {
      res.json({ success: true });
    } else {
      res.json({ success: false });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/check-has-pin', async (req, res) => {
  const { id_user } = req.body;

  try {
    const sql = 'SELECT * FROM pin_users WHERE id_user = ?';
    const [result] = await pool.query(sql, [id_user]);

    if (result.length > 0) {
      res.json({ hasPin: true });
    } else {
      res.json({ hasPin: false });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/add-pin', async (req, res) => {
  const { id_user, pin_user } = req.body;

  if (!id_user || !pin_user) {
    return res.status(400).json({ success: false, message: 'id_user and pin_user are required' });
  }

  try {
     console.log("Request Data:", req.body);

     const [rows] = await pool.query('SELECT MAX(CAST(id_pin AS UNSIGNED)) AS maxId FROM pin_users');
     const nextId = (rows[0].maxId || 0) + 1;
     const id_pin = nextId.toString().padStart(3, '0');

     const sql = 'INSERT INTO pin_users (id_pin, id_user, pin_user) VALUES (?, ?, ?)';
     const [result] = await pool.query(sql, [id_pin, id_user, pin_user]);

     console.log("Insert Result:", result);

     res.json({ success: true, id_pin: id_pin });
   } catch (err) {
     console.error("DB Error:", err);
     res.status(500).json({ message: 'Internal server error' });
   }
});

app.post('/change-pin', async (req, res) => {
  const { id_user, otp, new_pin } = req.body;

  if (!id_user || !otp || !new_pin) {
    return res.status(400).json({ success: false, message: 'ข้อมูลไม่ครบ' });
  }

  try {
    const [users] = await pool.query('SELECT * FROM pin_users WHERE id_user = ?', [id_user]);
    if (users.length === 0) {
      return res.status(404).json({ success: false, message: 'ไม่พบรหัสสมาชิก' });
    }

    if (otp !== '12345') {
      return res.status(401).json({ success: false, message: 'รหัส OTP ไม่ถูกต้อง' });
    }

    await pool.query('UPDATE pin_users SET pin_user = ? WHERE id_user = ?', [new_pin, id_user]);

    return res.status(200).json({ success: true, message: 'เปลี่ยนรหัส PIN สำเร็จ' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดของเซิร์ฟเวอร์' });
  }
});

app.get('/users/:id_user', async (req, res) => {
  const { id_user } = req.params;

  try {
    const [rows] = await pool.query(`
      SELECT first_name, last_name FROM users WHERE id_user = ?
    `, [id_user]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    console.error("Error fetching user:", err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.get('/deposit/total/:id_user', async (req, res) => {
  const { id_user } = req.params;

  try {
    const [rows] = await pool.query(`
      SELECT IFNULL(SUM(Deposit_amount), 0) AS total_deposit
      FROM deposit
      WHERE id_user = ?
    `, [id_user]);

    res.json({ success: true, total_deposit: rows[0].total_deposit });
  } catch (err) {
    console.error("Error fetching deposit:", err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.get('/deposit/history/:id_user', async (req, res) => {
  const { id_user } = req.params;

  try {
    const [rows] = await pool.query(
      `SELECT da.id_DepositAm, da.date_deposit, da.amount_Deposit, sd.id_status
       FROM deposit_amount da
       JOIN slip_deposit sd ON da.id_DepositAm = sd.id_DepositAm
       WHERE da.id_user = ?
       ORDER BY da.date_deposit DESC`,
      [id_user]
    );

    res.json({
      success: true,
      deposits: rows
    });
  } catch (err) {
    console.error("Error fetching deposit history:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

app.post('/deposit/DepositMonth', async (req, res) => {
  const { idDepositAm } = req.body;

  if (!idDepositAm) {
    return res.status(400).json({ success: false, message: "idDepositAm is required" });
  }

  try {
    const [rows] = await pool.query(
      `SELECT Deposit_month FROM deposit_amount WHERE id_DepositAm = ?`,
      [idDepositAm]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "ไม่พบข้อมูลการฝาก" });
    }

    const depositMonthJson = rows[0].Deposit_month;

    let parsed;
    try {
      parsed = typeof depositMonthJson === 'string'
        ? JSON.parse(depositMonthJson)
        : depositMonthJson;
    } catch (e) {
      return res.status(500).json({ success: false, message: "ไม่สามารถแปลง JSON ได้" });
    }

    return res.json({ success: true, Deposit_month: parsed });
  } catch (error) {
    console.error("Error in /deposit/DepositMonth:", error);
    return res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในเซิร์ฟเวอร์" });
  }
});

app.get("/Profile/users/:id", async (req, res) => {
  const userId = req.params.id;

  const sql = `
    SELECT
      u.id_user,
      u.profile_image,
      p.preName AS pre_name,
      u.first_name,
      u.last_name,
      u.address,
      u.phone_number,
      u.role,
      pu.pin_user
    FROM users u
    LEFT JOIN pre_name p ON u.pre_name = p.id_preName
    LEFT JOIN pin_users pu ON u.id_user = pu.id_user
    WHERE u.id_user = ?
  `;

  try {
    const [rows] = await pool.query(sql, [userId]);

    if (rows.length === 0) {
      return res.status(404).json({ message: "ไม่พบผู้ใช้" });
    }

    res.json({
      message: "พบผู้ใช้งาน",
      data: rows[0]
    });

  } catch (err) {
    res.status(500).json({ error: "ข้อผิดพลาดของฐานข้อมูล", details: err });
  }
});

app.post("/users/profile-image", async (req, res) => {
  const { id_user, profile_image } = req.body;

  if (!id_user || !profile_image) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const [result] = await pool.execute(
      "UPDATE users SET profile_image = ? WHERE id_user = ?",
      [profile_image, id_user]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ message: "Profile image updated successfully" });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

app.post('/deposit-month', async (req, res) => {
  const { id_user, date_deposit, Deposit_month } = req.body;

  if (!id_user || !date_deposit || !Deposit_month) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const formattedDate = new Date(date_deposit).toISOString().slice(0, 19).replace('T', ' ');
  const insertQuery = 'INSERT INTO deposit_amount (id_user, date_deposit, Deposit_month) VALUES (?, ?, ?)';
  const insertValues = [id_user, formattedDate, JSON.stringify(Deposit_month)];

  try {
    const [insertResult] = await pool.execute(insertQuery, insertValues);

    if (insertResult.affectedRows > 0) {
      const selectQuery = `
        SELECT id_DepositAm
        FROM deposit_amount
        WHERE id_user = ? AND date_deposit = ?
        ORDER BY id_DepositAm DESC
        LIMIT 1
      `;
      const [rows] = await pool.execute(selectQuery, [id_user, formattedDate]);

      const idDepositAm = rows.length > 0 ? rows[0].id_DepositAm : null;

      res.status(200).json({
        message: 'Deposit successful',
        data: {
          idDepositAm,
        },
      });
    } else {
      res.status(400).json({ message: 'Failed to insert deposit' });
    }
  } catch (err) {
    console.error('Error inserting deposit:', err.message);
    res.status(500).json({ message: 'Failed to deposit' });
  }
});

app.post('/upload-slip', async (req, res) => {
  const {
    id_user,
    image_slip,
    id_DepositAm,
    slip_number,
    amount_slip,
    data_slip
  } = req.body;

  const parsedAmount = parseFloat(
    typeof amount_slip === 'string'
      ? amount_slip.replace(/,/g, '').trim()
      : amount_slip
  );

  if (!id_user || !image_slip || !id_DepositAm || isNaN(parsedAmount)) {
    return res.status(400).json({ message: 'Missing or invalid required fields' });
  }

  try {
    const [duplicateCheck] = await pool.execute(
      `SELECT * FROM slip_deposit WHERE slip_number = ? OR data_slip = ?`,
      [slip_number, data_slip]
    );

    if (duplicateCheck.length > 0) {
      return res.status(409).json({ message: 'สลิปนี้ถูกใช้งานแล้ว' });
    }

    const insertQuery = `
      INSERT INTO slip_deposit
        (date, id_user, image_slip, slip_number, amount_slip, data_slip, id_status, id_Committee, id_DepositAm)
      VALUES
        (NOW(), ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const values = [
      id_user,
      image_slip,
      slip_number,
      parsedAmount,
      data_slip,
      'S002',
      null,
      id_DepositAm
    ];

    const [result] = await pool.execute(insertQuery, values);
    if (result.affectedRows > 0) {
      res.status(200).json({ message: 'Slip uploaded successfully' });
    } else {
      res.status(400).json({ message: 'Failed to upload slip' });
    }
  } catch (err) {
    console.error('Error uploading slip:', err.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/deposit-amount/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await pool.execute(
      'DELETE FROM deposit_amount WHERE id_DepositAm = ?',
      [id]
    );
    if (result.affectedRows > 0) {
      res.status(200).json({ message: 'ลบข้อมูลฝากเรียบร้อยแล้ว' });
    } else {
      res.status(404).json({ message: 'ไม่พบข้อมูล' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'ลบข้อมูลไม่สำเร็จ' });
  }
});

app.post('/check-slip-duplicate', async (req, res) => {
  const { slip_number, data_slip } = req.body;
  if (!slip_number || !data_slip) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const checkQuery = `
    SELECT COUNT(*) AS count FROM slip_deposit
    WHERE slip_number = ? OR data_slip = ?
  `;

  try {
    const [rows] = await pool.execute(checkQuery, [slip_number, data_slip]);
    const isDuplicate = rows[0].count > 0;
    res.status(200).json({ duplicate: isDuplicate });
  } catch (err) {
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/deposit-history', async (req, res) => {
  const { id_user } = req.query;

  if (!id_user) {
    return res.status(400).json({ message: 'Missing id_user' });
  }

  try {
    const [rows] = await pool.execute(
      `SELECT da.id_DepositAm, da.date_deposit, da.amount_Deposit,
              sd.id_status, st.status_name
       FROM deposit_amount da
       LEFT JOIN slip_deposit sd ON da.id_DepositAm = sd.id_DepositAm
       LEFT JOIN status st ON sd.id_status = st.id_status
       WHERE da.id_user = ?
       ORDER BY da.date_deposit DESC`,
      [id_user]
    );

    res.status(200).json({ data: rows });
  } catch (err) {
    console.error('Error fetching deposit history:', err.message);
    res.status(500).json({ message: 'Failed to fetch deposit history' });
  }
});


app.get('/getslips', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT
        s.id_slip,
        s.date,
        s.id_user,
        u.first_name,
        u.last_name,
        s.id_status,
        st.status_name
      FROM slip_deposit s
      JOIN users u ON s.id_user = u.id_user
      JOIN status st ON s.id_status = st.id_status
    `);

    res.json(rows);
  } catch (err) {
    console.error('Error fetching slips:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/getslips-Details', async (req, res) => {
  const idSlip = req.query.id_slip;

  const sql = `
    SELECT
      sd.id_slip,
      sd.date,
      u.first_name,
      u.last_name,
      sd.image_slip,
      sd.slip_number,
      sd.amount_slip,
      sd.id_status,
      s.status_name
    FROM slip_deposit sd
    JOIN users u ON sd.id_user = u.id_user
    JOIN status s ON sd.id_status = s.id_status
    WHERE sd.id_slip = ?
  `;

  try {
    const [results] = await pool.execute(sql, [idSlip]);

    if (results.length === 0) {
      return res.status(404).json({ error: 'Slip not found' });
    }

    const slip = results[0];

    res.json({
      ...slip,
      image_url: slip.image_slip,
    });
  } catch (err) {
    console.error('DB error:', err);
    res.status(500).json({ error: 'Database query failed' });
  }
});

app.post('/update-slip-status', async (req, res) => {
  const { id_slip, new_status } = req.body;

  const sql = `
    UPDATE slip_deposit
    SET id_status = ?
    WHERE id_slip = ?
  `;

  try {
    const [result] = await pool.execute(sql, [new_status, id_slip]);
    res.json({ success: true, affectedRows: result.affectedRows });
  } catch (err) {
    console.error("Update status error:", err);
    res.status(500).json({ error: "Failed to update status" });
  }
});


app.get('/users', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id_user, first_name, last_name, address FROM users`
    );
    res.json({ success: true, users: rows });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});


app.get('/users_data/:id', async (req, res) => {
  const id = req.params.id;
  try {
    const [rows] = await pool.query(
      `SELECT
         u.id_user,
         p.preName AS pre_name,
         u.first_name,
         u.last_name,
         u.role,
         u.address,
         u.phone_number,
         d.id_deposit,
         d.date_deposit,
         d.Deposit_amount
       FROM users u
       LEFT JOIN pre_name p ON u.pre_name = p.id_preName
       LEFT JOIN deposit d ON u.id_user = d.id_user
       WHERE u.id_user = ?`,
      [id]
    );

    if (rows.length > 0) {
      // รวมหลายรายการ deposit ไว้ใน array
      const user = {
        id_user: rows[0].id_user,
        pre_name: rows[0].pre_name,
        first_name: rows[0].first_name,
        last_name: rows[0].last_name,
        role: rows[0].role,
        address: rows[0].address,
        phone_number: rows[0].phone_number,
        deposits: rows
          .filter(r => r.id_deposit !== null)
          .map(r => ({
            id_deposit: r.id_deposit,
            date_deposit: r.date_deposit,
            deposit_amount: r.Deposit_amount
          }))
      };

      res.json({ success: true, user });
    } else {
      res.status(404).json({ success: false, message: 'User not found' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.delete('/users/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM users WHERE id_user = ?', [id]);
    res.json({ success: true, message: 'User deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.post('/add-users', async (req, res) => {
  try {
    const {
      pre_name_text,
      first_name,
      last_name,
      address,
      phone_number,
      deposit_amount
    } = req.body;

    const [preNameResult] = await pool.query(
      'SELECT id_preName FROM pre_name WHERE preName = ?',
      [pre_name_text]
    );

    if (preNameResult.length === 0) {
      return res.status(400).json({ error: 'คำนำหน้าไม่ถูกต้อง' });
    }

    const id_preName = preNameResult[0].id_preName;

    const [latest] = await pool.query(
      'SELECT id_user FROM users ORDER BY CAST(id_user AS UNSIGNED) DESC LIMIT 1'
    );

    let newId = '001';
    if (latest.length > 0) {
      const lastNum = parseInt(latest[0].id_user, 10) + 1;
      newId = lastNum.toString().padStart(3, '0');
    }

    // เพิ่มผู้ใช้
    await pool.query(
      'INSERT INTO users (id_user, pre_name, first_name, last_name, address, phone_number, role) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [newId, id_preName, first_name, last_name, address, phone_number, 'user']
    );

    // เพิ่มเงินฝากเริ่มต้น (ถ้ามี)
    if (deposit_amount && deposit_amount > 0) {
      const now = new Date();
      await pool.query(
        'INSERT INTO deposit (id_user, date_deposit, Deposit_amount) VALUES (?, ?, ?)',
        [newId, now, deposit_amount]
      );
    }

    res.status(201).json({ message: 'เพิ่มผู้ใช้เรียบร้อย', id_user: newId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'เกิดข้อผิดพลาดในระบบ' });
  }
});

app.get('/account', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT year_ad, SUM(amount_ad) AS total_amount
      FROM account_deposit
      GROUP BY year_ad
      ORDER BY year_ad DESC
    `);

    const total = rows.reduce((sum, row) => sum + row.total_amount, 0);

    res.json({
      total,
      yearly: rows
    });
  } catch (error) {
    console.error('Error fetching summary:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get("/announcements", async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        id_announcement,
        image_url,
        description,
        created_at
      FROM announcements
      ORDER BY created_at DESC
    `);

    res.status(200).json({
      message: "ดึงข้อมูลประกาศสำเร็จ",
      data: rows
    });
  } catch (err) {
    console.error("Error fetching announcements:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาด", error: err });
  }
});

app.post("/announcements-add", async (req, res) => {
  const { image_url, description } = req.body;

  if (!image_url || !description) {
    return res.status(400).json({ message: "กรุณาระบุข้อมูลให้ครบถ้วน" });
  }

  try {
    const [result] = await pool.execute(
      `INSERT INTO announcements (image_url, description, created_at)
       VALUES (?, ?, NOW())`,
      [image_url, description]
    );

    res.status(201).json({
      message: "เพิ่มประกาศเรียบร้อยแล้ว",
      id_announcement: result.insertId
    });
  } catch (err) {
    console.error("Error adding announcement:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาด", error: err });
  }
});

app.get('/loan', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        l.id_loan,
        l.id_user,
        l.loan_amount,
        l.Payment_Due_Date,
        u.first_name,
        u.last_name
      FROM loan l
      JOIN users u ON l.id_user = u.id_user
      ORDER BY l.Payment_Due_Date ASC
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error", details: err });
  }
});

app.delete('/loan-full/:id_loan', async (req, res) => {
  const { id_loan } = req.params;

  try {
    // 1. หาคำขอกู้ที่เกี่ยวข้อง
    const [result] = await pool.query(
      'SELECT id_loanReq FROM loan WHERE id_loan = ?',
      [id_loan]
    );

    if (result.length === 0) {
      return res.status(404).json({ message: 'ไม่พบ loan ที่ต้องการลบ' });
    }

    const id_loanReq = result[0].id_loanReq;

    // 2. ลบจาก loan
    await pool.query('DELETE FROM loan WHERE id_loan = ?', [id_loan]);

    // 3. ลบจาก loan_requests
    await pool.query('DELETE FROM loan_requests WHERE id_loanReq = ?', [id_loanReq]);

    res.json({ success: true, message: 'ลบสำเร็จทั้ง loan และ loan_requests' });
  } catch (err) {
    console.error('❌ DELETE loan-full error:', err);
    res.status(500).json({ success: false, error: 'เกิดข้อผิดพลาดในการลบ' });
  }
});
app.put('/loan/update-amount', async (req, res) => {
  const { id_loan, loan_amount } = req.body;

  try {
    const [loanRows] = await pool.query("SELECT id_loanReq FROM loan WHERE id_loan = ?", [id_loan]);
    if (loanRows.length === 0) {
      return res.status(404).json({ message: "ไม่พบข้อมูล loan" });
    }

    const id_loanReq = loanRows[0].id_loanReq;

    await pool.query("UPDATE loan SET loan_amount = ? WHERE id_loan = ?", [loan_amount, id_loan]);
    await pool.query("UPDATE loan_requests SET loan_amount = ? WHERE id_loanReq = ?", [loan_amount, id_loanReq]);

    res.json({ message: "อัปเดตจำนวนเงินสำเร็จ" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "เกิดข้อผิดพลาดที่เซิร์ฟเวอร์" });
  }
});

app.get('/committee', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT
        c.id_Committee,
        u.first_name,
        u.last_name,
        p.position_name
      FROM committee c
      JOIN users u ON c.id_user = u.id_user
      JOIN position p ON c.position_id = p.id_position
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error loading committee:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.patch('/committee/:id', async (req, res) => {
  const id = req.params.id;
  const { position_id } = req.body;

  if (!position_id) {
    return res.status(400).json({ error: "position_id is required" });
  }

  try {
    const [result] = await pool.execute(
      `UPDATE committee SET position_id = ? WHERE id_Committee = ?`,
      [position_id, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Committee not found" });
    }

    res.json({ message: "Position updated successfully" });
  } catch (error) {
    console.error('Error updating position:', error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post('/loan', async (req, res) => {
  const { id_user, loan_amount, payment_receiving_time } = req.body;
  const year = new Date(payment_receiving_time).getFullYear();

  try {
    // บันทึก loan
    await pool.execute(`INSERT INTO loan (...) VALUES (...)`);

    // ตรวจสอบว่ามีใน summary หรือยัง
    const [rows] = await pool.execute(
      `SELECT * FROM yearly_summary_loan WHERE id_user = ? AND year = ?`,
      [id_user, year]
    );

    if (rows.length > 0) {
      await pool.execute(
        `UPDATE yearly_summary_loan SET total_amount = total_amount + ? WHERE id_user = ? AND year = ?`,
        [loan_amount, id_user, year]
      );
    } else {
      const [count] = await pool.execute(`SELECT COUNT(*) AS c FROM yearly_summary_loan`);
      const newId = `SM${String(count[0].c + 1).padStart(3, '0')}`;

      await pool.execute(
        `INSERT INTO yearly_summary_loan (id_summary, id_user, year, total_amount) VALUES (?, ?, ?, ?)`,
        [newId, id_user, year, loan_amount]
      );
    }

    res.json({ message: 'Loan added and summary updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.get('/yearly-summary-loan', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT id_user, year, total_amount
      FROM yearly_summary_loan
      ORDER BY year DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error("Error loading yearly summary loan:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get('/loan/:id_user', async (req, res) => {
  const { id_user } = req.params;

  try {
    const [balanceResult] = await pool.query(`
      SELECT SUM(loan_amount) AS balance
      FROM loan_requests
      WHERE id_user = ? AND id_status = 'S001'
    `, [id_user]);

    const loan_balance = balanceResult[0].balance || 0;

    const [repayResult] = await pool.query(`
      SELECT id_loan, id_user, Payment_Due_Date, loan_amount
      FROM loan
      WHERE id_user = ?
      ORDER BY Payment_Due_Date;
    `, [id_user]);

    res.json({
      loan_balance,
      repayment_schedule: repayResult
    });
  } catch (err) {
    res.status(500).json({ error: "DB Error", details: err });
  }
});

app.get('/loan-requests', async (req, res) => {
  const sql = `
    SELECT
      lr.id_loanReq,
      lr.id_user,
      lr.loan_amount,
      lr.request_date,
      lr.id_status,
      s.status_name,
      u.first_name,
      u.last_name
    FROM loan_requests lr
    LEFT JOIN status s ON lr.id_status = s.id_status
    LEFT JOIN users u ON lr.id_user = u.id_user
    ORDER BY lr.request_date DESC
  `;

  try {
    const [results] = await pool.query(sql);
    res.json(results);
  } catch (err) {
    console.error("Loan Request Query Error:", err);
    res.status(500).json({ error: "Database error", details: err });
  }
});

app.post("/loan_requests", async (req, res) => {
  const { id_user, loan_amount, notes } = req.body;

  try {
    const [result] = await pool.query("SELECT id_loanReq FROM loan_requests ORDER BY id_loanReq DESC LIMIT 1");

    let nextId = "LR001";
    if (result.length > 0) {
      const lastIdRaw = result[0].id_loanReq;
      const lastId = String(lastIdRaw);
      const match = lastId.match(/^LR(\d+)$/);

      if (match) {
        const numericPart = parseInt(match[1], 10) + 1;
        nextId = "LR" + numericPart.toString().padStart(3, "0");
      }
    }

    const insertQuery = `
      INSERT INTO loan_requests (id_loanReq, id_user, loan_amount, notes, request_date, id_status)
      VALUES (?, ?, ?, ?, NOW(), 'S002')
    `;

    await pool.query(insertQuery, [nextId, id_user, loan_amount, notes]);
    res.status(201).json({ message: "ส่งคำขอกู้เรียบร้อย", id_loanReq: nextId });
  } catch (err) {
    res.status(500).json({ error: "Database error", details: err });
  }
});

app.post('/update-loan-status', async (req, res) => {
  const { id_loanReq, id_status, payment_due_date } = req.body;

  try {
    // 1. ตรวจสอบคำขอกู้
    const [prevResult] = await pool.query(
      'SELECT id_user, id_status, loan_amount FROM loan_requests WHERE id_loanReq = ?',
      [id_loanReq]
    );

    if (prevResult.length === 0) {
      return res.status(404).json({ message: 'ไม่พบคำขอกู้' });
    }

    const { id_user, id_status: oldStatus, loan_amount } = prevResult[0];

    // 2. อัปเดตสถานะ
    await pool.query(
      'UPDATE loan_requests SET id_status = ? WHERE id_loanReq = ?',
      [id_status, id_loanReq]
    );

    // 3. เปลี่ยนเป็น S001 → เพิ่มเข้า loan (ถ้ายังไม่มี)
    if (id_status === 'S001' && oldStatus !== 'S001') {
      const [existingLoan] = await pool.query(
        'SELECT * FROM loan WHERE id_loanReq = ?',
        [id_loanReq]
      );

      if (existingLoan.length === 0) {
        const [lastLoan] = await pool.query(
          'SELECT id_loan FROM loan ORDER BY id_loan DESC LIMIT 1'
        );

        let nextLoanId = 'L001';
        if (lastLoan.length > 0) {
          const match = lastLoan[0].id_loan.match(/^L(\d+)$/);
          if (match) {
            const num = parseInt(match[1]) + 1;
            nextLoanId = 'L' + num.toString().padStart(3, '0');
          }
        }

        if (!payment_due_date) {
          return res.status(400).json({ message: 'กรุณาระบุวันครบกำหนดชำระ (payment_due_date)' });
        }

        await pool.query(
          `INSERT INTO loan (
            id_loan, id_user, loan_amount, Payment_Due_Date, payment_receiving_time, id_loanReq, id_status
          ) VALUES (?, ?, ?, ?, NOW(), ?, ?)`,
          [nextLoanId, id_user, loan_amount, payment_due_date, id_loanReq, id_status]
        );
      }
    }

    // 4. ถ้าเปลี่ยนสถานะ "ออกจาก S001" → ลบ loan เฉพาะของคำขอนี้
    if (oldStatus === 'S001' && id_status !== 'S001') {
      await pool.query(
        'DELETE FROM loan WHERE id_loanReq = ?',
        [id_loanReq]
      );
    }

    res.status(200).json({ message: 'อัปเดตเรียบร้อย' });
  } catch (err) {
    console.error("❌ update-loan-status error:", err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด', details: err });
  }
});

app.get('/users-committee', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      select * from users
    `);
    res.json(rows); // ส่งเป็น array กลับ
  } catch (err) {
    console.error("Error fetching users:", err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.get('/positions', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id_position, position_name FROM position');
    res.json(rows);
  } catch (error) {
    console.error("Error fetching positions:", error);
    res.status(500).json({ message: "Server error" });
  }
});

app.post('/committee/add', async (req, res) => {
  const { user_id, position_id } = req.body;

  if (!user_id || !position_id) {
    return res.status(400).json({ error: "user_id and position_id are required" });
  }

  try {
    const [result] = await pool.execute(
        `INSERT INTO committee (id_user, position_id) VALUES (?, ?)`,
        [user_id, position_id]
    );

    res.status(200).json({
      success: true,
      message: "Committee member added",
      insertId: result.insertId
    });
  } catch (error) {
    console.error("Error adding committee member:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post('/positions-add', async (req, res) => {
  const { id_position, position_name } = req.body;

  if (!id_position || !position_name) {
    return res.status(400).json({ error: 'กรุณาระบุ id_position และ position_name' });
  }

  try {
    // 🔁 ใส่ backtick รอบชื่อ table
    const [existing] = await pool.query(
      'SELECT * FROM `position` WHERE id_position = ?',
      [id_position]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'id_position นี้มีอยู่แล้ว' });
    }

    // 🔁 ใส่ backtick รอบชื่อ table
    await pool.query(
      'INSERT INTO `position` (id_position, position_name) VALUES (?, ?)',
      [id_position, position_name]
    );

    res.status(201).json({ message: 'เพิ่มตำแหน่งสำเร็จ', id_position });
  } catch (err) {
    res.status(500).json({ error: 'เกิดข้อผิดพลาด: ' + err.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

