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
* **Scenario 1: Prevention of potion double usage (Cooldown/Debounce).**
  * **Given** the player is currently processing the usage of a health potion.
  * **When** they rapidly click or tap the "Use potion" button multiple times within milliseconds.
  * **Then** the Flutter interface must instantly disable the button widget during the UI animation and server request lifetime.
  * **And** the system must process only the first single request to prevent accidental consumption of multiple potions.

* **Scenario 2: Overhealing management when potion exceeds max health.**
  * **Given** the player has a health potion that restores 50 health points.
  * **And** the player's current health value is 80 out of 100.
  * **When** they select "Use potion" from the Flutter interface.
  * **Then** the MongoDB backend update logic must cap the updated health value at exactly 100 using mathematical constraints.
  * **And** it must remove the potion from the inventory array successfully.

* **Scenario 3: Simultaneous player defeat during potion usage.**
  * **Given** the player is in an active battle with very low health points.
  * **When** the player attempts to use a health potion at the exact same millisecond an enemy landing blow is processed.
  * **And** the server processes the enemy attack event first in the transaction queue.
  * **Then** the player status must be set to defeated.
  * **And** the pending potion usage request must be rejected, keeping the item in the inventory for the next game attempt.

---

## 🗺️ EPIC 4: Level Progress and Navigation
**Epic Priority:** Medium  
**Description:** Management of interactive world maps, control of level states through conditional logic ("Locked", "Unlocked", "Completed"), quest completion synchronization, and anti-cheat mechanisms for illegal level skipping.

#### 📜 US-TF-4-1: Locked/Unlocked Level Display
* **Priority:** Medium  
* **Description:** As a player, I want to view my progress through a level map so that I can see which challenges I have completed and which ones are still locked.

##### 🟢 HAPPY PATHS
* **Scenario 1: Successful synchronization upon leveling up.**
  * **Given** the player is currently playing Level 1.
  * **When** the player completes the victory conditions for Level 1.
  * **Then** the Flutter app must securely send a progress update request to the backend.
  * **And** the backend must validate the event and update the `max_level_reached` field to 2 in MongoDB Atlas.
  * **And** the mobile app must refresh the UI to dynamically show Level 2 as unlocked.

* **Scenario 2: Dynamic level menu visualization based on progress.**
  * **Given** the player has successfully completed Level `<max_level>`.
  * **And** the `max_level_reached` field in MongoDB has an exact value of `<max_level>`.
  * **When** the player accesses the Level Window screen.
  * **Then** the Flutter interface must display Level `<max_level>` as `"Completed"`.
  * **And** it must display Level `<unlocked_level>` as `"Unlocked"`.
  * **And** all levels higher than Level `<unlocked_level>` must appear with a lock icon and be unclickable.

  | max_level | unlocked_level |
  | :--- | :--- |
  | 1 | 2 |
  | 5 | 6 |

##### 🔴 SAD PATHS
* **Scenario 1: Network delay during synchronization.**
  * **Given** the player has just completed a level and the app is syncing with MongoDB.
  * **When** the server response takes longer than 10 seconds due to high latency or network congestion.
  * **Then** the Loading screen must update its text to exactly: `"Path Blocked"`.
  * **And** all UI inputs and interactive map nodes must remain disabled to prevent duplicate network requests.

* **Scenario 2: Connection failure and timeout after exceeding time limit.**
  * **Given** the app is in a Loading state attempting to connect to MongoDB.
  * **When** the network request hits the designated timeout threshold.
  * **Then** the app must safely abort the connection attempt.
  * **And** it must display the error identifier: `"Mission in delivery"`.
  * **And** it must show the message: `"Knight on the way"`.
  * **And** it must provide a `"Confused Knight"` button to allow the user to resend the request manually without losing the completed level data.

