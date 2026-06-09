const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Conexión a Atlas
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('✅ Atlas conectado'))
    .catch(err => console.error('❌ Error:', err));

// Rutas
app.use('/auth', require('./routes/auth'));
app.use('/player', require('./routes/player'));
app.use('/inventory', require('./routes/inventory'));
app.use('/levels', require('./routes/levels'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 API corriendo en puerto ${PORT}`));

module.exports = app;