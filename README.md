# Anonymous Chat App

A real-time anonymous chat application built using FastAPI, Socket.IO, and Firebase, allowing users to chat instantly without revealing their identity. The system ensures fast messaging, scalability, and privacy-first communication.

## Features
🕵️ Anonymous user chat (no login required)
⚡ Real-time messaging using Socket.IO
🔥 Firebase integration for user/session management
📡 FastAPI backend for high-performance APIs
🔍 User search & auto-match system
💬 Instant message delivery (low latency)
📱 Clean and minimal UI (Flutter / Web supported)
🟢 Online/offline status tracking
🧹 Auto chat session cleanup when user leaves
🔐 Privacy-focused architecture (no personal data stored)
🏗️ Tech Stack

## Backend
FastAPI (Python)
Socket.IO (Real-time communication)
Uvicorn (ASGI server)
Database / Auth
Firebase Authentication (Anonymous / optional)
Firestore / Realtime Database
Frontend (Optional)
Flutter (Jetpack-style UI or Web UI)
OR React (if web version used)

## System Architecture
User Client (Flutter/Web)
        |
        | Socket.IO
        ↓
FastAPI Server (Python)
        |
        | Firebase Admin SDK
        ↓
Firebase (Auth + Database)
💬 How It Works
User opens the app
App assigns anonymous session ID
Socket.IO connects to FastAPI server
User is matched with another available user

## Screenshot
<img width="400" height="700" alt="chatapp1" src="https://github.com/user-attachments/assets/3f3a542d-6beb-4f10-a3f1-c8e6fc6da4a0" />
<img width="400" height="700" alt="chatapp2" src="https://github.com/user-attachments/assets/fd086985-6c9c-4197-a808-e97104407922" />
<img width="400" height="700" alt="chatapp3" src="https://github.com/user-attachments/assets/b3c28d85-7ced-4624-8405-bde9a112c458" />
<img width="400" height="700" alt="chatapp4" src="https://github.com/user-attachments/assets/a179124e-adee-42b9-8ad9-cf3bc381a3e6" />
<img width="400" height="700" alt="chatapp5" src="https://github.com/user-attachments/assets/c4618ef0-0681-4ae9-bbda-25b272ca494a" />
<img width="400" height="700" alt="chatapp6" src="https://github.com/user-attachments/assets/abdc502f-1fa9-4b68-a0e6-636a8e9e3032" />
<img width="400" height="700" alt="chatapp7" src="https://github.com/user-attachments/assets/4c8733d8-0865-4477-a08d-1d21966f1e8a" />

Real-time chat session starts
Messages are exchanged via WebSockets
When user disconnects → session is removed automatically
