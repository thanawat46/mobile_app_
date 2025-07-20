import mysql from 'mysql2/promise';

const pool = await mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '1101',
  database: 'deposit_fund',
  port: 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

export default pool;
