# PRODUCT BACKLOG / NEXUS RPG — THE CROWN SCHISM

---

## 🎯 Product Goal

Our goal is to build the core foundation and the first gameplay experience for "Nexus RPG — The Crown Schism". We want to make sure players can create secure profiles, manage their backpacks and items with total freedom, watch their progress unlock visually on the map, and feel confident that their hard-earned game saves are always safe, smooth, and protected.

---

## 🗺️ Epics

- **Epic 1:** Authentication and Profile System
- **Epic 2:** Login
- **Epic 3:** Flexible Inventory Management (NoSQL Challenge)
- **Epic 4:** Level Progress and Navigation
- **Epic 5:** Safe Exit and Persistence
- **Epic 6:** Offline Mode & Local Persistence *(Mobile Only)*

---

## 📝 User Stories & Acceptance Criteria

---

### Epic 1: Authentication and Profile System

#### US-TF-1-1: New User Registration

- **Priority:** High
- **Description:** As a player, I want to have a unique account so that my progress and inventory are securely saved in the cloud.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: Successful registration of a new warrior.
  Given the user is on the home screen.
  When they enter a unique username, a valid email, and a secure password.
  And they press the "Create Profile" button.
  Then the system must create a new document in the Players collection in MongoDB.
  And it must initialize an inventory with an Iron Sword and a Health Potion.
  And the session must be saved locally with SharedPreferences.
  And the user must be redirected to the Level Map screen.

# ❌ SAD PATH 1
Scenario: Attempted registration with an existing email address.
  Given the user is on the registration screen.
  And the entered email address already exists in the Players collection.
  When the user presses the "Create Profile" button.
  Then the MongoDB backend should return a duplicate key error.
  And the Flutter interface should display: "This email address is already registered."
  And no new document should be created in the Players collection.

# ❌ SAD PATH 2
Scenario: Attempted registration with an existing username.
  Given the user is on the registration screen.
  And the entered username already exists in the Players collection.
  When the user presses the "Create Profile" button.
  Then the MongoDB backend should return a duplicate key error.
  And the Flutter interface should display: "This username is already in use."
  And no new document should be created in the Players collection.

# ❌ SAD PATH 3
Scenario: Registration attempt with empty fields.
  Given the user is on the registration screen.
  When the user leaves one or more required fields blank.
  And clicks the "Create Profile" button.
  Then the Flutter interface should display: "You must complete all required fields."
  And no request should be sent to the server.

# ❌ SAD PATH 4
Scenario: Registration attempt with an invalid email address.
  Given the user is on the registration screen.
  When the user enters an email address that does not contain the "@" symbol.
  And clicks the "Create Profile" button.
  Then the Flutter interface should display: "The email address is invalid."
  And no request should be sent to the server.
  And the registration must not be completed.

# ❌ SAD PATH 5
Scenario: Attempted registration with an insecure password.
  Given the user is on the registration screen.
  When the user enters a password that does not meet security requirements
  (minimum 8 characters, uppercase, lowercase, numbers, and special characters).
  And presses the "Create Profile" button.
  Then the Flutter interface should display: "Use numbers, lowercase letters, uppercase letters, and special characters with a minimum of 8 characters."
  And no new document should be created in the Players collection.

# ❌ SAD PATH 6
Scenario: Attempted registration without a server connection.
  Given the user is on the registration screen.
  And the server is down or unavailable.
  When the user completes all fields correctly.
  And presses the "Create Profile" button.
  Then the Flutter interface should intercept the connection error.
  And display: "Could not connect to the server. Please try again later."
  And no document should be created in the Players collection.

# ❌ SAD PATH 7
Scenario: Attempted registration with invalid username length or characters.
  Given the user is on the registration screen.
  When the user enters a username shorter than 3 characters, longer than 15 characters,
  or containing special characters.
  And presses the "Create Profile" button.
  Then the Flutter interface should display: "The username must be between 3 and 15 characters long and contain only letters and numbers."
  And no request should be sent to the server.