* **Scenario 3: Unexpected app closure during Loading state.**
  * **Given** the app was in a Loading state sending progress updates to MongoDB.
  * **When** the user force-closes the application or the device powers off unexpectedly.
  * **Then** upon restarting the application, the system must first check the local persistent cache and then perform a sync check with MongoDB Atlas.
  * **And** the level menu must display the actual recovered state without data corruption.

##### ⚙️ EDGE CASES
* **Scenario 1: Backend rejects illegal level skips (Anti-Cheat Validation).**
  * **Given** the `max_level_reached` field in MongoDB for the player is currently 1.
  * **When** the backend receives an HTTP update request claiming the player has completed Level 5.
  * **Then** the backend validation logic must reject the request with a validation error (HTTP 400).
  * **And** the `max_level_reached` field must remain unchanged in the database.
  * **And** the system should log a security flag on the server for suspicious activity tracking.

* **Scenario 2: Server-side idempotency on duplicate progress requests.**
  * **Given** the backend has already processed a request and set `max_level_reached` to 2 for the player.
  * **When** the backend receives an identical duplicate update request for the same Level 1 completion event.
  * **Then** the backend must not duplicate any associated rewards, experience, or alter the database state.
  * **And** it must return a standard successful response (HTTP 200/204) to allow the client to sync and clear its local flags correctly.

* **Scenario 3: Resolution of progress conflicts during startup (Cloud Wins).**
  * **Given** the player's local cache on Device A indicates `max_level_reached` is 2.
  * **And** the MongoDB database updated via a prior session on Device B indicates `max_level_reached` is 5.
  * **When** the application starts on Device A and executes the initial synchronization routine.
  * **Then** the system must resolve the conflict automatically by adopting the higher value from the cloud (Level 5).
  * **And** the local cache on Device A must be overwritten with the cloud data.
  * **And** the Level Menu must display up to Level 6 as Unlocked.

---

## 🚪 EPIC 5: Safe Exit and Persistence
**Epic Priority:** Low  
**Description:** Implementation of controlled confirmation dialogs when exiting the application, interception of native operating system gestures, and ensuring data persistence in memory/disk before the app process closes.

#### 📜 US-TF-5-1: Exit Confirmation
* **Priority:** Low  
* **Description:** As a player, I want to be able to close the application in a controlled manner, ensuring my data is not lost.

##### 🟢 HAPPY PATHS
* **Scenario 1: Closing the application from the Main Menu (Confirming Exit).**
  * **Given** the player is on the main menu screen.
  * **When** they press the "Exit" button.
  * **Then** a custom modal pop-up confirmation dialog must appear in Flutter with distinct "Yes" and "No" choice buttons.
  * **And** upon pressing "Yes", the application must securely commit any pending cache data to disk and cleanly close the application process.

* **Scenario 2: Canceling application exit from the confirmation pop-up.**
  * **Given** the player is currently viewing the exit confirmation pop-up.
  * **When** they press the "No" button.
  * **Then** the pop-up dialog must disappear instantly.
  * **And** the user must return to the active, interactive main menu screen.

##### 🔴 SAD PATHS
* **Scenario 1: Closing the confirmation pop-up using the standard "X" button.**
  * **Given** the player is viewing the exit confirmation pop-up.
  * **When** they press the generic "X" button on the top corner of the pop-up modal.
  * **Then** the pop-up must close without triggering any exit routines.
  * **And** the user must remain on the active main menu screen.

* **Scenario 2: Preventing controlled exit during active cloud synchronization.**
  * **Given** the application is actively communicating with MongoDB Atlas to sync progress or items.
  * **When** the player attempts to trigger the exit sequence.
  * **Then** the application must temporarily disable or defer the exit command until the network transaction completes.
  * **And** it must ensure the database transaction finishes successfully before allowing the user to quit.

