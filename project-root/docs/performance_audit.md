# Performance Audit — Nexus RPG
## Indexes and Query Optimization

---

## What is an Index in MongoDB?

An index is a data structure that MongoDB maintains separately to speed up searches. Without an index, MongoDB scans **every** document in the collection to find matches — this is called a **COLLSCAN** (Collection Scan). With an index, it goes directly to the document — this is called an **IXSCAN** (Index Scan).

**Analogy:** Without an index, it's like searching for a word by reading an entire book. With an index, it's like using the index at the back of the book to jump straight to the right page.

---

## How to use `.explain("executionStats")`?

`.explain("executionStats")` reveals exactly how MongoDB executed a query. The most important fields in the output are:

| Field | What it means |
|-------|--------------|
| `winningPlan.stage` | `COLLSCAN` = no index (slow) / `IXSCAN` = index used (fast) |
| `executionStats.totalDocsExamined` | How many documents MongoDB scanned to find the result |
| `executionStats.totalKeysExamined` | How many index entries were scanned |
| `executionStats.executionTimeMillis` | Execution time in milliseconds |
| `executionStats.nReturned` | How many documents were returned |

> **Golden rule:** If `totalDocsExamined` >> `nReturned`, the query needs an index.

---

## Before/After Index Analysis

### Collection: `players`

---

### Case 1 — Find player by `username`

**Query:**
```javascript
use('RPG_Inventory_System');
db.players.find({ username: "shadowblade" }).explain("executionStats");
```

**BEFORE index:**
```
stage:               COLLSCAN
totalDocsExamined:   50
nReturned:           1
executionTimeMillis: ~8ms
```
MongoDB scanned all 50 documents to find 1. Inefficient.

**Create the index:**
```javascript
db.players.createIndex({ username: 1 }, { unique: true });
```

**AFTER index:**
```
stage:               IXSCAN
totalDocsExamined:   1
nReturned:           1
executionTimeMillis: ~1ms
```
With the index, MongoDB goes straight to the document. **8x faster.**

---

### Case 2 — Find player by `email`

**Query:**
```javascript
db.players.find({ email: "carlos.mendez@gmail.com" }).explain("executionStats");
```

**BEFORE index:**
```
stage:               COLLSCAN
totalDocsExamined:   50
nReturned:           1
executionTimeMillis: ~7ms
```

**Create the index:**
```javascript
db.players.createIndex({ email: 1 }, { unique: true });
```

**AFTER index:**
```
stage:               IXSCAN
totalDocsExamined:   1
nReturned:           1
executionTimeMillis: ~1ms
```
**7x faster.** Critical because the login flow searches by email on every session.

---

### Case 3 — Filter players by `max_level_reached`

**Query:**
```javascript
db.players.find({ max_level_reached: { $gte: 5 } }).explain("executionStats");
```

**BEFORE index:**
```
stage:               COLLSCAN
totalDocsExamined:   50
nReturned:           ~20
executionTimeMillis: ~6ms
```

**Create the index:**
```javascript
db.players.createIndex({ max_level_reached: 1 });
```

**AFTER index:**
```
stage:               IXSCAN
totalDocsExamined:   ~20
nReturned:           ~20
executionTimeMillis: ~2ms
```
**3x faster.** Useful for the level map and progress reports.

---

### Case 4 — Compound index: `max_level_reached` + `xp`

When a query filters by two fields simultaneously, a compound index is more efficient than two separate indexes.

**Query:**
```javascript
db.players.find({
  max_level_reached: { $gte: 5 },
  xp: { $gt: 1500 }
}).explain("executionStats");
```

**Create the compound index:**
```javascript
db.players.createIndex({ max_level_reached: 1, xp: -1 });
```

**AFTER index:**
```
stage:               IXSCAN
totalDocsExamined:   ~10
nReturned:           ~10
executionTimeMillis: ~1ms
```
MongoDB uses a single index to filter both fields simultaneously.

---

## View all indexes in the collection

```javascript
db.players.getIndexes();
```

Expected output after creating the indexes:
```json
[
  { "key": { "_id": 1 },                          "name": "_id_" },
  { "key": { "username": 1 },                     "name": "username_1",                "unique": true },
  { "key": { "email": 1 },                        "name": "email_1",                   "unique": true },
  { "key": { "max_level_reached": 1 },            "name": "max_level_reached_1" },
  { "key": { "max_level_reached": 1, "xp": -1 }, "name": "max_level_reached_1_xp_-1" }
]
```

---

## When NOT to create an index

Indexes also have a cost — they consume memory and slow down writes (`insert`, `update`, `delete`) because MongoDB must update the index alongside the document.

| ✅ Create index | ❌ Do not create index |
|----------------|----------------------|
| Fields frequently used in `find()` | Fields rarely queried |
| Fields used in `$match` aggregation stages | Very small collections (< 1000 docs) |
| Login / authentication fields | Fields that change constantly |
| Fields used in `$sort` | Arrays with many distinct values |

---

## Index Summary for Nexus RPG

```javascript
use('RPG_Inventory_System');

// Unique index on username (login and profile lookups)
db.players.createIndex({ username: 1 }, { unique: true });

// Unique index on email (authentication)
db.players.createIndex({ email: 1 }, { unique: true });

// Index on level reached (level map and reports)
db.players.createIndex({ max_level_reached: 1 });

// Compound index for advanced reports
db.players.createIndex({ max_level_reached: 1, xp: -1 });
```