# ❌ SAD PATH 8
Scenario: Attempted registration with mismatched passwords.
  Given the user is on the registration screen.
  When the user enters a valid password.
  And enters a different password in the "Confirm password" field.
  And presses the "Create Profile" button.
  Then the Flutter interface should display: "Passwords do not match."
  And no request should be sent to the server.

# ❌ SAD PATH 9
Scenario: Username case insensitivity check.
  Given the user is on the registration screen.
  And a player with the username "KnightKing" already exists in the collection.
  When a new user attempts to register with the username "knightking".
  And presses the "Create Profile" button.
  Then the MongoDB backend should detect the duplication regardless of the case.
  And the Flutter interface should display: "This username is already in use."
  And no new document should be created in the Players collection.

# ⚙️ EDGE CASE 1
Scenario: Automatic trimming of whitespace in registration fields.
  Given the user is on the registration screen.
  When the user enters an email or username with leading or trailing whitespaces.
  And presses the "Create Profile" button.
  Then the Flutter application should automatically trim the whitespaces before validating or sending data.
  And the registration should proceed successfully if the credentials are valid.

# ⚙️ EDGE CASE 2
Scenario: Prevention of MongoDB injection attacks during registration.
  Given the user is on the registration screen.
  When the user attempts to input malicious code or query expressions into the text fields.
  And presses the "Create Profile" button.
  Then the backend must reject or sanitize the data before querying MongoDB.
  And the system should return an invalid format error without exposing internal server details.

# ⚙️ EDGE CASE 3
Scenario: Prevention of double submission (Debounce/Loading state).
  Given the user is on the registration screen.
  When the user presses the "Create Profile" button.
  Then the button should immediately become disabled and show a loading indicator.
  And the interface must ignore any subsequent clicks until the server responds.
```

---

### Epic 2: Login

#### US-TF-2-1: Back to Adventure!

- **Priority:** High
- **Description:** As a player, I want to log in to continue my progress and avoid having to start over.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: Successful login with existing credentials.
  Given the player already has a registered account in the Players collection.
  When they enter their registered email and correct password.
  And press the "Enter the Kingdom" button.
  Then the backend must validate the credentials using bcrypt.
  And return the playerId, username, and max_level_reached.
  And the session must be saved locally with SharedPreferences.
  And the player must be redirected to the Level Map screen at their last saved progress.

# ❌ SAD PATH 1
Scenario: Login attempt with incorrect password.
  Given the player is on the login screen.
  When they enter a registered email with an incorrect password.
  And press the "Enter the Kingdom" button.
  Then the backend must return a 401 Unauthorized error.
  And the Flutter interface must display: "Invalid credentials. Please try again."
  And the session must not be saved.

# ❌ SAD PATH 2
Scenario: Login attempt with non-existent email.
  Given the player is on the login screen.
  When they enter an email that does not exist in the Players collection.
  And press the "Enter the Kingdom" button.
  Then the backend must return a 404 Not Found error.
  And the Flutter interface must display: "No account found with this email."

# ❌ SAD PATH 3
Scenario: Timeout or slow network response while syncing progress.
  Given the player is on the main menu and has a poor internet connection.
  When they select the "Continue Game" option.
  And the request to "/profile/sync" takes longer than 10 seconds to respond.
  Then the Flutter client must cancel the request due to a timeout error.
  And the Flutter interface must display: "Sync timed out. Would you like to load your local save instead?"
  And the application must offer options to "Retry" or "Play Offline".

# ❌ SAD PATH 4
Scenario: Handling corrupted local cache files.
  Given the player is on the main menu and does not have internet access.
  When they select the "Continue Game" option.
  And the local database file is found to be corrupted or unreadable.
  Then the Flutter application must catch the initialization error.
  And the interface must display: "Save file is corrupted. Please connect to the internet to restore your progress from the cloud."
  And the "Continue Game" action must be blocked until an internet connection is established.

# ⚙️ EDGE CASE 1
Scenario: Conflict resolution when cloud progress is newer than local progress.
  Given the player is on the main menu and has an internet connection.
  When they select the "Continue Game" option.
  And the server detects that the MongoDB document timestamp is newer than the local client timestamp.
  Then the server must send the cloud data to the client.
  And the Flutter application must display a dialog asking the player if they want to overwrite their local progress.
  And the local state must update only after the player confirms the action.

# ⚙️ EDGE CASE 2
Scenario: Session token expiration during sync request.
  Given the player has been inactive for a long period.
  When they select the "Continue Game" option.
  And the request to "/profile/sync" returns an HTTP 401 Unauthorized error.
  Then the Flutter client must automatically attempt to refresh the session token in the background.
  And if token refresh succeeds, it must retry the sync request seamlessly.
  And if token refresh fails, it must redirect the user to the login screen with the message: "Session expired. Please log in again."
```

