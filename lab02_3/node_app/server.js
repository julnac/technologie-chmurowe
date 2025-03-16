const express = require('express');
const mongoose = require('mongoose');
const app = express();
const port = 8080;
const mongoUri = "mongodb://host.docker.internal:27017/testdb";

mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log("Connected to MongoDB"))
  .catch(err => console.error("MongoDB connection error:", err));

const dataSchema = new mongoose.Schema({ message: String });
const DataModel = mongoose.model("Data", dataSchema);

async function seedDatabase() {
  const count = await DataModel.countDocuments();
  if (count === 0) {
    await DataModel.create({ message: "Hello from MongoDB" });
    console.log("Inserted initial data into MongoDB");
  }
}

seedDatabase();

app.get('/', async (req, res) => {
  try {
    const data = await DataModel.find();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log();
});
