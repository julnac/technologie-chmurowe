const express = require('express');
const app = express();
const port = 8080;

app.get('/', (req, res) => {
  res.json({ datetime: new Date().toISOString() });
});

app.listen(port, () => {
  console.log();
});
