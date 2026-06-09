const router = require('express').Router();
const Level = require('../models/Level');

// Solo lectura — GET /levels
router.get('/', async (req, res) => {
    try {
        const levels = await Level.find().sort({ level_number: 1 });
        res.json(levels);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;