---

### Epic 3: Flexible Inventory Management (NoSQL Challenge)

#### US-TF-3-1: Collecting Embedded Items

- **Priority:** Critical
- **Description:** As a player, I want to collect different types of items (like swords) to improve my stats, taking advantage of a flexible schema.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: Picking up a sword with specific attributes.
  Given the player has defeated an enemy or found a chest.
  When the player selects "Pick up sword".
  Then the backend must use the $push operator to add the sword object to the player's inventory array.
  And the object must contain the specific fields damage and durability.

# ❌ SAD PATH 1
Scenario: The player attempts to pick up an item with a full inventory.
  Given the player's inventory array already contains 30 items (maximum capacity).
  When the player selects "Pick up item".
  Then the backend must reject the $push operation.
  And the Flutter interface must display: "Inventory full! Free up space."
  And the item must not be added to the inventory.

# ❌ SAD PATH 2
Scenario: Out of storage space during local save creation.
  Given the player has successfully synchronized their progress.
  When the Flutter application attempts to write the latest state to the local cache.
  And the device storage is full.
  Then the Flutter application must catch the storage error without crashing the game.
  And the interface must display: "Storage full. Local progress cannot be saved. Free up space to prevent data loss."

# ❌ SAD PATH 3
Scenario: Network disconnection during item acquisition causes data loss.
  Given the player is about to receive an item from a drop or quest.
  When the internet connection drops at the moment the item is acquired.
  And the Flutter client fails to send the update request to the backend.
  Then the Flutter application must display a connection error message.
  And the acquired items must not be saved to the local database or MongoDB.
  And the player state must revert to the last successfully synchronized timestamp.

# ⚙️ EDGE CASE 1
Scenario: Items added to overflow storage when main inventory is full.
  Given the player completes an action that rewards items.
  And the player's main inventory is completely full.
  When the reward is processed by the server.
  Then the MongoDB backend must append the extra items to an overflow array inside the player document.
  And the Flutter client must display: "Inventory full! Overflow items have been sent to temporary storage."

# ⚙️ EDGE CASE 2
Scenario: Preventing local data tampering or cheating.
  Given the player is playing in offline mode.
  When the player modifies the local database file using external tools to alter stats or inventory.
  And they reconnect to the internet to sync their progress.
  Then the backend must validate the local save file using a secure checksum.
  And if the checksum validation fails, the server must reject the sync request.
  And the system must overwrite the modified local progress with the legitimate cloud data from MongoDB.
