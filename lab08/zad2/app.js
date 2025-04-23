const express = require('express');
const redis = require('redis');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Redis client
const client = redis.createClient({
  host: 'redis',
  port: 6379,
});

client.on('error', (err) => console.error('Redis error:', err));

app.use(bodyParser.json());

// POST /message - dodaj wiadomość
app.post('/message', (req, res) => {
  const { message } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  client.rpush('messages', message, (err, reply) => {
    if (err) return res.status(500).json({ error: 'Redis error' });
    res.status(201).json({ status: 'Message added', total: reply });
  });
});

// GET /messages - pobierz wszystkie wiadomości
app.get('/messages', (req, res) => {
  client.lrange('messages', 0, -1, (err, messages) => {
    if (err) return res.status(500).json({ error: 'Redis error' });
    res.json({ messages });
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
