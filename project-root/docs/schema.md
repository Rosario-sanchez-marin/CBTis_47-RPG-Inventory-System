# Diagrama de relaciones - RPG Inventory System

```mermaid
---
title:RPG Inventory System 
---
erDiagram
    PLAYER ||--o{ INVENTORY : posee
    INVENTORY ||--o{ ITEM : contiene

    PLAYER {
        int id
        string name
        int level
    }

    INVENTORY {
        int id
        int capacity
    }

    ITEM {
        int id
        string type
        string name
        int damage
        int durability
        string effect
        int duration
        string coordinates
    }
```
