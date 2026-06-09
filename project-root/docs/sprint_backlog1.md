# 📝 SPRINT BACKLOG: SPRINT 1 – "Walking Skeleton & Foundations"

**Product:** "Nexus RPG: The Crown Schism"  
**Sprint Duration:** 4 weeks / 29 days (April 20 – May 18, 2026)  
**Capacity Plan:** 40h/week ➔ ~160h total available | **138h planned**

---

## 📌 Table of Contents
1. [Sprint Goal](#1-sprint-goal)
2. [Sprint Parameters & Capacity Plan](#2-sprint-parameters--capacity-plan)
3. [Epics, User Stories & Acceptance Criteria](#3-epics-user-stories--acceptance-criteria)
4. [Action Plan & Task Breakdown](#4-action-plan--task-breakdown)
5. [Weekly Execution Roadmap](#5-weekly-execution-roadmap)
6. [Impediments & Dependencies](#6-impediments--dependencies)
7. [Definition of Done (DoD)](#7-definition-of-done---dod)
8. [Task Distribution by Team Member](#-8-task-distribution-by-team-member)

---

## 1. Sprint Goal
Configure the project's base architecture (**Walking Skeleton**) by establishing a functional and secure connection between Flutter, Node.js, and MongoDB Atlas. This will allow user registration and login, sequential map navigation (Levels 1 to 3), and persistence of a basic turn-based combat loop with initialized inventory.

---

## 2. Sprint Parameters & Capacity Plan

* **Team Size:** 5 members
* **Duration:** 4 weeks (29 days)
* **Capacity per Member:** 8 hours / week
* **Total per Member:** 4 weeks × 8h = 32 hours
* **Total Team Capacity:** 5 members × 32h = **160 hours available.**
* **Total Planned Effort:** **138 estimated hours.**
* **Contingency Buffer:** 22 hours (to mitigate latency issues, Atlas deployment, or asynchronous operations in Flutter).
* **Tech Stack:** Flutter, Node.js/Express, MongoDB Atlas, Hive, SharedPreferences.

---

## 3. Epics, User Stories & Acceptance Criteria

### 🏰 EPIC 1: Authentication and Profile System
**Epic Priority:** High  
**Description:** Identity management base layer, secure game account registration, initialization of player profile parameters, and local/remote persistence of access credentials to ensure seamless and secure sessions.

#### 📜 US-TF-1-1: New User Registration
* **Priority:** High  
* **Description:** As a player, I want to have a unique account so that my progress and inventory are securely saved in the cloud.

##### 🟢 HAPPY PATH
* **Scenario: Successful registration of a new warrior.**
  * **Given** the user is on the home screen.
  * **When** they enter a unique username, a valid email, and a secure password.
  * **And** they press the "Create Profile" button.
  * **Then** the backend must encrypt the password using `bcrypt` and create a new document in the `Players` collection in MongoDB.
  * **And** the system must simultaneously initialize an empty inventory array linked to the player's ID inside the `inventories` collection containing an *Iron Sword* and a *Health Potion*.
  * **And** the session token (JWT) must be saved locally using `SharedPreferences`.
  * **And** the user must be redirected to the Level Map screen.

##### 🔴 SAD PATHS
* **Scenario 1: Attempted registration with an existing email address.**
  * **Given** the user is on the registration screen.
  * **And** the entered email address already exists in the `Players` collection.
  * **When** the user presses the "Create Profile" button.
  * **Then** the MongoDB backend should return a duplicate key error (HTTP 409 Conflict).
  * **And** the Flutter interface should display: `"This email address is already registered."`
  * **And** no new document should be created in the `Players` collection.

* **Scenario 2: Attempted registration with an existing username.**
  * **Given** the user is on the registration screen.
  * **And** the entered username already exists in the `Players` collection.
  * **When** the user presses the "Create Profile" button.
  * **Then** the MongoDB backend should return a duplicate key error (HTTP 409 Conflict).
  * **And** the Flutter interface should display: `"This username is already in use."`
  * **And** no new document should be created in the `Players` collection.

* **Scenario 3: Registration attempt with empty fields.**
  * **Given** the user is on the registration screen.
  * **When** the user leaves one or more required fields blank.
  * **And** clicks the "Create Profile" button.
  * **Then** the Flutter interface should intercept the action and display: `"You must complete all required fields."`
  * **And** no HTTP request should be sent to the server.

* **Scenario 4: Registration attempt with an invalid email address.**
  * **Given** the user is on the registration screen.
  * **When** the user enters an email address that does not contain the "@" symbol or fails regex check.
  * **And** clicks the "Create Profile" button.
  * **Then** the Flutter interface should display: `"The email address is invalid."`
  * **And** no request should be sent to the server.
  * **And** the registration must not be completed.

* **Scenario 5: Attempted registration with an insecure password.**
  * **Given** the user is on the registration screen.
  * **When** the user enters a password that does not meet security requirements (minimum 8 characters, at least one uppercase letter, one lowercase letter, one number, and one special character).
  * **And** presses the "Create Profile" button.
  * **Then** the Flutter interface should display: `"Use numbers, lowercase letters, uppercase letters, and special characters with a minimum of 8 characters."`
  * **And** no new document should be created in the `Players` collection.

* **Scenario 6: Attempted registration without a server connection.**
  * **Given** the user is on the registration screen.
  * **And** the server is down, unreachable, or unavailable.
  * **When** the user completes all fields correctly.
  * **And** presses the "Create Profile" button.
  * **Then** the Flutter interface should intercept the connection error or socket exception.
  * **And** display: `"Could not connect to the server. Please try again later."`
  * **And** no document should be created in the `Players` collection.

* **Scenario 7: Attempted registration with invalid username length or characters.**
  * **Given** the user is on the registration screen.
  * **When** the user enters a username shorter than 3 characters, longer than 15 characters, or containing special characters.
  * **And** presses the "Create Profile" button.
  * **Then** the Flutter interface should display: `"The username must be between 3 and 15 characters long and contain only letters and numbers."`
  * **And** no request should be sent to the server.

* **Scenario 8: Attempted registration with mismatched passwords.**
  * **Given** the user is on the registration screen.
  * **When** the user enters a valid password.
  * **And** enters a different password in the "Confirm password" field.
  * **And** presses the "Create Profile" button.
  * **Then** the Flutter interface should display: `"Passwords do not match."`
  * **And** no request should be sent to the server.

* **Scenario 9: Username case insensitivity check.**
  * **Given** the user is on the registration screen.
  * **And** a player with the username "KnightKing" already exists in the collection.
  * **When** a new user attempts to register with the username "knightking".
  * **And** presses the "Create Profile" button.
  * **Then** the MongoDB backend should detect the duplication regardless of upper/lowercase using a collation rule or case-insensitive index.
  * **And** the Flutter interface should display: `"This username is already in use."`
  * **And** no new document should be created in the `Players` collection.

##### ⚙️ EDGE CASES
* **Scenario 1: Automatic trimming of whitespace in registration fields.**
  * **Given** the user is on the registration screen.
  * **When** the user enters an email or username with leading or trailing whitespaces.
  * **And** presses the "Create Profile" button.
  * **Then** the Flutter application should automatically trim the whitespaces using `.trim()` before validating or sending data.
  * **And** the registration should proceed successfully if the cleaned credentials are valid.

* **Scenario 2: Prevention of MongoDB injection attacks during registration.**
  * **Given** the user is on the registration screen.
  * **When** the user attempts to input malicious NoSQL code or query expressions (e.g., `{"$gt": ""}`) into the text fields.
  * **And** presses the "Create Profile" button.
  * **Then** the backend middleware must sanitize, cast to string, or reject the data before querying MongoDB.
  * **And** the system should return an invalid format error (HTTP 400) without exposing internal server details or stack traces.

* **Scenario 3: Prevention of double submission (Debounce/Loading state).**
  * **Given** the user is on the registration screen.
  * **When** the user presses the "Create Profile" button.
  * **Then** the button must immediately become disabled and show a loading indicator.
  * **And** the interface must completely ignore any subsequent clicks until the server responds or a timeout occurs.

---

### 🚪 EPIC 2: Login
**Epic Priority:** High  
**Description:** Authentication of preexisting users via secure flows, downloading saved state from the cloud, initializing local cache, and resolving conflicts between local and remote save states upon logging in.

#### 📜 US-TF-2-1: Back to Adventure!
* **Priority:** High  
* **Description:** As a player, I want to log in to continue my progress and avoid having to start over.

##### 🟢 HAPPY PATH
* **Scenario: Successful login with existing credentials.**
  * **Given** the player already has a registered account in the `Players` collection.
  * **When** they enter their registered email and correct password.
  * **And** press the "Enter the Kingdom" button.
  * **Then** the backend must validate the credentials using `bcrypt.compare()`.
  * **And** return a successful response containing the `playerId`, `username`, `max_level_reached`, and a valid JWT token.
  * **And** the token and session state must be saved locally with `SharedPreferences`.
  * **And** the player must be redirected to the Level Map screen at their last saved progress.

##### 🔴 SAD PATHS
* **Scenario 1: Login attempt with incorrect password.**
  * **Given** the player is on the login screen.
  * **When** they enter a registered email with an incorrect password.
  * **And** press the "Enter the Kingdom" button.
  * **Then** the backend must return an HTTP 401 Unauthorized error.
  * **And** the Flutter interface must display: `"Invalid credentials. Please try again."`
  * **And** the session must not be saved.

* **Scenario 2: Login attempt with non-existent email.**
  * **Given** the player is on the login screen.
  * **When** they enter an email that does not exist in the `Players` collection.
  * **And** press the "Enter the Kingdom" button.
  * **Then** the backend must return an HTTP 404 Not Found error.
  * **And** the Flutter interface must display: `"No account found with this email."`

* **Scenario 3: Timeout or slow network response while syncing progress.**
  * **Given** the player is on the main menu and has a poor internet connection.
  * **When** they select the "Continue Game" option.
  * **And** the request to `/profile/sync` takes longer than 10 seconds to respond.
  * **Then** the Flutter HTTP client must cancel the request due to a timeout error.
  * **And** the Flutter interface must display: `"Sync timed out. Would you like to load your local save instead?"`
  * **And** the application must offer interactive options to "Retry" or "Play Offline".

* **Scenario 4: Handling corrupted local cache files.**
  * **Given** the player is on the main menu and does not have internet access.
  * **When** they select the "Continue Game" option.
  * **And** the local database file (`SharedPreferences`/`Hive`) is found to be corrupted, unreadable, or modified illegally.
  * **Then** the Flutter application must catch the initialization error without crashing.
  * **And** the interface must display: `"Save file is corrupted. Please connect to the internet to restore your progress from the cloud."`
  * **And** the "Continue Game" action must be blocked until an active internet connection is verified.

##### ⚙️ EDGE CASES
* **Scenario 1: Conflict resolution when cloud progress is newer than local progress.**
  * **Given** the player is on the main menu and has an internet connection.
  * **When** they select the "Continue Game" option.
  * **And** the server detects that the MongoDB document updated timestamp is newer than the local client save timestamp.
  * **Then** the server must send the full cloud data package to the client.
  * **And** the Flutter application must display a modal dialog asking the player if they want to overwrite their local progress with the cloud save.
  * **And** the local state must update only after the player explicitly confirms the action.

* **Scenario 2: Session token expiration during sync request.**
  * **Given** the player has been inactive for a long period of time.
  * **When** they select the "Continue Game" option.
  * **And** the request to `/profile/sync` returns an HTTP 401 Unauthorized error due to an expired JWT.
  * **Then** the Flutter client must automatically attempt to refresh the session token via a refresh endpoint in the background.
  * **And** if token refresh succeeds, it must retry the sync request seamlessly without disrupting the user.
  * **And** if token refresh fails, it must clear the local session and redirect the user to the login screen with the message: `"Session expired. Please log in again."`

---

### 🎒 EPIC 3: Flexible Inventory Management (NoSQL Challenge)
**Epic Priority:** Critical  
**Description:** Designing and optimizing dynamic inventory management by leveraging the structured advantages of MongoDB (NoSQL). Handling arrays of embedded subdocuments for equipable items and consumables, capacity limits, and offline state persistence.

#### 📜 US-TF-3-1: Collecting Embedded Items
* **Priority:** Critical  
* **Description:** As a player, I want to collect different types of items (such as swords) to improve my stats, taking advantage of a flexible schema.

##### 🟢 HAPPY PATH
* **Scenario: Picking up a sword with specific attributes.**
  * **Given** the player has defeated an enemy or opened a chest.
  * **When** the player selects "Pick up sword".
  * **Then** the backend must execute an update query using the `$push` operator to add the sword subdocument to the player's inventory array inside the `inventories` collection.
  * **And** the embedded object must contain specific non-relational fields like `damage`, `durability`, and a unique `_id`.

##### 🔴 SAD PATHS
* **Scenario 1: The player attempts to pick up an item with a full inventory.**
  * **Given** the player's inventory array already contains exactly 30 items (maximum capacity allowed).
  * **When** the player selects "Pick up item".
  * **Then** the backend must validate the size of the array and reject the `$push` operation returning an HTTP 400 error.
  * **And** the Flutter interface must display: `"Inventory full! Free up space."`
  * **And** the item must not be added to the collection.

* **Scenario 2: Out of storage space during local save creation.**
  * **Given** the player has successfully synchronized their progress.
  * **When** the Flutter application attempts to write the latest state to the local hardware cache.
  * **And** the mobile device internal storage is completely full.
  * **Then** the Flutter application must catch the write/I-O exception without crashing the game engine.
  * **And** the interface must display: `"Storage full. Local progress cannot be saved. Free up space to prevent data loss."`

* **Scenario 3: Network disconnection during item acquisition causes data loss.**
  * **Given** the player is about to receive an item from a drop or quest completion.
  * **When** the internet connection drops exactly at the moment the item is acquired.
  * **And** the Flutter HTTP client fails to send or receive the update request to the backend.
  * **Then** the Flutter application must display a connection error banner.
  * **And** the acquired items must not be committed to the local database or MongoDB Atlas.
  * **And** the player state must cleanly revert to the last successfully synchronized server timestamp.

##### ⚙️ EDGE CASES
* **Scenario 1: Items added to overflow storage when main inventory is full.**
  * **Given** the player completes an event or action that rewards items.
  * **And** the player's main inventory array length is equal to 30 (completely full).
  * **When** the reward is processed on the MongoDB server side.
  * **Then** the backend must append the extra item subdocuments to an alternative `overflow` array inside the player's inventory document.
  * **And** the Flutter client must receive this status and display: `"Inventory full! Overflow items have been sent to temporary storage."`

* **Scenario 2: Preventing local data tampering or cheating.**
  * **Given** the player is playing the RPG in offline mode.
  * **When** the player modifies the local database files using external root/jailbreak tools to alter stats or append items.
  * **And** they reconnect to the internet to synchronize their progress with MongoDB Atlas.
  * **Then** the backend must validate the payload using a secure cryptographic checksum (HMAC/SHA256) generated by the app.
  * **And** if the checksum validation fails due to data manipulation, the server must reject the sync request.
  * **And** the system must completely overwrite the modified local progress with the legitimate cloud data retrieved from MongoDB.

---

#### 📜 US-TF-3-2: Using Consumables (Potions)
* **Priority:** High  
* **Description:** As a player, I want to use consumables from my inventory to restore my stats during my journey.

##### 🟢 HAPPY PATH
* **Scenario: The player uses a health potion.**
  * **Given** the player has a valid potion object inside their inventory array.
  * **When** they select "Use potion" from the Flutter user interface.
  * **Then** the backend must locate the document, remove that specific object from the inventory array using its unique `_id` via the `$pull` operator.
  * **And** it must execute an update to increment the player's health status variable in the main document.

##### 🔴 SAD PATHS
* **Scenario 1: Server error when attempting to use a health potion.**
  * **Given** the player has a potion in their inventory.
  * **When** they select "Use potion" from the Flutter interface.
  * **And** the backend returns an unexpected server error (HTTP 500).
  * **Then** the Flutter interface must catch the error and display: `"Unable to continue battle. Try again later."`
  * **And** the potion must remain intact and must not be removed from the inventory array.

* **Scenario 2: Attempting to use a health potion at maximum health.**
  * **Given** the player has a health potion in their inventory.
  * **And** the player's health status parameter is already at 100%.
  * **When** they attempt to select "Use potion" from the Flutter interface.
  * **Then** the Flutter application must intercept the action locally before hitting the server.
  * **And** the interface must display: `"Your health is already full."`
  * **And** the potion must not be consumed or removed.

* **Scenario 3: Mid-battle network disconnection while consuming an item.**
  * **Given** the player selects "Use potion" during an active online battle session.
  * **When** the internet connection drops before the Flutter client receives a successful response from the backend.
  * **Then** the Flutter interface must display a reconnection loading spinner and temporarily freeze all user battle actions.
  * **And** if the connection cannot be restored within a strict timeout, the game must roll back the local inventory and health state to the last verified server save state.

##### ⚙️ EDGE CASES
* **Scenar
