const request = require('supertest');
const app = require('../server');
const Player = require('../models/Player');
const mongoose = require('mongoose');

// ── Un solo beforeAll y afterAll ────────────────────────────────────────────
beforeAll(async () => {
    await Player.deleteMany({
        $or: [
            {
                email: {
                    $in: [
                        'testwarrior@gmail.com',
                        'duplicate@gmail.com',
                        'otro@gmail.com',
                    ]
                }
            },
            {
                username: {
                    $in: [
                        'TestWarrior',
                        'OtroGuerrero',
                        'OtroGuerrero2',
                        'testwarrior',
                    ]
                }
            },
        ]
    });
});

afterAll(async () => {
    await Player.deleteMany({
        $or: [
            {
                email: {
                    $in: [
                        'testwarrior@gmail.com',
                        'duplicate@gmail.com',
                        'otro@gmail.com',
                    ]
                }
            },
            {
                username: {
                    $in: [
                        'TestWarrior',
                        'OtroGuerrero',
                        'OtroGuerrero2',
                        'testwarrior',
                    ]
                }
            },
        ]
    });
    await mongoose.connection.close();
});

// ════════════════════════════════════════════════════════════
// POST /auth/register
// ════════════════════════════════════════════════════════════
describe('POST /auth/register', () => {

    // ✅ HAPPY PATH
    test('Registro exitoso con datos válidos', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'TestWarrior',
                email: 'testwarrior@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('playerId');
        expect(res.body).toHaveProperty('username', 'TestWarrior');
    });

    // ✅ Inventario inicial creado al registrarse
    test('El jugador nuevo tiene Espada de Hierro y Poción en su inventario', async () => {
        const jugador = await Player.findOne({ email: 'testwarrior@gmail.com' });
        expect(jugador).not.toBeNull();
        expect(jugador.inventory.length).toBe(2);
        expect(jugador.inventory[0].name).toBe('Espada de Hierro');
        expect(jugador.inventory[1].name).toBe('Poción de Vida');
    });

    // ✅ Nivel 1 por defecto al registrarse
    test('El jugador nuevo empieza en nivel 1', async () => {
        const jugador = await Player.findOne({ email: 'testwarrior@gmail.com' });
        expect(jugador.current_level).toBe(1);
        expect(jugador.max_level_reached).toBe(1);
    });

    // ❌ SAD PATH 1 — Email duplicado
    test('Email duplicado retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'NuevoGuerrero99',
                email: 'testwarrior@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Este correo electrónico ya está registrado.');
    });

    // ❌ SAD PATH 2 — Username duplicado
    test('Username duplicado retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'TestWarrior',       // ← username duplicado
                email: 'duplicate@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Este nombre de guerrero ya está en uso.');
    });

    // ❌ SAD PATH 3 — Campos vacíos
    test('Campos vacíos retornan error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({ username: '', email: '', password: '' });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Todos los campos son obligatorios.');
    });

    // ❌ SAD PATH 4 — Email no es gmail
    test('Email que no es gmail retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'Guerrero',
                email: 'guerrero@hotmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('El correo electrónico debe ser una cuenta de Gmail válida (@gmail.com).');
    });

    // ❌ SAD PATH 5 — Contraseña débil
    test('Contraseña débil retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'Guerrero',
                email: 'guerrero@gmail.com',
                password: '12345',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Usa números, letras minúsculas, mayúsculas y caracteres especiales con un mínimo de 8 caracteres.');
    });

    // ❌ SAD PATH 6 — Username menor a 3 caracteres
    test('Username menor a 3 caracteres retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'ab',
                email: 'guerrero@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('El nombre de guerrero debe tener entre 3 y 15 caracteres y solo puede contener letras y números.');
    });

    // ❌ SAD PATH 7 — Username mayor a 15 caracteres
    test('Username mayor a 15 caracteres retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'GuerreroDeAethelgardMuyLargo',
                email: 'guerrero@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('El nombre de guerrero debe tener entre 3 y 15 caracteres y solo puede contener letras y números.');
    });

    // ⚙️ EDGE CASE — Username case-insensitive
    test('Username duplicado ignorando mayúsculas retorna error 400', async () => {
        const res = await request(app)
            .post('/auth/register')
            .send({
                username: 'testwarrior',   // mismo que TestWarrior en minúsculas
                email: 'otro@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Este nombre de guerrero ya está en uso.');
    });

});

// ════════════════════════════════════════════════════════════
// POST /auth/login
// ════════════════════════════════════════════════════════════
describe('POST /auth/login', () => {

    // ✅ HAPPY PATH
    test('Login exitoso con credenciales correctas', async () => {
        const res = await request(app)
            .post('/auth/login')
            .send({
                email: 'testwarrior@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('playerId');
        expect(res.body).toHaveProperty('username', 'TestWarrior');
        expect(res.body).toHaveProperty('max_level_reached');
    });

    // ❌ SAD PATH 1 — Contraseña incorrecta
    test('Contraseña incorrecta retorna error 401', async () => {
        const res = await request(app)
            .post('/auth/login')
            .send({
                email: 'testwarrior@gmail.com',
                password: 'WrongPass@123!',
            });
        expect(res.statusCode).toBe(401);
        expect(res.body.error).toBe('Credenciales inválidas. Por favor intenta de nuevo.');
    });

    // ❌ SAD PATH 2 — Email no existe
    test('Email no registrado retorna error 404', async () => {
        const res = await request(app)
            .post('/auth/login')
            .send({
                email: 'noexiste@gmail.com',
                password: 'Test@1234!',
            });
        expect(res.statusCode).toBe(404);
        expect(res.body.error).toBe('No se encontró ninguna cuenta con este correo.');
    });

});