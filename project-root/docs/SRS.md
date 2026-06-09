# 📑 Software Requirements Specification (SRS) — Nexus RPG

---

## 1. Introduction

This document defines the requirements for the development of a mobile RPG video game focused on dynamic inventory management using NoSQL technologies.

---

## 2. Functional Requirements (FR)

### 2.1 User and Session Management

- **FR-01 — Account Registration:** The system must allow the user to create an account using a unique username, email, and password.
- **FR-02 — Profile Persistence:** The system must store the player's progress (current level) and their credentials in MongoDB.
- **FR-03 — Multi-device Login:** The user must be able to access their profile from any device using their email and password.

### 2.2 Level Mechanics

- **FR-04 — Sequential Progress:** The system will unlock level $n+1$ only when level $n$ has been marked as completed in the database.
- **FR-05 — Level Map:** The interface must graphically display the status of all 10 levels (Locked/Unlocked).

### 2.3 Inventory System (Core NoSQL)

- **FR-06 — Heterogeneous Item Structure:** The system must allow storing objects with different attributes (e.g., Swords with damage and Potions with effect) within the same array.
- **FR-07 — Item Management:** The user must be able to:
  - **Collect:** Add an item to the player document's `inventory` array.
  - **Use/Delete:** Remove an item from the array using its unique identifier.
- **FR-08 — Real-time Synchronization:** The inventory displayed in Flutter must reflect the current state of the MongoDB document after each action.

---

## 3. Non-Functional Requirements (NFR)

### 3.1 Performance and Scalability

- **NFR-01 — Network Latency:** Requests to the backend (Node.js) must not exceed 500ms under normal network conditions.
- **NFR-02 — Data Availability:** MongoDB Atlas will be used to guarantee 99.9% availability of player data.

### 3.2 Usability and Aesthetics

- **NFR-03 — Responsive Design:** The Flutter interface must adapt to different screen resolutions (smartphones and tablets).
- **NFR-04 — Visual Feedback:** Every inventory action (collect/delete) must display a visual confirmation (SnackBar or animation) to the user.

### 3.3 Security

- **NFR-05 — Credential Protection:** Passwords must be stored using a hashing algorithm (e.g., bcrypt) on the server.
- **NFR-06 — Schema Integrity:** Although NoSQL is flexible, the backend must validate that items added to the array meet the minimum required data types.

---

## 4. System Architecture (Technical Summary)

| Component     | Technology          | Role                                                              |
|---------------|---------------------|-------------------------------------------------------------------|
| Frontend      | Flutter             | Mobile application, UI rendering and state management.            |
| Backend       | Node.js + Express   | REST API, business logic and schema validation.                   |
| Database      | MongoDB             | JSON document storage (Embedded Models).                          |
| Communication | HTTP/JSON           | Data exchange protocol between Flutter and the API.               |

---

## 5. Data Model (Conceptual Schema)

To comply with **FR-06**, the player document in MongoDB will follow this logical structure:

'$$\text{Player} = \{ \text{id, username, email, password, current\_level, } \mathbf{inventory: [ ]} \}$$'

> **Architect's Note:** By using the embedded model for the inventory, we ensure that **FR-08** is fulfilled with a single database query, optimizing performance on mobile devices.