##### ⚙️ EDGE CASES
* **Scenario 1: Intercepting system back button or gesture on the Main Menu.**
  * **Given** the player is on the main menu screen.
  * **When** the player presses the mobile device's native hardware "Back" button or triggers the native Android/iOS back gesture.
  * **Then** the Flutter application must intercept the action using a `PopScope` or `WillPopScope` widget.
  * **And** it must force display the same custom exit confirmation pop-up dialog with "Yes" and "No" choices.

* **Scenario 2: Secure data persistence during a controlled application exit.**
  * **Given** the player has active session data, temporary progress flags, or uncommitted items in RAM memory.
  * **And** the exit confirmation pop-up is currently displayed.
  * **When** the player presses the "Yes" button.
  * **Then** the Flutter app must execute an immediate synchronous write operation to the local persistent cache file.
  * **And** once the local save file integrity is successfully verified, the application process must terminate cleanly.

---

## 📴 EPIC 6: Offline Mode & Local Persistence (Mobile Only)
**Epic Priority:** High  
**Description:** Offline lifecycle support for mobile devices using the local embedded database Hive. Automatic foreground or background data synchronization upon detecting connectivity, mobile device timestamp anti-cheat verification, and "Last-Write-Wins" conflict resolution algorithms.

#### 📜 US-TF-6-1: Offline Gameplay with Local Cache
* **Priority:** High  
* **Description:** As a mobile player, I want to be able to play without an internet connection so that my progress is saved locally and I can continue my adventure at any time.

##### 🟢 HAPPY PATH
* **Scenario: Player launches the app without internet connection.**
  * **Given** the mobile player has previously logged in with internet at least once.
  * **And** their progress has been cached locally in `Hive`.
  * **When** they open the app without an active internet connection.
  * **Then** the app must automatically load the last saved local state from `Hive`.
  * **And** display a non-blocking in-game warning banner: `"Offline Mode — Progress will sync when you reconnect."`
  * **And** allow the player to navigate the level map and play battle loops normally.

##### 🔴 SAD PATHS
* **Scenario 1: Player launches the app without internet and no local data.**
  * **Given** the mobile player has never logged in before on this device.
  * **And** there is no active internet connection.
  * **When** they open the app.
  * **Then** the app must block entry and display: `"No local progress found. Connect to the internet to download your save file."`
  * **And** the player must not be able to access the core game screens.

* **Scenario 2: Local Hive database is corrupted.**
  * **Given** the mobile player opens the app without internet.
  * **And** the local `Hive` database file structure is corrupted, unreadable, or throwing a deserialization error.
  * **When** the app tries to load local data at initialization.
  * **Then** the app must detect the corruption error, catch the exception, and display: `"The evil Malakor has interrupted your process! Return to your mission."`
  * **And** attempt to restore or pull data from MongoDB Atlas if an internet connection becomes available later.

* **Scenario 3: Device storage is full and cannot save local progress.**
  * **Given** the mobile player is playing in Offline Mode.
  * **And** the device internal storage is completely full.
  * **When** the app tries to write progress updates locally to `Hive`.
  * **Then** the app must catch the storage exception and display: `"Too much weight in your backpack! Free up some space."`
  * **And** the player must not lose their current volatile session progress in RAM until the app process is closed.

* **Scenario 4: App closes unexpectedly while saving local progress.**
  * **Given** the mobile player is playing in Offline Mode.
  * **And** the app is in the middle of writing data packets to `Hive`.
  * **When** the app crashes or is forcefully terminated by the OS.
  * **Then** upon reopening, the app must detect an incomplete or unclosed database transaction flag.
  * **And** roll back to the last valid checkpoint saved in `Hive`.
  * **And** display: `"Your last session was interrupted. Progress restored to last checkpoint."`

##### ⚙️ EDGE CASES
* **Scenario 1: Validating local timestamps to prevent device time cheating.**
  * **Given** the player is playing offline.
  * **And** the player manually changes their mobile device's system clock to a future date to skip time gates.
  * **When** the player completes a level and the local cache saves the progress with the altered timestamp.
  * **And** the internet connection is subsequently restored.
  * **Then** the system must validate the local timestamp against an NTP network time or the backend server time during synchronization.
  * **And** if an unrealistic or illegal discrepancy is detected, the server time must overwrite the session data, discarding the fraudulent timeline.

