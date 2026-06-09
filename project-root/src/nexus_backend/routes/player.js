const router = require('express').Router();
const Player = require('../models/Player');

// GET /player/:id — map_screen (paso 2)
router.get('/:id', async (req, res) => {
    try {
        const p = await Player.findById(req.params.id);
        if (!p) return res.status(404).json({ error: 'Jugador no encontrado' });
        res.json({
            username: p.username,
            current_level: p.current_level,
            max_level_reached: p.max_level_reached,
            totalKeys: p.totalKeys,
            xp: p.xp,
            stats: p.stats,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PATCH /player/level — al ganar un nivel (US-TF-3-1, RF-04)
router.patch('/level', async (req, res) => {
    try {
        const { playerId, nivelCompletado, xpGanado, nuevaLlave } = req.body;

        const jugador = await Player.findById(playerId);

        // Verifica si ya completó este nivel antes
        const yaCompletado = jugador.max_level_reached > nivelCompletado;

        const update = {
            $inc: { xp: xpGanado },
            $max: { max_level_reached: nivelCompletado + 1 },
            $set: { current_level: nivelCompletado + 1 },
        };

        // Solo da llave si es la primera vez que completa este nivel
        if (nuevaLlave && !yaCompletado) {
            update.$inc.totalKeys = 1;
        }

        const p = await Player.findByIdAndUpdate(playerId, update, { new: true });
        res.json({
            max_level_reached: p.max_level_reached,
            xp: p.xp,
            totalKeys: p.totalKeys,
            llaveOtorgada: nuevaLlave && !yaCompletado,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PATCH /player/reset-hp — reinicia HP al entrar a un nivel
router.patch('/reset-hp', async (req, res) => {
    try {
        const { playerId, hp } = req.body;
        // Si mandan un hp específico lo usa, si no resetea a 100
        const newHp = (hp !== undefined) ? Math.min(Math.max(hp, 0), 100) : 100;
        const p = await Player.findByIdAndUpdate(
            playerId,
            { $set: { 'stats.hp': newHp } },
            { returnDocument: 'after' }
        );
        if (!p) return res.status(404).json({ error: 'Jugador no encontrado' });
        res.json({ hp: p.stats.hp });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
module.exports = router;