const mongoose = require('mongoose');

// ── ESQUEMA DE ÍTEMS (embebido dentro del jugador · RF-06) ──────────────────
const itemSchema = new mongoose.Schema({
    name: { type: String, required: true },
    type: { type: String, enum: ['weapon', 'consumable', 'key', 'shield'], required: true },
    cantidad: { type: Number, default: 1 },
    equipado: { type: Boolean, default: false },
    item_id: { type: String },   // para las llaves (key_01, key_02…)
    stats: {
        type: Object,
        default: {},
        validate: {
            validator: function (stats) {
                if (this.type === 'weapon')
                    // ← agrega damage_bonus para la Hoja Reforzada
                    return ('damage' in stats && 'durability' in stats) ||
                        ('damage' in stats && 'damage_bonus' in stats);
                if (this.type === 'consumable')
                    return 'heal' in stats ||
                        'freeze_turns' in stats ||
                        'damage_bonus' in stats ||
                        'nostalgia' in stats ||
                        'confusion_turns' in stats ||
                        'poison_turns' in stats;
                if (this.type === 'shield')
                    return 'absorcion' in stats;
                return true;
            },
            message: 'Los stats del ítem no son válidos para su tipo.',
        },
    },
    created_at: { type: Date, default: Date.now },
});

// ── ESQUEMA PRINCIPAL DEL JUGADOR ───────────────────────────────────────────
const playerSchema = new mongoose.Schema(
    {
        // RF-01: registro con username único, email y contraseña
        username: { type: String, required: true, unique: true, trim: true },
        email: { type: String, required: true, unique: true, trim: true, lowercase: true },
        password_hash: { type: String, required: true },   // bcrypt · RNF-05

        // RF-04: progreso secuencial de niveles
        current_level: { type: Number, default: 1, min: 1 },
        max_level_reached: { type: Number, default: 1, min: 1 },  // US-TF-3-1
        totalKeys: { type: Number, default: 0, min: 0 },  // sello de Malakor
        xp: { type: Number, default: 0, min: 0 },

        // Estadísticas del jugador (US-TF-2-2: hp se actualiza al usar pociones)
        stats: {
            hp: { type: Number, default: 100, min: 0, max: 100 },
            ataque: { type: Number, default: 10 },
            defensa: { type: Number, default: 5 },
        },

        // RF-06: inventario embebido con esquema flexible
        // RF-07: se gestiona con $push y $pull
        inventory: [itemSchema],
    },
    {
        timestamps: true,  // agrega createdAt y updatedAt automáticamente
    }
);

// ── EXPORTA el modelo ────────────────────────────────────────────────────────
module.exports = mongoose.model('Player', playerSchema);