* **Scenario 2: High-frequency network instability during synchronization.**
  * **Given** the player is transitioning from offline to online mode with pending data packets in the local cache.
  * **When** the internet connection repeatedly drops and reconnects rapidly (network flapping) during the synchronization process.
  * **Then** the application must implement a debounced stabilization period of exactly 3 seconds of solid connectivity before executing the network request.
  * **And** it must strictly prevent partial or corrupted data packets from being transmitted to MongoDB Atlas.

---

#### 📜 US-TF-6-2: Automatic Cloud Sync on Reconnection
* **Priority:** High  
* **Description:** As a mobile player, I want my offline progress to be automatically uploaded to MongoDB Atlas when I reconnect to the internet, so that my data is never lost.

##### 🟢 HAPPY PATH
* **Scenario: Player reconnects to the internet after playing offline.**
  * **Given** the mobile player has been playing in Offline Mode.
  * **And** their progress is saved locally in `Hive`.
  * **When** the application connectivity listener detects an active internet connection.
  * **Then** the app must automatically trigger an upload sync of all local progress changes to MongoDB Atlas.
  * **And** display a toast message: `"Progress saved to the cloud ☁️"`
  * **And** the local Hive data signatures must match the MongoDB Atlas cloud document exactly.

##### 🔴 SAD PATHS
* **Scenario 1: Connection is lost in the middle of synchronization.**
  * **Given** the mobile player has reconnected to the internet.
  * **And** the app has started syncing local progress to MongoDB Atlas.
  * **When** the internet connection is broken mid-sync.
  * **Then** the app must halt the sync operation immediately.
  * **And** keep the local `Hive` data intact without performing partial writes, updates, or corrupting state in Atlas.
  * **And** display: `"Sync interrupted. We'll try again when you reconnect."`
  * **And** automatically queue a retry when connectivity is officially restored.

* **Scenario 2: MongoDB Atlas is unavailable during sync.**
  * **Given** the mobile player has reconnected to the internet.
  * **And** MongoDB Atlas returns a cluster error or server fault (HTTP 500).
  * **When** the app tries to sync local progress.
  * **Then** the app must keep the local `Hive` data intact.
  * **And** display: `"Could not sync progress. We'll try again later."`
  * **And** retry the sync automatically after a backoff period of 30 seconds.

* **Scenario 3: Local data is incomplete or missing required fields during sync.**
  * **Given** the mobile player tries to sync after reconnecting.
  * **And** the local `Hive` data is missing critical structural fields (e.g., `playerId` is null due to corruption).
  * **When** the app tries to build the sync JSON payload.
  * **Then** the app validation layer must detect the missing fields.
  * **And** abort the sync operation immediately to prevent uploading corrupted schemas.
  * **And** display: `"Sync failed due to incomplete local data. Please log in again."`
  * **And** redirect the player to the login screen for fresh data fetching.

##### ⚙️ EDGE CASES
* **Scenario 1: Automatic background synchronization when internet is restored.**
  * **Given** the player has pending progress saved in the local cache.
  * **And** the application process is running suspended in the background.
  * **When** the operating system network provider detects that the internet connection has been restored.
  * **Then** the application must trigger a silent background worker task to securely stream the saved data to MongoDB Atlas.
  * **And** after successful confirmation from the server, the local cache must safely clear its pending synchronization flags.

* **Scenario 2: Forced emergency backup when exiting with full storage.**
  * **Given** the application is holding the current session's progress exclusively in RAM due to a full disk storage error.
  * **When** the player attempts to exit the game or the OS triggers a low memory warning threat.
  * **Then** the application must attempt to compress the progress data structure to its smallest possible binary size.
  * **And** make a final emergency attempt to write the compressed progress file to the local cache or fire a lightweight socket request before termination.