```

#### US-TF-3-2: Using Consumables (Potions)

- **Priority:** High
- **Description:** As a player, I want to use consumables from my inventory to restore my attributes during my journey.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: The player uses a health potion.
  Given the player has a potion in their inventory array.
  When they select "Use potion" from the Flutter interface.
  Then the backend must remove that specific object from the inventory array using its _id.
  And it must update the player's health status in the main document.

# ❌ SAD PATH 1
Scenario: Server error when attempting to use a health potion.
  Given the player has a potion in their inventory.
  When they select "Use potion" from the Flutter interface.
  And the backend returns an unexpected server error (500).
  Then the Flutter interface must display: "Unable to continue battle. Try again later."
  And the potion must not be removed from the inventory.

# ❌ SAD PATH 2
Scenario: Attempting to use a health potion at maximum health.
  Given the player has a health potion in their inventory.
  And the player's health status is already at 100%.
  When they attempt to select "Use potion" from the Flutter interface.
  Then the Flutter application must intercept the action before calling the server.
  And the interface must display: "Your health is already full."
  And the potion must not be removed from the inventory.

# ❌ SAD PATH 3
Scenario: Mid-battle network disconnection while consuming an item.
  Given the player selects "Use potion" during an active battle session.
  When the internet connection drops before the Flutter client receives a response from the backend.
  Then the Flutter interface must display a reconnection loader and temporarily pause battle actions.
  And if the connection cannot be restored, the game must revert the local inventory and health state to the last verified server save.

# ⚙️ EDGE CASE 1
Scenario: Prevention of potion double usage (Cooldown/Debounce).
  Given the player is using a health potion.
  When they rapidly tap the "Use potion" button multiple times.
  Then the Flutter interface must temporarily disable the button during the animation and server request.
  And the system must process only the first request to prevent accidental consumption of multiple items.

# ⚙️ EDGE CASE 2
Scenario: Overhealing management when potion exceeds max health.
  Given the player has a health potion that restores 50 health points.
  And the player's current health is 80 out of 100.
  When they select "Use potion" from the Flutter interface.
  Then the MongoDB backend must cap the updated health value at exactly 100.
  And it must remove the potion from the inventory successfully.

# ⚙️ EDGE CASE 3
Scenario: Simultaneous player defeat during potion usage.
  Given the player is in an active battle with very low health.
  When the player attempts to use a health potion at the exact same moment an enemy lands a fatal blow.
  And the server processes the enemy attack event first.
  Then the player status must be set to defeated.
  And the potion request must be rejected, keeping the potion in the inventory for the next attempt.
```

---

### Epic 4: Level Progress and Navigation

#### US-TF-4-1: Locked/Unlocked Level Display

- **Priority:** Medium
- **Description:** As a player, I want to visualize my progress through a level map so I can see which challenges I have completed and which are still locked.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH 1
Scenario: Successful synchronization upon leveling up.
  Given the player is currently playing Level 1.
  When the player completes the victory conditions for Level 1.
  Then the Flutter app must securely send the update request to the backend.
  And the backend must validate the data and update the max_level_reached field to 2 in MongoDB.
  And the app must refresh the UI to show Level 2 as unlocked.

# ✅ HAPPY PATH 2
Scenario Outline: Dynamic level menu visualization based on progress.
  Given the player has successfully completed Level <max_level>.
  And the max_level_reached field in MongoDB has a value of <max_level>.
  When the player accesses the Level Window screen.
  Then the Flutter interface must display Level <max_level> as "Completed".
  And it must display Level <unlocked_level> as "Unlocked".
  And all levels higher than Level <unlocked_level> must appear with a lock icon.

  Examples:
    | max_level | unlocked_level |
    | 1         | 2              |
    | 5         | 6              |

# ❌ SAD PATH 1
Scenario: Network delay during synchronization.
  Given the player has just completed a level and the app is syncing with MongoDB.
  When the server response takes longer than 10 seconds due to high latency.
  Then the Loading screen must update its text to: "Camino bloqueado".
  And all UI inputs must remain disabled to prevent duplicate requests.

# ❌ SAD PATH 2
Scenario: Connection failure and timeout after exceeding time limit.
  Given the app is in a Loading state attempting to connect to MongoDB.
  When the network request hits the designated timeout threshold.
  Then the app must safely abort the connection attempt.
  And it must display the error identifier: "Mision en entrega".
  And it must show the message: "Caballero en camino".
  And it must provide a "Caballero confundida" button to resend the request without losing the completed level data.

# ❌ SAD PATH 3
Scenario: Unexpected app closure during Loading state.
  Given the app was in a Loading state sending progress to MongoDB.
  When the user force-closes the application or the device powers off.
  Then upon restarting, the system must first check the local cache and then sync with MongoDB.
  And the level menu must display the actual recovered state.

