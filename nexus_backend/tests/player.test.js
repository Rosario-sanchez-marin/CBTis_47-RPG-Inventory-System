const request = require('supertest');
const app = require('../server');
const Player = require('../models/Player');
const mongoose = require('mongoose');

let playerId;

beforeAll(async () => {
    // Limpia jugadores de prueba
    await Player.deleteMany({ email: 'test_player@gmail.com' });

    // Crea un jugador de prueba directamente en Atlas
    const jugador = await Player.create({
        username: 'TestPlayer',
        email: 'test_player@gmail.com',
        password_hash: 'hashedpassword',
        current_level: 1,
        max_level_reached: 1,
        totalKeys: 0,
        xp: 0,
        stats: { hp: 100, ataque: 10, defensa: 5 },
        inventory: [],
    });
    playerId = jugador._id.toString();
});

afterAll(async () => {
    await Player.deleteMany({ email: 'test_player@gmail.com' });
    await mongoose.connection.close();
});

// ════════════════════════════════════════════════════════════
// GET /player/:id
// ════════════════════════════════════════════════════════════
describe('GET /player/:id', () => {

    // ✅ HAPPY PATH
    test('Retorna datos del jugador correctamente', async () => {
        const res = await request(app).get(`/player/${playerId}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('username', 'TestPlayer');
        expect(res.body).toHaveProperty('max_level_reached', 1);
        expect(res.body).toHaveProperty('xp', 0);
        expect(res.body).toHaveProperty('totalKeys', 0);
    });

    // ❌ SAD PATH — Jugador no existe
    test('Jugador no encontrado retorna error 404', async () => {
        const res = await request(app).get('/player/000000000000000000000000');
        expect(res.statusCode).toBe(404);
        expect(res.body).toHaveProperty('error', 'Jugador no encontrado');
    });

});

// ════════════════════════════════════════════════════════════
// PATCH /player/level
// ════════════════════════════════════════════════════════════
describe('PATCH /player/level', () => {

    // ✅ HAPPY PATH — Subir de nivel correctamente
    test('Actualiza nivel y XP correctamente', async () => {
        const res = await request(app)
            .patch('/player/level')
            .send({
                playerId: playerId,
                nivelCompletado: 1,
                xpGanado: 150,
                nuevaLlave: true,
            });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('max_level_reached', 2);
        expect(res.body).toHaveProperty('xp', 150);
    });

    // ✅ $max nunca retrocede el nivel
    test('max_level_reached nunca retrocede', async () => {
        const res = await request(app)
            .patch('/player/level')
            .send({
                playerId: playerId,
                nivelCompletado: 1,  // nivel ya completado
                xpGanado: 0,
                nuevaLlave: false,
            });
        expect(res.statusCode).toBe(200);
        expect(res.body.max_level_reached).toBeGreaterThanOrEqual(2);
    });

    // ✅ Llave no se duplica al repetir nivel
    test('La llave no se duplica al repetir el mismo nivel', async () => {
        const antes = await Player.findById(playerId);
        const keysBefore = antes.totalKeys;

        await request(app)
            .patch('/player/level')
            .send({
                playerId: playerId,
                nivelCompletado: 1,  // nivel ya completado
                xpGanado: 0,
                nuevaLlave: true,
            });

        const despues = await Player.findById(playerId);
        expect(despues.totalKeys).toBe(keysBefore);
    });

    // ✅ XP acumula correctamente
    test('El XP se acumula correctamente', async () => {
        const antes = await Player.findById(playerId);
        const xpAntes = antes.xp;

        await request(app)
            .patch('/player/level')
            .send({
                playerId: playerId,
                nivelCompletado: 2,
                xpGanado: 250,
                nuevaLlave: true,
            });

        const despues = await Player.findById(playerId);
        expect(despues.xp).toBe(xpAntes + 250);
    });

    // ❌ SAD PATH — PlayerId inválido
    test('PlayerId inválido retorna error 500', async () => {
        const res = await request(app)
            .patch('/player/level')
            .send({
                playerId: 'id_invalido',
                nivelCompletado: 1,
                xpGanado: 150,
                nuevaLlave: false,
            });
        expect(res.statusCode).toBe(500);
    });

});