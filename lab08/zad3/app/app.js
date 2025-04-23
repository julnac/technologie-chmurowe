const express = require('express');
const redis = require('redis');
const { Pool } = require('pg');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Redis client
const redisClient = redis.createClient({
  socket: {
    host: 'redis',
    port: 6379
  }
});
redisClient.connect().catch(console.error);

// PostgreSQL client
const pool = new Pool({
  user: 'postgres',
  host: 'postgres',
  database: 'usersdb',
  password: 'postgrespw',
  port: 5432
});

// Tworzenie tabeli users (jeśli nie istnieje)
pool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
  )
`).catch(console.error);

// Redis endpoints
app.post('/message', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: 'Message is required' });
  await redisClient.rPush('messages', message);
  res.status(201).json({ status: 'Message added' });
});

app.get('/messages', async (req, res) => {
  const messages = await redisClient.lRange('messages', 0, -1);
  res.json({ messages });
});

// PostgreSQL endpoints
app.post('/user', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Name is required' });
  await pool.query('INSERT INTO users(name) VALUES($1)', [name]);
  res.status(201).json({ status: 'User added' });
});

app.get('/users', async (req, res) => {
  const result = await pool.query('SELECT * FROM users');
  res.json({ users: result.rows });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