# ⚙️ EDGE CASE 1
Scenario: Backend rejects illegal level skips (Anti-Cheat Validation).
  Given the max_level_reached field in MongoDB for the player is currently 1.
  When the backend receives an update request claiming the player completed Level 5.
  Then the backend must reject the request with a validation error.
  And the max_level_reached field must remain unchanged.
  And the system should log a security flag for suspicious activity.

# ⚙️ EDGE CASE 2
Scenario: Server-side idempotency on duplicate progress requests.
  Given the backend has already processed and set max_level_reached to 2 for the player.
  When the backend receives a duplicate update request for the same Level 1 completion.
  Then the backend must not duplicate any associated rewards or alter the database state.
  And it must return a successful response to allow the client to sync correctly.

# ⚙️ EDGE CASE 3
Scenario: Resolution of progress conflicts during startup (Cloud Wins).
  Given the player's local cache on Device A indicates max_level_reached is 2.
  And the MongoDB database updated via Device B indicates max_level_reached is 5.
  When the application starts on Device A and performs the initial synchronization.
  Then the system must resolve the conflict by adopting the higher value from the cloud (Level 5).
  And the local cache must be overwritten with the cloud data.
  And the Level Menu must display up to Level 6 as Unlocked.
```

---

### Epic 5: Safe Exit and Persistence

#### US-TF-5-1: Exit Confirmation

- **Priority:** Low
- **Description:** As a player, I want to be able to close the application in a controlled manner, ensuring my data is not lost.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH 1
Scenario: Closing the application from the Main Menu (Confirming Exit).
  Given the player is on the main menu.
  When they press the "Exit" button.
  Then a pop-up confirmation dialog must appear in Flutter with "Yes" and "No" options.
  And upon pressing "Yes", the application must securely save any pending data and close the application process.

# ✅ HAPPY PATH 2
Scenario: Canceling application exit from the confirmation pop-up.
  Given the player is viewing the exit confirmation pop-up.
  When they press the "No" button.
  Then the pop-up must disappear.
  And the user must return to the active main menu screen.

# ❌ SAD PATH 1
Scenario: Closing the confirmation pop-up using the standard "X" button.
  Given the player is viewing the exit confirmation pop-up.
  When they press the "X" button on the top corner of the pop-up.
  Then the pop-up must close without exiting the application.
  And the user must remain on the active main menu screen.

# ❌ SAD PATH 2
Scenario: Preventing controlled exit during active cloud synchronization.
  Given the application is actively communicating with MongoDB to sync progress.
  When the player attempts to trigger the exit sequence.
  Then the application must temporarily disable the exit command until the network request completes.
  And it must ensure the database transaction finishes successfully before allowing the user to quit.

# ⚙️ EDGE CASE 1
Scenario: Intercepting system back button or gesture on the Main Menu.
  Given the player is on the main menu screen.
  When the player presses the device's native hardware "Back" button.
  Then the application must intercept the action.
  And it must display the same exit confirmation pop-up with "Yes" and "No" options.

# ⚙️ EDGE CASE 2
Scenario: Secure data persistence during a controlled application exit.
  Given the player has active session data or temporary progress flags in memory.
  And the exit confirmation pop-up is currently displayed.
  When the player presses the "Yes" button.
  Then the Flutter app must execute an immediate synchronous write to the local cache.
  And once the local save file is successfully verified, the application process must terminate cleanly.
```

---

### Epic 6: Offline Mode & Local Persistence *(Mobile Only)*

#### US-TF-6-1: Offline Gameplay with Local Cache

- **Priority:** High
- **Description:** As a mobile player, I want to be able to play without an internet connection so that my progress is saved locally and I can continue my adventure at any time.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: Player launches the app without internet connection.
  Given the mobile player has previously logged in with internet.
  And their progress has been saved locally in Hive.
  When they open the app without an internet connection.
  Then the app must load the last saved local state from Hive.
  And display a warning: "Offline Mode — Progress will sync when you reconnect."
  And allow the player to navigate the map and play normally.

