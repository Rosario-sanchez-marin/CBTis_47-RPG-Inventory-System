// =============================================================
// S11 — CRUD: Update & Delete
// $set, $inc, $push — Actualización de inventarios/estados
// Colección: players
// =============================================================

use('RPG_Inventory_System');

// -------------------------------------------------------------
// $set — Actualizar un campo específico
// Cambiar el nivel actual de un jugador
// SQL: UPDATE players SET current_level = 4 WHERE username = 'shadowblade'
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  { $set: { current_level: 4, max_level_reached: 4 } }
);

// -------------------------------------------------------------
// $set — Actualizar HP del jugador (después de una batalla)
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  { $set: { "stats.hp": 80 } }
);

// -------------------------------------------------------------
// $set — Equipar un ítem del inventario
// Cambia equipado: false → true en la Espada de Hierro
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade", "inventory.name": "Espada de Hierro" },
  { $set: { "inventory.$.equipado": true } }
);

// -------------------------------------------------------------
// $inc — Incrementar un campo numérico
// Sumar 350 XP al jugador al completar un nivel
// SQL: UPDATE players SET xp = xp + 350 WHERE username = 'shadowblade'
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  { $inc: { xp: 350 } }
);

// -------------------------------------------------------------
// $inc — Incrementar totalKeys al obtener una llave
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  { $inc: { totalKeys: 1 } }
);

// -------------------------------------------------------------
// $inc — Decrementar HP al recibir daño en combate
// Resta 15 HP al jugador
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  { $inc: { "stats.hp": -15 } }
);

// -------------------------------------------------------------
// $push — Agregar un nuevo ítem al inventario
// Equivalente a "How do I add a new comment to a comments array"
// del prompt — aquí agregamos un ítem al array inventory
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  {
    $push: {
      inventory: {
        name: "Pocion de Salud",
        type: "consumable",
        cantidad: 1,
        equipado: false,
        stats: { heal: 30 },
        created_at: new Date()
      }
    }
  }
);

// -------------------------------------------------------------
// $push — Agregar una llave nueva al inventario
// Se ejecuta cuando el jugador completa un nivel
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  {
    $push: {
      inventory: {
        name: "Llave de la Forja",
        type: "key",
        cantidad: 1,
        equipado: false,
        item_id: "key_06",
        created_at: new Date()
      }
    }
  }
);

// -------------------------------------------------------------
// $set + $inc combinados — Completar un nivel
// Actualiza nivel, suma XP y suma una llave en una sola operación
// -------------------------------------------------------------
db.players.updateOne(
  { username: "shadowblade" },
  {
    $set:  { current_level: 6, max_level_reached: 6 },
    $inc:  { xp: 650, totalKeys: 1 }
  }
);

// -------------------------------------------------------------
// updateMany — Actualizar TODOS los jugadores
// Resetear HP a 100 para todos (mantenimiento del servidor)
// SQL: UPDATE players SET stats.hp = 100
// -------------------------------------------------------------
db.players.updateMany(
  {},
  { $set: { "stats.hp": 100 } }
);

// -------------------------------------------------------------
// deleteOne — Eliminar un jugador específico
// SQL: DELETE FROM players WHERE username = 'shadowblade'
// -------------------------------------------------------------
db.players.deleteOne(
  { username: "shadowblade" }
);

// -------------------------------------------------------------
// deleteMany — Eliminar jugadores que nunca avanzaron
// Elimina jugadores que siguen en nivel 1 con menos de 150 XP
// -------------------------------------------------------------
db.players.deleteMany(
  {
    $and: [
      { max_level_reached: 1 },
      { xp: { $lte: 150 } }
    ]
  }
);
