# ToDo Team
A Flutter-based collaborative "Offline-First" task management app for teams, supporting offline mode, local and push notifications, and secure authentication. Mainly developed for Android and iOS platforms.


## Table of Contents
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)

## Features
- **Secure Authentication** — JWT-based login & signup
- **Local Storage** — Sqflite for tasks/users, Flutter Secure Storage for credentials
- **Role-based Actions** — Only owners can edit tasks
- **Priority & Time Tracking** — Color-coded priority and dynamic "time left" indicator
- **Local Notifications** — Alerts for tasks due in <24h
- **Offline Support** — Local caching of tasks with sync when online
- **Push Notifications** — Firebase Cloud Messaging for task updates *still needs some work on the backend side*

## Tech Stack
- **Frontend/UI**: Flutter
- **State Management**: Provider
- **Local Database**: sqflite
- **Secure Storage**: flutter_secure_storage
- **Networking**: http
- **Push Notifications**: Firebase Cloud Messaging
- **Local Notifications**: flutter_local_notifications

## Architecture
- **UI Layer**: Flutter widgets
- **State Management**: Provider for caching/filtering tasks
- **Data Layer**:
    - Sqflite for local storage (tasks, users)
    - Flutter Secure Storage for sensitive data (JWT, expiry date)
    - Pending changes table for offline sync
- **Networking Layer**: REST API with JWT auth, JSON over HTTP

## Installation
1. Clone the repository:
   ```bash
   git clone https://gitea.chedy-projects.tech/chedy/ToDo_Team.git
   cd ToDo_Team
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Sign Up** — Create an account and log in.
2. **Create Tasks** — Assign them to yourself or teammates or to none.
3. **View Tasks** — Filter by ownership, assignment, or unassigned tasks.
4. **Edit/Delete Tasks** — Owners only.
5. **Offline Mode** — Make changes offline; they sync when you reconnect.
6. **Notifications** — Receive alerts for tasks due soon.
7. **Push Notifications** — Get updates on task changes from teammates.

## Roadmap
1. **Functionality**
- Add ADMIN support: KPI statistics, user management, task analytics, and advanced reporting (can be desktop app or web app)
2. **Performance level** 
- Add Pagination : splitting tasks loaded in chunks
- Add Lazy Loading : limit number of displayed tasks
3. **Esthetics**
- Add Shimmer Effect: Visually appealing shimmer effect during task loading
- Add dark theme
4. **Nice To Have**
- Integration with the calendar