# ❌ SAD PATH 1
Scenario: Player launches the app without internet and no local data.
  Given the mobile player has never logged in before.
  And there is no internet connection.
  When they open the app.
  Then the app must display: "No local progress found. Connect to the internet to download your save file."
  And the player must not be able to access the game.

# ❌ SAD PATH 2
Scenario: Local Hive database is corrupted.
  Given the mobile player opens the app without internet.
  And the local Hive database is corrupted or unreadable.
  When the app tries to load local data.
  Then the app must detect the corruption error.
  And display: "The evil Malakor has interrupted your process! Return to your mission."
  And attempt to restore data from MongoDB Atlas if connection becomes available.

# ❌ SAD PATH 3
Scenario: Device storage is full and cannot save local progress.
  Given the mobile player is playing in Offline Mode.
  And the device storage is completely full.
  When the app tries to save progress locally to Hive.
  Then the app must detect the storage error.
  And display: "Too much weight in your backpack! Free up some space."
  And the player must not lose their current session progress until the app is closed.

# ❌ SAD PATH 4
Scenario: App closes unexpectedly while saving local progress.
  Given the mobile player is playing in Offline Mode.
  And the app is in the middle of writing data to Hive.
  When the app crashes or is forcefully closed.
  Then upon reopening, the app must detect an incomplete save file.
  And roll back to the last valid checkpoint saved in Hive.
  And display: "Your last session was interrupted. Progress restored to last checkpoint."

# ⚙️ EDGE CASE 1
Scenario: Validating local timestamps to prevent device time cheating.
  Given the player is playing offline.
  And the player manually changes their device's system clock to a future date.
  When the player completes a level and the local cache saves the progress with the altered timestamp.
  And the internet connection is subsequently restored.
  Then the system must validate the local timestamp against the backend server time during synchronization.
  And if an unrealistic discrepancy is detected, the server time must overwrite the session data.

# ⚙️ EDGE CASE 2
Scenario: High-frequency network instability during synchronization.
  Given the player is transitioning from offline to online mode with pending data in the local cache.
  When the internet connection repeatedly drops and reconnects rapidly during the synchronization process.
  Then the application must implement a stabilization period of 3 seconds before executing the network request.
  And it must prevent partial or corrupted data packets from being sent to MongoDB.
```

---

#### US-TF-6-2: Automatic Cloud Sync on Reconnection

- **Priority:** High
- **Description:** As a mobile player, I want my offline progress to be automatically uploaded to MongoDB Atlas when I reconnect to the internet, so that my data is never lost.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH
Scenario: Player reconnects to the internet after playing offline.
  Given the mobile player has been playing in Offline Mode.
  And their progress is saved locally in Hive.
  When the app detects an internet connection.
  Then the app must automatically sync all local progress to MongoDB Atlas.
  And display: "Progress saved to the cloud ☁️"
  And the local Hive data must match the MongoDB document.

# ❌ SAD PATH 1
Scenario: Connection is lost in the middle of synchronization.
  Given the mobile player has reconnected to the internet.
  And the app has started syncing local progress to MongoDB Atlas.
  When the internet connection is lost mid-sync.
  Then the app must stop the sync operation immediately.
  And keep the local Hive data intact without partial writes to Atlas.
  And display: "Sync interrupted. We'll try again when you reconnect."
  And retry the sync automatically when connection is restored.

# ❌ SAD PATH 2
Scenario: MongoDB Atlas is unavailable during sync.
  Given the mobile player has reconnected to the internet.
  And MongoDB Atlas returns a server error (500).
  When the app tries to sync local progress.
  Then the app must keep the local Hive data intact.
  And display: "Could not sync progress. We'll try again later."
  And retry the sync automatically after 30 seconds.

# ❌ SAD PATH 3
Scenario: Local data is incomplete or missing required fields during sync.
  Given the mobile player tries to sync after reconnecting.
  And the local Hive data is missing required fields (e.g., playerId is null).
  When the app tries to build the sync request.
  Then the app must detect the missing fields.
  And abort the sync operation.
  And display: "Sync failed due to incomplete local data. Please log in again."
  And redirect the player to the login screen.

# ⚙️ EDGE CASE 1
Scenario: Automatic background synchronization when internet is restored.
  Given the player has pending progress saved in the local cache.
  And the application is running in the background.
  When the operating system detects that the internet connection has been restored.
  Then the application must trigger a silent background task to securely send the saved data to MongoDB.
  And after successful confirmation, the local cache must clear its pending synchronization flags.

# ⚙️ EDGE CASE 2
Scenario: Forced emergency backup when exiting with full storage.
  Given the application is holding the current session's progress in RAM due to a full storage error.
  When the player attempts to exit the game or the OS triggers a low memory warning.
  Then the application must attempt to compress the progress data to its smallest possible size.
  And make a final emergency attempt to write the compressed progress file to the local cache.
```

