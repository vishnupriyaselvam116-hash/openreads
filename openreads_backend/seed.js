require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

async function seed() {
  try {
    const uri = 'mongodb://openreads:vishnu%402004@ac-vw3lxne-shard-00-00.hrrsjha.mongodb.net:27017,ac-vw3lxne-shard-00-01.hrrsjha.mongodb.net:27017,ac-vw3lxne-shard-00-02.hrrsjha.mongodb.net:27017/openreads?ssl=true&authSource=admin&retryWrites=true&w=majority';
    
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 30000,
      family: 4,
    });
    console.log('✅ Connected to MongoDB Atlas');

    const existing = await User.findOne({ role: 'admin' });

    if (!existing) {
      await User.create({
        name: 'Super Admin',
        email: process.env.ADMIN_EMAIL,
        password: process.env.ADMIN_PASSWORD,
        role: 'admin',
      });
      console.log('✅ Admin created successfully!');
      console.log('   Email   :', process.env.ADMIN_EMAIL);
      console.log('   Password:', process.env.ADMIN_PASSWORD);
    } else {
      console.log('ℹ️  Admin already exists. Skipping.');
    }

    await mongoose.disconnect();
    console.log('✅ Done!');
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

seed();