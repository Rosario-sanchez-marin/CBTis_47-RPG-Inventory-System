const bcrypt = require('bcryptjs');
const Player = require('../models/Player');
const router = require('express').Router();

// US-TF-1-1: Registro
router.post('/register', async (req, res) => {
    try {
        const { username, email, password } = req.body;

        if (!username || !email || !password) {
            return res.status(400).json({ error: 'Todos los campos son obligatorios.' });
        }

        // ← DECLARA la variable antes de usarla
        const usernameRegex = /^[a-zA-Z0-9]{3,15}$/;
        if (!usernameRegex.test(username.trim())) {
            return res.status(400).json({
                error: 'El nombre de guerrero debe tener entre 3 y 15 caracteres y solo puede contener letras y números.'
            });
        }

        const emailRegex = /^[a-zA-Z0-9._%+-]+@gmail\.com$/;
        if (!emailRegex.test(email.trim())) {
            return res.status(400).json({ error: 'El correo electrónico debe ser una cuenta de Gmail válida (@gmail.com).' });
        }

        // ← DECLARA la variable antes de usarla
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}$/;
        if (!passwordRegex.test(password)) {
            return res.status(400).json({
                error: 'Usa números, letras minúsculas, mayúsculas y caracteres especiales con un mínimo de 8 caracteres.'
            });
        }

        // ← DECLARA y consulta antes de usar
        const existingUsername = await Player.findOne({
            username: { $regex: new RegExp(`^${username.trim()}$`, 'i') }
        });
        if (existingUsername) {
            return res.status(400).json({ error: 'Este nombre de guerrero ya está en uso.' });
        }

        const existingEmail = await Player.findOne({
            email: email.trim().toLowerCase()
        });
        if (existingEmail) {
            return res.status(400).json({ error: 'Este correo electrónico ya está registrado.' });
        }

        const password_hash = await bcrypt.hash(password, 10);
        const jugador = await Player.create({
            username: username.trim(),
            email: email.trim().toLowerCase(),
            password_hash,
            current_level: 1,
            max_level_reached: 1,
            stats: { hp: 100, ataque: 10, defensa: 5 },
            inventory: [
                { name: 'Espada de Hierro', type: 'weapon', stats: { damage: 10, durability: 50 } },
                { name: 'Poción de Vida', type: 'consumable', cantidad: 1, stats: { heal: 20 } },
            ],
        });

        res.json({ playerId: jugador._id, username: jugador.username });
    } catch (err) {
        if (err.code === 11000) {
            const field = Object.keys(err.keyValue)[0];
            const message = field === 'email'
                ? 'Este correo electrónico ya está registrado.'
                : 'Este nombre de guerrero ya está en uso.';
            return res.status(400).json({ error: message });
        }
        res.status(400).json({ error: err.message });
    }
});

// RF-03: Login multi-dispositivo
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const jugador = await Player.findOne({ email });
        if (!jugador) return res.status(404).json({ error: 'No se encontró ninguna cuenta con este correo.' });
        const ok = await bcrypt.compare(password, jugador.password_hash);
        if (!ok) return res.status(401).json({ error: 'Credenciales inválidas. Por favor intenta de nuevo.' });

        res.json({
            playerId: jugador._id,
            username: jugador.username,
            max_level_reached: jugador.max_level_reached,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;