

const { MongoClient } = require('mongodb');
const uri = "mongodb://nexus_admin:contraseña@ac-liunuac-shard-00-00.84rczkf.mongodb.net:27017,ac-liunuac-shard-00-01.84rczkf.mongodb.net:27017,ac-liunuac-shard-00-02.84rczkf.mongodb.net:27017/RPG_Inventory_System?ssl=true&replicaSet=atlas-r1ve1p-shard-0&authSource=admin&appName=RPG1";
const client = new MongoClient(uri);

async function run() {
  try {
    await client.connect();
    const db = client.db("RPG_Inventory_System"); // <-- your database name here

    console.log("🚀 Starting database setup — RPG Inventory System...");

    // ==========================================
    // COLLECTION: PLAYERS
    // ==========================================
    await db.createCollection("players", {
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: ["username", "email", "password_hash", "current_level", "max_level_reached"],
          properties: {
            username: {
              bsonType: "string",
              description: "Unique player username"
            },
            email: {
              bsonType: "string",
              pattern: "^.+@.+$",
              description: "Valid email address"
            },
            password_hash: {
              bsonType: "string",
              description: "Bcrypt hash — never store plain text passwords"
            },
            current_level: {
              bsonType: "int",
              minimum: 1,
              description: "Current active level of the player"
            },
            max_level_reached: {
              bsonType: "int",
              minimum: 1,
              description: "Highest level the player has ever reached"
            },
            totalKeys: {
              bsonType: "int",
              minimum: 0
            },
            xp: {
              bsonType: "int",
              minimum: 0
            },
            stats: {
              bsonType: "object",
              required: ["hp", "ataque", "defensa"],
              properties: {
                hp:      { bsonType: "int", minimum: 0 },
                ataque:  { bsonType: "int", minimum: 0 },
                defensa: { bsonType: "int", minimum: 0 }
              }
            },
            inventory: {
              bsonType: "array",
              items: {
                bsonType: "object",
                required: ["name", "type", "cantidad"],
                properties: {
                  name:     { bsonType: "string" },
                  type: {
                    // "consumable" added — matches your real document
                    enum: ["weapon", "consumable", "armor", "map", "scroll", "accessory"]
                  },
                  cantidad: { bsonType: "int", minimum: 0 },
                  equipado: { bsonType: "bool" },
                  stats:    { bsonType: "object" },  // flexible — each item type has different stats
                  created_at: { bsonType: "date" }
                }
              }
            }
            // Note: createdAt, updatedAt and __v are managed automatically
            // by Mongoose — no need to validate them here
          }
        }
      }
    });
    console.log("✅ Collection 'players' created.");

    // ==========================================
    // COLLECTION: ITEMS (Master catalog)
    // ==========================================
    await db.createCollection("items", {
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: ["name", "type", "rarity", "sell_price"],
          properties: {
            name:          { bsonType: "string" },
            type:          { enum: ["weapon", "consumable", "armor", "map", "scroll", "accessory"] },
            rarity:        { enum: ["common", "uncommon", "rare", "epic", "legendary"] },
            sell_price:    { bsonType: "int", minimum: 0 },
            is_quest_item: { bsonType: "bool" },
            stats:         { bsonType: "object" }  // flexible per item type
          }
        }
      }
    });
    console.log("✅ Collection 'items' created.");

    // ==========================================
// COLLECTION: LEVELS
// ==========================================
await db.createCollection("levels", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["level_number", "title", "difficulty"],
      properties: {
        level_number: {
          bsonType: "int",
          minimum: 1
        },
        title: {
          bsonType: "string"
        },
        difficulty: {
          // Spanish values — matches your real documents
          enum: ["Fácil", "Normal", "Difícil", "Legendario"]
        },
        xp_required: {
          bsonType: "int",
          minimum: 0
        },
        reward_item_id: {
          bsonType: "string"
        },
        lore_snippet: {
          bsonType: "string",
          description: "Short narrative text shown to the player"
        },
        is_completed: {
          bsonType: "bool"
        }
      }
    }
  }
});
console.log("✅ Collection 'levels' created.");
    
    // ==========================================
    // INDEXES — Performance
    // ==========================================
    await db.collection("players").createIndex({ username: 1 },             { unique: true });
    await db.collection("players").createIndex({ email: 1 },                { unique: true });
    await db.collection("players").createIndex({ current_level: 1 });

    await db.collection("items").createIndex({ name: 1 },                   { unique: true });
    await db.collection("items").createIndex({ type: 1 });
    await db.collection("items").createIndex({ rarity: 1, sell_price: -1 });

    await db.collection("levels").createIndex({ level_number: 1 },          { unique: true });

    console.log("⚡ All indexes created.");

  } catch (err) {
    console.error("❌ ERROR:", err.message);
  } finally {
    await client.close();
    console.log("🔌 Connection closed.");
  }
}

run();