---

#### 📜 US-TF-6-3: Conflict Resolution (Local vs Cloud)
* **Priority:** Medium  
* **Description:** As a mobile player, I want the application to handle conflicts between my local and cloud progress intelligently, so that I never lose my most recent achievements.

##### 🟢 HAPPY PATHS
* **Scenario 1: Local progress is newer than cloud progress.**
  * **Given** the mobile player played offline and advanced up to level 3.
  * **And** MongoDB Atlas cloud document still shows level 2.
  * **When** the app syncs after reconnecting to the internet.
  * **Then** the app must evaluate timestamps and detect that local progress is newer.
  * **And** upload the local state to MongoDB Atlas using an upsert operation.
  * **And** the cloud document must reflect level 3.

* **Scenario 2: Cloud progress is newer than local progress.**
  * **Given** the mobile player logged in on another device and advanced to level 4.
  * **And** the local `Hive` cache on the current phone still shows level 2.
  * **When** the app syncs after reconnecting.
  * **Then** the app must evaluate timestamps and detect that cloud progress is newer.
  * **And** completely overwrite the local `Hive` cache with the MongoDB Atlas version.
  * **And** the player must continue seamlessly from level 4.

##### 🔴 SAD PATHS
* **Scenario 1: Neither local nor cloud data is valid.**
  * **Given** the mobile player tries to sync after reconnecting.
  * **And** the local `Hive` data is structurally corrupted.
  * **And** MongoDB Atlas returns an empty or invalid corrupted document.
  * **When** the app tries to execute the conflict resolution engine.
  * **Then** the app must catch the validation exception and detect that neither source is a reliable source of truth.
  * **And** display: `"We could not recover your progress. Please contact support."`
  * **And** redirect the player to the login screen while creating a local error log with the details of the conflict for debugging.

* **Scenario 2: Device clock is misconfigured causing incorrect conflict resolution.**
  * **Given** the mobile player's device clock is set to an incorrect date or time manually.
  * **And** the app uses timestamps to determine which progress is newer.
  * **When** the app tries to resolve the conflict upon reconnection.
  * **Then** the app must detect the timestamp anomaly by cross-referencing server time.
  * **And** default to the MongoDB Atlas version as the absolute source of truth.
  * **And** display: `"Your device clock appears to be incorrect. Cloud progress has been loaded."`

##### ⚙️ EDGE CASES
* **Scenario 1: Player has two active sessions on different devices simultaneously.**
  * **Given** the mobile player is logged in on their phone in Offline Mode.
  * **And** the same player is also logged in on a tablet device with an active internet connection.
  * **And** both separate sessions generate different progress parameters simultaneously.
  * **When** both sessions try to write or sync data to MongoDB Atlas.
  * **Then** the MongoDB backend validation layers must detect the simultaneous write conflict transaction.
  * **And** apply a strict "last-write-wins" strategy based exclusively on the server-side reception timestamp.
  * **And** notify both active sessions: `"Your progress has been updated from another device."`
  * **And** force reload the most recent state from MongoDB Atlas on both user device viewports.

---

## 4. Action Plan & Task Breakdown

The action plan spans across the 4 weeks to ensure clean, modular development with robust testing:

### ⚙️ Core Architecture & Database (42h total)
* Initialize the Flutter project structured under Clean Architecture by layers: **10h**
* Set up the base Node.js/Express server and configure connection to the MongoDB Atlas cluster: **10h**
* Design and validate Mongoose schemas (`User`, `PlayerStats`, `Inventory`): **10h**
* Implement robust authentication using JWT and security middlewares (bcrypt): **12h**

