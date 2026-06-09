const router = require('express').Router();
const Player = require('../models/Player');

// GET /inventory/:playerId — inventory_screen carga los ítems reales
router.get('/:playerId', async (req, res) => {
    try {
        const p = await Player.findById(req.params.playerId);
        if (!p) return res.status(404).json({ error: 'Jugador no encontrado' });
        res.json(p.inventory);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /inventory/item — recoger ítem ($push · US-TF-2-1)
router.post('/item', async (req, res) => {
    try {
        const { playerId, item } = req.body;
        const jugador = await Player.findById(playerId);

        // ← Límite de 30 ítems (backlog Technical Notes)
        if (jugador.inventory.length >= 30) {
            return res.status(400).json({
                error: 'Inventory full. Maximum 30 items allowed.'
            });
        }

        const p = await Player.findByIdAndUpdate(
            playerId,
            { $push: { inventory: item } },
            { returnDocument: 'after', runValidators: true }  // ← fix warning
        );
        res.json(p.inventory);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// DELETE /inventory/:playerId/:itemId — usar/borrar ítem ($pull · US-TF-2-2)
// DELETE /inventory/:playerId/:itemId
router.delete('/:playerId/:itemId', async (req, res) => {
    try {
        const { playerId, itemId } = req.params;
        const jugador = await Player.findById(playerId);
        const item = jugador?.inventory.id(itemId);
        const healAmount = item?.stats?.heal ?? 0;

        // ❌ Solo bloquea si ES una poción de curación y el HP ya está lleno
        if (healAmount > 0 && jugador.stats.hp >= 100) {
            return res.status(400).json({ error: 'Your health is already full.' });
        }

        // Si no cura, newHp se queda igual
        const newHp = healAmount > 0
            ? Math.min(jugador.stats.hp + healAmount, 100)
            : jugador.stats.hp;

        const p = await Player.findByIdAndUpdate(
            playerId,
            {
                $pull: { inventory: { _id: itemId } },
                $set: { 'stats.hp': newHp },
            },
            { returnDocument: 'after' }
        );

        res.json({
            inventory: p.inventory,
            newHp: p.stats.hp,
            healed: newHp - jugador.stats.hp,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
module.exports = router;