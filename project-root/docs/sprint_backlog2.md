**SPRINT BACKLOG 2

---
sprint_backlog: "Sprint 2 - Core Gameplay & Final Content"
product: "Nexus RPG: The Crown Schism"
sprint_duration: "May 13 - June 6, 2026 (24 days)"
capacity_plan: "40h/week -> ~120h total, 98h planned"
---

## 📌 Sprint Backlog Table of Contents

1. [1. Sprint Goal](#1-sprint-goal)
2. [2. Sprint Parameters & Capacity Plan](#2-sprint-parameters--capacity-plan)
3. [3. Selected Epics, User Stories & Acceptance Criteria](#3-selected-epics-user-stories--acceptance-criteria)
    * [Epic 1: Core Gameplay Progression](#epic-1-core-gameplay-progression)
    * [Epic 2: Combat & Mechanics](#epic-2-combat--mechanics)
    * [Epic 3: Inventory System](#epic-3-inventory-system)
    * [Epic 4: Narrative & Lore](#epic-4-narrative--lore)
    * [Epic 5: Developer Tools & QA](#epic-5-developer-tools--qa)
4. [4. Action Plan & Task Breakdown](#4-action-plan--task-breakdown)
    * [Levels 4-10 Implementation](#levels-4-10-implementation-50h-total)
    * [Seed System](#seed-system-15h-total--hu-17-hu-18)
    * [Testing & Bug Fixes](#testing--bug-fixes-17h-total--hu-11-hu-13-hu-19)
    * [Documentation](#documentation-11h-total)
    * [Sprint Closure](#sprint-closure-5h-total)
5. [5. Weekly Execution Roadmap](#5-weekly-execution-roadmap)
    * [Week 1: Levels 4-5 & Seed Foundation](#week-1-levels-4-5--seed-foundation-est-28h)
    * [Week 2: Levels 6-7 & Narrative Arc](#week-2-levels-6-7--narrative-arc-est-28h)
    * [Week 3: Levels 8-10 & Final Boss](#week-3-levels-8-10--final-boss-est-28h)
    * [Week 4: Testing, Docs & Integration](#week-4-testing-docs--integration-est-14h)
6. [6. Impediments & Dependencies](#6-impediments--dependencies)
7. [7. Definition of Done (DoD)](#7-definition-of-done-dod)
8. [👥 Task Distribution](#-task-distribution)

---

# SPRINT BACKLOG: SPRINT 2

## 1. Sprint Goal
Deliver playable levels 4–10 with integrated UI, complete technical documentation, and a functional seed system accessible from the game interface, ensuring all components are connected to MongoDB Atlas.

---

## 2. Sprint Parameters & Capacity Plan

*   **Team Size:** 5 members
*   **Sprint Duration:** 24 days (~3.5 weeks)
*   **Capacity per member:** 8h/week $\rightarrow$ ~24h total per member.
*   **Total Team Capacity:** 5 members $\times$ 24h = **120 available hours**.
*   **Total Planned Effort:** **98 estimated hours**.
*   **Buffer:** 22h for unexpected integration and deployment issues.
*   **Tech Stack:** Flutter, Node.js/Express, MongoDB Atlas.

---

## 3. Selected Epics, User Stories & Acceptance Criteria

### Epic 1: Core Gameplay Progression

*   **HU-01: Sequential Level Progression**
    *   *As a player, I want to complete levels sequentially so that I can advance in the story and unlock the next level on the map.*
    *   **Acceptance Criteria:**
        *   **Given** the player is on the level selection map.
        *   **When** they successfully complete the current level (e.g., Level 4).
        *   **Then** the system must update their progress in MongoDB (`PATCH /player/level`) and immediately unlock access to the next level (e.g., Level 5).

*   **HU-02: Automatic Reward (Key & Item)**
    *   *As a player, I want to automatically receive a key and a reward item in my inventory the first time I complete a level, so that my progress feels rewarded.*
    *   **Acceptance Criteria:**
        *   **Given** the player completes a specific level for the first time.
        *   **When** the server processes the victory state.
        *   **Then** 1 key and 1 unique reward item must be automatically added to the player's database inventory (`POST /inventory/item`).

*   **HU-03: XP Progression**
    *   *As a player, I want to earn XP upon completing each level so that I can see my character grow throughout the game.*
    *   **Acceptance Criteria:**
        *   **Given** the player successfully finishes a level.
        *   **When** the victory screen is triggered.
        *   **Then** the earned experience points must be added to the player's profile and persisted in MongoDB Atlas.

*   **HU-04: No Key Duplication on Replay**
    *   *As a player, I want keys not to duplicate if I replay an already completed level, so that the integrity of my inventory is maintained.*
    *   **Acceptance Criteria:**
        *   **Given** the player replays a level that already has a "Completed" status.
        *   **When** they clear the level successfully again.
        *   **Then** the system must not grant an additional key or duplicate the unique item reward in their inventory.

*   **HU-08: Final Level Gate (Level 10)**
    *   *As a player, I want the final level to be locked until I have all 9 keys, so that reaching the final boss feels like a real achievement.*
    *   **Acceptance Criteria:**
        *   **Given** the player interacts with Level 10 on the map interface.
        *   **When** the key count retrieved from `GET /player/keys` is less than 9.
        *   **Then** the level must remain locked, and a prompt indicating that all 9 keys are required must be displayed.

*   **HU-09: Final Victory Screen**
    *   *As a player, I want to see a victory screen after defeating the final boss so that I have a satisfying conclusion to the story.*
    *   **Acceptance Criteria:**
        *   **Given** the player reduces Malakor's health points to 0 in Level 10.
        *   **When** the combat loop terminates.
        *   **Then** the game must display the final cinematic victory screen, showing the credits and narrative conclusion.

*   **HU-10: Map Progress States**
    *   *As a player, I want to see on the map which levels are available, locked, or completed so that I can keep track of my progress.*
    *   **Acceptance Criteria:**
        *   **Given** the user opens the world map interface.
        *   **When** the frontend fetches the user's progression data from the backend.
        *   **Then** each level node (4 to 10) must visually reflect its current state via distinct colors or icons: Locked, Available, or Completed.

*   **HU-11: Key Counter HUD**
    *   *As a player, I want to see the key count on the map so that I know how many keys I still need to access the final level.*
    *   **Acceptance Criteria:**
        *   **Given** the player is navigating the map UI.
        *   **When** the view updates.
        *   **Then** a dedicated counter widget must remain visible displaying the active text format: `Keys: X / 9`.

### Epic 2: Combat & Mechanics

*   **HU-05: Unique Enemy Mechanics**
    *   *As a player, I want each enemy to have a unique mechanic so that every level presents a different challenge.*
    *   **Acceptance Criteria:**
        *   **Given** the player is in an active turn-based combat instance.
        *   **When** it is the enemy's turn or their trigger condition is fulfilled.
        *   **Then** the backend must execute the corresponding unique mechanical script (e.g., life regeneration or damage over time) and apply it to the game state payload sent to the client.

*   **HU-06: Status Effect UI Indicator**
    *   *As a player, I want to see a visual indicator when I am affected by a status effect so that I can make tactical decisions during combat.*
    *   **Acceptance Criteria:**
        *   **Given** the active player character is afflicted with a status condition (such as Poison in Level 7).
        *   **When** the player's turn initializes in the Flutter layout.
        *   **Then** a status badge or blinking element must be rendered next to the character's health bar.

*   **HU-07: Combat Combat-Item System**
    *   *As a player, I want to be able to use special items during combat so that I have a strategic advantage.*
    *   **Acceptance Criteria:**
        *   **Given** it is the player's turn during a battle sequence.
        *   **When** the user accesses the quick-inventory drawer and confirms the consumption of an item.
        *   **Then** the item's effects must immediately update player attributes, and its quantity must be decremented via MongoDB.

### Epic 3: Inventory System

*   **HU-12: Main Menu Inventory Management**
    *   *As a player, I want to see all my items in an inventory screen so that I can manage my resources before entering combat.*
    *   **Acceptance Criteria:**
        *   **Given** the player is navigating the main dashboard or world map.
        *   **When** they press the Inventory action button.
        *   **Then** the application must load a structured grid displaying all ownership records fetched from the database inventory collection.

*   **HU-13: 30-Item Inventory Cap**
    *   *As a player, I want my inventory to have a limit of 30 items so that resource management becomes part of the experience.*
    *   **Acceptance Criteria:**
        *   **Given** the player's current item array contains exactly 30 entries.
        *   **When** a route execution triggers a new item addition via `POST /inventory/item`.
        *   **Then** the API must reject the request with a `400 Bad Request` payload, and the client must render an "Inventory Full" notification toast.

### Epic 4: Narrative & Lore

*   **HU-14: Fallen Sentinel Intro Dialogues**
    *   *As a player, I want to hear the Fallen Sentinel's dialogue at the start of certain levels so that I can understand the world's lore as I progress.*
    *   **Acceptance Criteria:**
        *   **Given** the player boots Level 4, 5, 6, or 7.
        *   **When** the pre-combat phase initializes.
        *   **Then** the screen overlay must render a structured dialog box containing the Fallen Sentinel's narrative scripts along with a functioning "Skip" option.

*   **HU-15: Level 8 Atmosphere Shift**
    *   *As a player, I want Level 8 to have no dialogue and only a dark atmosphere so that I can feel the narrative shift that marks the story.*
    *   **Acceptance Criteria:**
        *   **Given** the user triggers the loading routine for Level 8 (The Great Crystal Library).
        *   **When** the view loads completely.
        *   **Then** the system must explicitly omit dialogue elements and apply a dark, muted visual theme across the Flutter view layout.

*   **HU-16: Malakor's First Encounter (Level 9)**
    *   *As a player, I want to hear Malakor speak for the first time in Level 9 so that his appearance as the final boss carries dramatic weight.*
    *   **Acceptance Criteria:**
        *   **Given** the player initializes Level 9.
        *   **When** entering the map introduction.
        *   **Then** the narrative module must isolate Malakor's unique text box prompts before shifting control over to the two-phase boss sequence.

### Epic 5: Developer Tools & QA

*   **HU-17: In-Game UI Seed Interface**
    *   *As a developer, I want to access a seed screen from the map or settings so that I can insert test data without manually modifying the database.*
    *   **Acceptance Criteria:**
        *   **Given** an administrator or QA practitioner is inside the configuration or world map views.
        *   **When** they execute the dedicated hidden gesture macro.
        *   **Then** the routing engine must mount the sandbox "Seed Panel" view containing tools for database operations.

*   **HU-18: Preconfigured Testing Profiles**
    *   *As a developer, I want to seed preconfigured player profiles so that I can speed up testing at different game states.*
    *   **Acceptance Criteria:**
        *   **Given** the QA engine is active on the UI Seed interface.
        *   **When** the operator triggers the "Load Profile: Level 9 Preset" module.
        *   **Then** the system must dispatch asynchronous batch HTTP requests to register a mock environment profile configured directly to Level 9 with 8 keys stored in the Atlas cluster.

*   **HU-19: Unit and E2E Automated Verification**
    *   *As a development team, we want to run unit and manual tests so that we can ensure all 10 levels work correctly before delivery.*
    *   **Acceptance Criteria:**
        *   **Given** the current build cycle has progressed into the closure phase (Week 4).
        *   **When** the continuous delivery commands or localized test scripts (`npm run test` utilizing Jest) are initiated alongside manual test scripts.
        *   **Then** 100% of the domain business rules must return passing evaluations with zero structural regressions.

---

## 4. Action Plan & Task Breakdown

### Levels 4-10 Implementation: 50h total
*   **Level 4 — The Forest of Whispers:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
*   **Level 5 — The Market of Silence:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
*   **Level 6 — The Forge of Hope:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
*   **Level 7 — The Swamp of Sorrow:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-06, HU-10, HU-14
*   **Level 8 — The Great Crystal Library:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-15
*   **Level 9 — The Watchtower of Sacrifice:** 7h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-16
*   **Level 10 — The Throne of the Schism:** 8h | HU-01, HU-02, HU-03, HU-05, HU-08, HU-09, HU-10, HU-11

### Seed System: 15h total | HU-17, HU-18
*   Design seed screen accessible from map: 4h
*   Add backend seeds logic for Level 5 and Level 9 states: 5h  
*   Connect interface to `POST /auth/register` and `POST /inventory/item`: 3h
*   Test and validate seeded data in Atlas: 3h

### Testing & Bug Fixes: 17h total | HU-11, HU-13, HU-19
*   Write and run Jest unit tests (Domain & Combat validation): 5h
*   Manual end-to-end test of all 10 levels: 5h
*   Verify key count + inventory limit constraints: 3h
*   Fix bugs found in staging environment: 4h

### Documentation: 11h total
*   Update README with complete descriptions of all 10 levels: 4h
*   Review and update Product Backlog and SRS: 3h
*   Add complex aggregation queries documentation: 4h

### Sprint Closure: 5h total
*   Preparation of Demo Day presentation: 2.5h
*   Atlas showcase + Team Retrospective: 2.5h

---

## 5. Weekly Execution Roadmap

### Week 1: Levels 4-5 & Seed Foundation (Est. 28h)
*   **Focus:** Implement core loop for mid-game + start dev tools.
*   **Key Tasks:**
    *   Develop Level 4 and 5 screens with unique mechanics.
    *   Design seed screen UI accessible from map.
    *   Connect `_endGame()` to `PATCH /player/level` for both levels.
*   **Friday Milestone:** Level 4 and 5 fully playable with data saved to Atlas.

### Week 2: Levels 6-7 & Narrative Arc (Est. 28h)
*   **Focus:** Escalate mechanics + close Fallen Sentinel arc.
*   **Key Tasks:**
    *   Implement Level 6 regen + Level 7 poison with visual indicator.
    *   Add last Fallen Sentinel dialogue before Level 8 silence.
    *   Add seed: player at Level 5 with 5 keys.
*   **Friday Milestone:** Levels 4-7 complete, poison status effect working.

### Week 3: Levels 8-10 & Final Boss (Est. 28h)
*   **Focus:** Narrative shift + final content lock.
*   **Key Tasks:**
    *   Build Level 8 with dark atmosphere, no dialogue.
    *   Implement Level 9 two-phase boss + Malakor dialogue.
    *   Build Level 10 with 9-key lock check + victory screen.
    *   Add seed: player at Level 9 with 8 keys.
*   **Friday Milestone:** All 10 levels playable, final boss unlockable with 9 keys.

### Week 4: Testing, Docs & Integration (Est. 14h)
*   **Focus:** Closing the loop, polishing, and delivery.
*   **Key Tasks:**
    *   Run Jest tests + manual E2E for all levels.
    *   Verify key count on map and 30-item inventory limit.
    *   Update README, SRS, and aggregation queries.
    *   Connect seed actions to backend routes.
*   **Friday Milestone:** A functional "Walking Skeleton" where a player can complete all 10 levels, unlock the final boss with keys, and devs can seed test states from the UI.

---

## 6. Impediments & Dependencies
*   **Dependency:** Level 10 lock requires `GET /player/keys` endpoint to be functional before implementation. Level 7 poison indicator requires HU-06 combat UI component.
*   **Impediment:** None identified currently.

---

## 7. Definition of Done (DoD)
*   [ ] Code follows Clean Architecture principles strictly.
*   [ ] Unit tests pass for all Domain Use Cases, specifically enemy mechanics and key validation.
*   [ ] API endpoints are protected by authentication middleware.
*   [ ] The functionality has been manually tested end-to-end in the staging environment.
*   [ ] Data is correctly saved and retrieved from MongoDB Atlas.
*   [ ] No critical or high-severity bugs exist.
*   [ ] English code comments and Mermaid E-R diagrams are updated and documented.

---

## 👥 Task Distribution

| Member | Responsibility | HUs |
|---|---|---|
| **Sánchez Marín María del Rosario** | Data Modeler — MongoDB schemas, seed system | HU-17, HU-18 |
| **Rojas González Ulisses** | Query Developer — aggregation queries, backend routes | HU-01, HU-03, HU-04 |
| **Valiente Marín Yoanna** | Integration Specialist — Flutter ↔ API connection | HU-02, HU-07, HU-08 |
| **Velázquez Reyes Axel Judá** | Data Seeder / QA — testing, bug fixes, seed interface | HU-13, HU-19 |
| **Virgen Juárez Camila** | Scrum Master — documentation, sprint coordination | HU-09, HU-10, HU-11 |