### 🎮 Combat Mechanics & Map Flow (50h total)
* Design backend logical loop for combat (Turn-based calculation of Damage/Defense/HP): **18h**
* Develop user interfaces in Flutter (Login, Interactive Map for Levels 1-3, Combat Screen): **18h**
* Develop controllers and routes for progress updates (`PATCH /player/level`): **14h**

### 🧪 QA, Test Data & Documentation (46h total)
* Create data seeding scripts to populate base monsters for levels 1, 2, and 3: **10h**
* Execute manual and integrated E2E tests (Register ➔ Login ➔ Level 1 Battle ➔ Save progress): **18h**
* Draft the Software Requirements Specification (SRS) document and API technical reference in `README.md`: **18h**

---

## 5. Weekly Execution Roadmap

### 🗓️ Week 1: Technical Foundations and Database (Est. 34h)
* **Focus:** Basic network connectivity and initial data persistence.
* **Friday Milestone:** Active MongoDB Atlas cluster with validated schemas and initial Node.js server structure running locally.

### 🗓️ Week 2: Authentication and Base Interfaces (Est. 36h)
* **Focus:** Security and initial user flow.
* **Friday Milestone:** Registration and login flow completely functional from the Flutter mobile app to MongoDB Atlas using `bcrypt` encryption and JWT.

### 🗓️ Week 3: Combat Logic and Level Map (Est. 36h)
* **Focus:** Core gameplay framework design.
* **Friday Milestone:** Flutter map renders level nodes and backend engine calculates damage for "Attack" and "Defend" actions.

### 🗓️ Week 4: End-to-End Integration, QA, and Wrap-up (Est. 32h)
* **Focus:** Consolidation, local/offline testing, and technical documentation.
* **Friday Milestone:** **Walking Skeleton Completed.** A new user can register, navigate the map, sequentially clear three levels while saving progress to the cloud (Atlas) or local storage (Hive), and securely log out.

---

## 6. Impediments & Dependencies

* **Strict Dependency:** The Flutter frontend development team cannot link or give full functionality to the world map or combat views until the database schemas, controllers, and HTTP routes are ready and exposed by the backend team.
* **Technical Risk:** Learning curve when connecting asynchronous HTTP calls in Flutter with Clean Architecture and native synchronization with Hive/SharedPreferences, which could consume part of the buffer time.

---

## 7. Definition of Done (DoD)

- [ ] The source code compiles 100% without critical warnings or errors in both Node.js and Flutter environments.
- [ ] User account passwords are encrypted using a hash with `bcrypt` before impacting the Atlas database.
- [ ] All created REST API routes are listed, explained, and exemplified inside the `README.md` file.
- [ ] Cross end-to-end testing has been executed, validating the complete gameplay flow successfully on an emulator or physical device, including offline states.

---

## 👥 8. Task Distribution by Team Member

| Team Member | Primary Role / Responsibility | Linked User Stories |
| :--- | :--- | :--- |
| **Sánchez Marín María del Rosario** | **Data Modeler:** Design collections (`users`, `inventories`, `player_stats`). MongoDB Atlas cluster setup and security. | US-TF-1-1, US-TF-3-1, US-TF-3-2 |
| **Rojas González Ulisses** | **Query Developer:** Express routing, JWT generation and validation, backend damage logic, and level patch management. | US-TF-1-1, US-TF-2-1, US-TF-4-1 |
| **Valiente Marín Yoanna** | **Integration Specialist:** Flutter project layer architecture, HTTP/API service consumption layer, Login screen, Level Map, and Combat UI. | US-TF-1-1, US-TF-2-1, US-TF-4-1, US-TF-5-1 |
| **Velázquez Reyes Axel Judá** | **Data Seeder / QA:** Monster population scripts, automated/manual integration testing, and black-box verification of E2E flows and NoSQL injections. | Sprint Quality Control / Sad & Edge Criteria |
| **Virgen Juárez Camila** | **Scrum Master:** Task board management, impediment mitigation, drafting the SRS document, and endpoint reference manual. | General Sprint Documentation and Closing |
