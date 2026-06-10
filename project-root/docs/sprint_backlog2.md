🏃 Sprint Backlog: Sprint 2
---
– Core Gameplay & Final Content
*Product:* Nexus RPG: The Crown Schism  
*Sprint Duration:* May 13 – June 6, 2026 (24 days)  
*Capacity Plan:* 8h/week → ∼28h total, 27h planificadas
---
OUTLINE
1. Sprint Goal
2. Sprint Parameters & Capacity Plan
3. Selected Epics & User Stories  
4. Action Plan & Task Breakdown
5. Weekly Execution Roadmap
6. Impediments & Dependencies
7. Definition of Done (DoD)
---
1. Sprint Goal
Deliver playable levels 4–10 with integrated UI, complete technical documentation, and a functional seed system accessible from the game interface, ensuring all components are connected to MongoDB Atlas.

2. Sprint Parameters & Capacity Plan
- *Team Size:* 5 members
- *Total Capacity:* 27h estimadas de 28h disponibles
- *Buffer:* 1h para imprevistos
- *Tech Stack:* Flutter, http://Node.js/Express, MongoDB Atlas

3. Selected Epics & User Stories

*Epic 1: Core Gameplay Progression*
- HU-01: As a player, I want to complete levels sequentially so that I can advance in the story and unlock the next level on the map.
- HU-02: As a player, I want to automatically receive a key and a reward item in my inventory the first time I complete a level, so that my progress feels rewarded.
- HU-03: As a player, I want to earn XP upon completing each level so that I can see my character grow throughout the game.
- HU-04: As a player, I want keys not to duplicate if I replay an already completed level, so that the integrity of my inventory is maintained.
- HU-08: As a player, I want the final level to be locked until I have all 9 keys, so that reaching the final boss feels like a real achievement.
- HU-09: As a player, I want to see a victory screen after defeating the final boss so that I have a satisfying conclusion to the story.
- HU-10: As a player, I want to see on the map which levels are available, locked, or completed so that I can keep track of my progress.
- HU-11: As a player, I want to see the key count on the map so that I know how many keys I still need to access the final level.

*Epic 2: Combat & Mechanics*
- HU-05: As a player, I want each enemy to have a unique mechanic so that every level presents a different challenge.
- HU-06: As a player, I want to see a visual indicator when I am affected by a status effect so that I can make tactical decisions during combat.
- HU-07: As a player, I want to be able to use special items during combat so that I have a strategic advantage.

*Epic 3: Inventory System*
- HU-12: As a player, I want to see all my items in an inventory screen so that I can manage my resources before entering combat.
- HU-13: As a player, I want my inventory to have a limit of 30 items so that resource management becomes part of the experience.

*Epic 4: Narrative & Lore*
- HU-14: As a player, I want to hear the Fallen Sentinel's dialogue at the start of certain levels so that I can understand the world's lore as I progress.
- HU-15: As a player, I want Level 8 to have no dialogue and only a dark atmosphere so that I can feel the narrative shift that marks the story.
- HU-16: As a player, I want to hear Malakor speak for the first time in Level 9 so that his appearance as the final boss carries dramatic weight.

*Epic 5: Developer Tools & QA*
- HU-17: As a developer, I want to access a seed screen from the map or settings so that I can insert test data without manually modifying the database.
- HU-18: As a developer, I want to seed preconfigured player profiles so that I can speed up testing at different game states.
- HU-19: As a development team, we want to run unit and manual tests so that we can ensure all 10 levels work correctly before delivery.

4. Action Plan & Task Breakdown
_Desglosado por nivel para claridad_

*Levels 4-10 Implementation: 18.5h total*
- Level 4 — The Forest of Whispers: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
- Level 5 — The Market of Silence: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
- Level 6 — The Forge of Hope: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-14
- Level 7 — The Swamp of Sorrow: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-06, HU-10, HU-14
- Level 8 — The Great Crystal Library: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-15
- Level 9 — The Watchtower of Sacrifice: 2.5h | HU-01, HU-02, HU-03, HU-04, HU-05, HU-10, HU-16
- Level 10 — The Throne of the Schism: 3h | HU-01, HU-02, HU-03, HU-05, HU-08, HU-09, HU-10, HU-11

*Seed System: 3h total* | HU-17, HU-18
- Design seed screen accessible from map: 1h
- Add seeds for Level 5 and Level 9 states: 1h  
- Connect to `POST /auth/register` and `POST /inventory/item`: 0.5h
- Test seeded data in Atlas: 0.5h

*Testing & Bug Fixes: 3h total* | HU-11, HU-13, HU-19
- Run all Jest unit tests: 0.5h
- Manual end-to-end test of all 10 levels: 1h
- Verify key count + inventory limit: 1h
- Fix bugs found: 0.5h

*Documentation: 2h total*
- Update README with all 10 levels: 1h
- Review Product Backlog and SRS: 0.5h
- Add aggregation queries: 0.5h

*Sprint Closure: 1h total*
- Demo Day: 0.5h
- Atlas showcase + Retrospective: 0.5h

5. Weekly Execution Roadmap

*Week 1: Levels 4-5 & Seed Foundation (Est. 6h)*
- *Focus*: Implement core loop for mid-game + start dev tools
- *Key Tasks*:
    - Develop Level 4 and 5 screens with unique mechanics
    - Design seed screen UI accessible from map
    - Connect `_endGame()` to `PATCH /player/level` for both levels
- *Friday Milestone*: Level 4 and 5 fully playable with data saved to Atlas

*Week 2: Levels 6-7 & Narrative Arc (Est. 5h)*
- *Focus*: Escalate mechanics + close Fallen Sentinel arc
- *Key Tasks*:
    - Implement Level 6 regen + Level 7 poison with visual indicator
    - Add last Fallen Sentinel dialogue before Level 8 silence
    - Add seed: player at Level 5 with 5 keys
- *Friday Milestone*: Levels 4-7 complete, poison status effect working

*Week 3: Levels 8-10 & Final Boss (Est. 8h)*
- *Focus*: Narrative shift + final content lock
- *Key Tasks*:
    - Build Level 8 with dark atmosphere, no dialogue
    - Implement Level 9 two-phase boss + Malakor dialogue
    - Build Level 10 with 9-key lock check + victory screen
    - Add seed: player at Level 9 with 8 keys
- *Friday Milestone*: All 10 levels playable, final boss unlockable with 9 keys

*Week 4: Testing, Docs & Integration (Est. 6h)*
- *Focus*: Closing the loop and delivery
- *Key Tasks*:
    - Run Jest tests + manual E2E for all levels
    - Verify key count on map and 30-item inventory limit
    - Update README, SRS, and aggregation queries
    - Connect seed actions to backend routes
- *Friday Milestone*: A functional "Walking Skeleton" where a player can complete all 10 levels, unlock the final boss with keys, and devs can seed test states from the UI.

6. Impediments & Dependencies
- *Dependency*: Level 10 lock requires `GET /player/keys` endpoint to be functional before implementation. Level 7 poison indicator requires HU-06 combat UI component.
- *Impediment*: None identified currently.

7. Definition of Done (DoD)
- [ ] Code follows Clean Architecture principles strictly
- [ ] Unit tests pass for all Domain Use Cases, specifically enemy mechanics and key validation
- [ ] API endpoints are protected by authentication middleware
- [ ] The functionality has been manually tested end-to-end in the staging environment
- [ ] Data is correctly saved and retrieved from MongoDB Atlas
- [ ] No critical or high-severity bugs exist
- [ ] English code comments and Mermaid E-R diagrams are updated and documented
