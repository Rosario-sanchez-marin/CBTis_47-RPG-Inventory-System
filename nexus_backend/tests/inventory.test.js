const request = require('supertest');
const app = require('../server');
const Player = require('../models/Player');
const mongoose = require('mongoose');

let playerId;

beforeAll(async () => {
    await Player.deleteMany({ email: 'test_inventory@gmail.com' });

    const jugador = await Player.create({
        username: 'TestInventory',
        email: 'test_inventory@gmail.com',
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
    await Player.deleteMany({ email: 'test_inventory@gmail.com' });
    await mongoose.connection.close();
});

// ════════════════════════════════════════════════════════════
// GET /inventory/:playerId
// ════════════════════════════════════════════════════════════
describe('GET /inventory/:playerId', () => {

    // ✅ HAPPY PATH — Inventario vacío
    test('Retorna inventario vacío correctamente', async () => {
        const res = await request(app).get(`/inventory/${playerId}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual([]);
    });

    // ❌ SAD PATH — Jugador no existe
    test('Jugador no encontrado retorna error 404', async () => {
        const res = await request(app).get('/inventory/000000000000000000000000');
        expect(res.statusCode).toBe(404);
    });

});

// ════════════════════════════════════════════════════════════
// POST /inventory/item
// ════════════════════════════════════════════════════════════
describe('POST /inventory/item', () => {

    // ✅ HAPPY PATH — $push agrega ítem correctamente
    test('$push agrega espada al inventario correctamente', async () => {
        const res = await request(app)
            .post('/inventory/item')
            .send({
                playerId,
                item: {
                    name: 'Espada de Hierro',
                    type: 'weapon',
                    stats: { damage: 10, durability: 50 },
                },
            });
        expect(res.statusCode).toBe(200);
        expect(res.body.length).toBe(1);
        expect(res.body[0]).toHaveProperty('name', 'Espada de Hierro');
        expect(res.body[0]).toHaveProperty('type', 'weapon');
    });

    // ✅ $push agrega poción correctamente
    test('$push agrega poción al inventario correctamente', async () => {
        const res = await request(app)
            .post('/inventory/item')
            .send({
                playerId,
                item: {
                    name: 'Poción de Vida',
                    type: 'consumable',
                    stats: { heal: 20 },
                },
            });
        expect(res.statusCode).toBe(200);
        expect(res.body.length).toBe(2);
        expect(res.body[1]).toHaveProperty('name', 'Poción de Vida');
    });

    // ❌ SAD PATH — Límite de 30 ítems
    test('Rechaza $push cuando el inventario tiene 30 ítems', async () => {
        // Limpia primero
        await Player.findByIdAndUpdate(playerId, { $set: { inventory: [] } });

        // Llena hasta 30 directo en Atlas (más rápido)
        const items = Array.from({ length: 30 }, (_, i) => ({
            name: `Item ${i}`,
            type: 'weapon',
            stats: { damage: 5, durability: 10 },
        }));
        await Player.findByIdAndUpdate(
            playerId,
            { $push: { inventory: { $each: items } } },
            { returnDocument: 'after' }
        );

        // Intenta agregar el ítem 31 via API
        const res = await request(app)
            .post('/inventory/item')
            .send({
                playerId,
                item: {
                    name: 'Item de más',
                    type: 'weapon',
                    stats: { damage: 5, durability: 10 },
                },
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Inventory full. Maximum 30 items allowed.');
    }, 30000); // ← timeout extendido para esta prueba

    // ❌ SAD PATH — Stats inválidos para el tipo
    test('Rechaza ítem con stats inválidos para su tipo', async () => {
        // Limpia el inventario
        await Player.findByIdAndUpdate(playerId, { $set: { inventory: [] } });

        const res = await request(app)
            .post('/inventory/item')
            .send({
                playerId,
                item: {
                    name: 'Espada Inválida',
                    type: 'weapon',
                    // ← le falta damage y durability
                    stats: { efecto_pocion: 'invalido' },
                },
            });
        expect(res.statusCode).toBe(400);
    });

});

// ════════════════════════════════════════════════════════════
// DELETE /inventory/:playerId/:itemId
// ════════════════════════════════════════════════════════════
describe('DELETE /inventory/:playerId/:itemId', () => {

    let itemId;

    beforeEach(async () => {
        // Limpia completamente el inventario
        await Player.findByIdAndUpdate(
            playerId,
            { $set: { inventory: [], 'stats.hp': 80 } },
            { returnDocument: 'after' }
        );

        // Agrega una poción fresca
        const p = await Player.findByIdAndUpdate(
            playerId,
            {
                $push: {
                    inventory: {
                        name: 'Poción de Vida',
                        type: 'consumable',
                        stats: { heal: 20 },
                    },
                },
            },
            { returnDocument: 'after' }
        );
        itemId = p.inventory[0]._id.toString();
    });

    // ✅ HAPPY PATH — $pull elimina poción y actualiza HP
    test('$pull elimina poción y actualiza HP del jugador', async () => {
        const res = await request(app)
            .delete(`/inventory/${playerId}/${itemId}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('healed', 20);
        expect(res.body).toHaveProperty('newHp', 100); // 80 + 20 = 100
        expect(res.body.inventory.length).toBe(0);
    });

    // ❌ SAD PATH — HP ya al máximo
    test('No usa poción si HP ya está al 100%', async () => {
        // Pone HP al máximo
        await Player.findByIdAndUpdate(playerId, { $set: { 'stats.hp': 100 } });

        const res = await request(app)
            .delete(`/inventory/${playerId}/${itemId}`);
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Your health is already full.');
    });

    // ❌ SAD PATH — Ítem no existe
    test('Ítem inexistente no rompe el servidor', async () => {
        const res = await request(app)
            .delete(`/inventory/${playerId}/000000000000000000000000`);
        expect(res.statusCode).toBe(200);
    });

    // ✅ Overheal limitado a 100 HP
    test('El HP no supera 100 al usar poción', async () => {
        // Pone HP en 90 — la poción cura 20 pero no debe pasar de 100
        await Player.findByIdAndUpdate(playerId, { $set: { 'stats.hp': 90 } });

        const res = await request(app)
            .delete(`/inventory/${playerId}/${itemId}`);
        expect(res.statusCode).toBe(200);
        expect(res.body.newHp).toBe(100);     // no pasa de 100
        expect(res.body.healed).toBe(10);     // solo curó 10 aunque la poción da 20
    });

});