require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Root route
app.get('/', (req, res) => {
  res.send('Node.js API is running');
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Database health check
app.get('/health/db', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT NOW() as now');
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      timestamp: rows[0].now
    });
  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Application info
app.get('/api/info', (req, res) => {
  res.json({
    application: 'Node.js AWS Deployment',
    version: '1.0.0',
    hostname: require('os').hostname(),
    uptime: process.uptime()
  });
});

// Get users
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, username, email, created_at FROM users LIMIT 10'
    );

    res.json({
      success: true,
      count: rows.length,
      data: rows
    });

  } catch (error) {
    console.error('Database query error:', error);
    res.status(500).json({
      success: false,
      error: 'Database query failed',
      message: error.message
    });
  }
});

// Create user
app.post('/api/users', async (req, res) => {

  const { username, email } = req.body;

  if (!username || !email) {
    return res.status(400).json({
      success: false,
      error: 'Username and email are required'
    });
  }

  try {

    const [result] = await pool.query(
      'INSERT INTO users (username, email) VALUES (?, ?)',
      [username, email]
    );

    res.status(201).json({
      success: true,
      userId: result.insertId
    });

  } catch (error) {

    console.error('Database insert error:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to create user',
      message: error.message
    });

  }
});

// 404 route
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Database host: ${process.env.DB_HOST}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});