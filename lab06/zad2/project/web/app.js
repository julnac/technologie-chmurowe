const express = require('express');
const mysql = require('mysql2');
const app = express();
const port = 3000;

const db = mysql.createConnection({
  host: 'db', // nazwa hosta = nazwa kontenera z MySQL
  user: 'testuser',
  password: 'testpass',
  database: 'testdb'
});

app.get('/', (req, res) => {
  db.query('SELECT NOW() as now', (err, results) => {
    if (err) {
      return res.status(500).send('Błąd połączenia z bazą danych');
    }
    res.send(`Połączenie działa! Czas z DB: ${results[0].now}`);
  });
});

app.listen(port, () => {
  console.log(`Aplikacja działa na porcie ${port}`);
});