---

#### US-TF-6-3: Conflict Resolution (Local vs Cloud)

- **Priority:** Medium
- **Description:** As a mobile player, I want the app to handle conflicts between my local and cloud progress intelligently, so that I never lose my most recent achievements.
- **Acceptance Criteria (Gherkin):**

```gherkin
# ✅ HAPPY PATH 1
Scenario: Local progress is newer than cloud progress.
  Given the mobile player played offline and advanced to level 3.
  And MongoDB Atlas still shows level 2.
  When the app syncs after reconnecting.
  Then the app must detect that local progress is newer.
  And upload the local state to MongoDB Atlas using an upsert operation.
  And the cloud document must reflect level 3.

# ✅ HAPPY PATH 2
Scenario: Cloud progress is newer than local progress.
  Given the mobile player logged in on another device and advanced to level 4.
  And the local Hive cache still shows level 2.
  When the app syncs after reconnecting.
  Then the app must detect that cloud progress is newer.
  And overwrite the local Hive cache with the MongoDB Atlas data.
  And the player must continue from level 4.

# ❌ SAD PATH 1
Scenario: Neither local nor cloud data is valid.
  Given the mobile player tries to sync after reconnecting.
  And the local Hive data is corrupted.
  And MongoDB Atlas returns an empty or invalid document.
  When the app tries to resolve the conflict.
  Then the app must detect that neither source is valid.
  And display: "We could not recover your progress. Please contact support."
  And redirect the player to the login screen.
  And create an error log with the details of the conflict.

# ❌ SAD PATH 2
Scenario: Device clock is misconfigured causing incorrect conflict resolution.
  Given the mobile player's device clock is set to an incorrect date or time.
  And the app uses timestamps to determine which progress is newer.
  When the app tries to resolve the conflict.
  Then the app must detect the timestamp anomaly.
  And default to the MongoDB Atlas version as the source of truth.
  And display: "Your device clock appears to be incorrect. Cloud progress has been loaded."

# ⚙️ EDGE CASE 1
Scenario: Player has two active sessions on different devices simultaneously.
  Given the mobile player is logged in on their phone in Offline Mode.
  And the same player is also logged in on another device with internet.
  And both sessions generate different progress simultaneously.
  When both sessions try to sync to MongoDB Atlas.
  Then the backend must detect the simultaneous write conflict.
  And apply a last-write-wins strategy based on the server timestamp.
  And notify both sessions: "Your progress has been updated from another device."
  And reload the most recent state from MongoDB Atlas on both devices.
```

---

> 💡 **Technical Notes kept for implementation (Architecture Guidelines):**
>
> - **Backend Validation:** Ensure that items within the `inventory` array comply with business logic (e.g., a sword cannot have a `potion_effect` attribute).
> - **Inventory Capacity:** The `inventory` array must not exceed **30 items** per player. If the limit is reached, the backend must reject the `$push` operation and return an error to the client.
> - **Password Requirements:** Minimum 8 characters, must include uppercase letters, lowercase letters, numbers, and special characters.
> - **Username Requirements:** Between 3 and 15 characters, letters and numbers only, case-insensitive uniqueness check.
> - **Frontend Performance (Flutter):** Use `FutureBuilder` or state management like `Riverpod` to handle efficient inventory loading from the `/profile` endpoint.
