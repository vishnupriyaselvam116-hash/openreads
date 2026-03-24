require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const bookRoutes = require('./routes/books');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/books', bookRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', app: 'OpenReads API' });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

const DIRECT_URI = 'mongodb://openreads:vishnu%402004@ac-vw3lxne-shard-00-00.hrrsjha.mongodb.net:27017,ac-vw3lxne-shard-00-01.hrrsjha.mongodb.net:27017,ac-vw3lxne-shard-00-02.hrrsjha.mongodb.net:27017/openreads?ssl=true&authSource=admin&retryWrites=true&w=majority';

mongoose
  .connect(DIRECT_URI, {
    serverSelectionTimeoutMS: 30000,
    family: 4,
  })
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  });
