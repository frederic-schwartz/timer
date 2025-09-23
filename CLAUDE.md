# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Tockee" is a Flutter timer application with comprehensive session management and logging capabilities. The app allows users to:
- Start, pause, resume, and stop timer sessions
- Persist sessions across app restarts with proper pause time handling
- View session history and resume previous sessions
- Track all user actions with detailed logging system
- Configure display settings (number of recent sessions)

## Commands

### Code Quality
- `flutter analyze` - Run static analysis on Dart code
- `flutter test` - Run all tests (includes SessionLog model tests)
- `flutter test test/widget_test.dart` - Run specific test file

### Development & Build
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter clean` - Clean build artifacts

### Dependencies
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade all dependencies
- `flutter pub deps` - Show dependency tree

### Icon Generation
- `flutter pub run flutter_launcher_icons` - Generate app icons from assets/icon/app_icon.png

## Architecture

The app follows **Clean Architecture** with clear separation of concerns across Domain, Data, and Presentation layers.

### Clean Architecture Structure
- **Domain Layer** (`lib/src/domain/`) - Business logic, entities, repositories (interfaces), and use cases
- **Data Layer** (`lib/src/data/`) - Data sources, models, and repository implementations
- **Presentation Layer** (`lib/src/presentation/`) - Controllers, screens, and widgets

### Data Layer
The app uses **SQLite** (sqflite) for persistence with database versioning:
- `SessionLocalDataSource` - Database operations with version migration (v1→v2)
- `timer_sessions` table - Stores session data with pause time tracking
- `session_logs` table - Records all user actions with foreign key relationships
- `TimerLocalDataSource` and `SettingsLocalDataSource` - Specialized data access

### Domain Entities
- `TimerSession` - Core session model with duration calculation and state management
- `SessionLog` - Action logging model with enum-based actions (start, pause, resume, stop, resume_session)
- `TimerState` and `TimerSnapshot` - Timer state management entities

### Repository Pattern
Each domain has its own repository interface with concrete implementations:
- `SessionRepository` / `SessionRepositoryImpl` - Session data management
- `TimerRepository` / `TimerRepositoryImpl` - Timer operations and state
- `SettingsRepository` / `SettingsRepositoryImpl` - App configuration

### Use Cases (Interactors)
All business logic is encapsulated in use cases following Single Responsibility Principle:
- Timer operations: `StartTimer`, `PauseTimer`, `StopTimer`, `ResumeSession`
- Data queries: `GetAllSessions`, `GetSessionLogs`, `GetAllLogs`
- Settings: `GetRecentSessionsCount`, `SetRecentSessionsCount`
- Data management: `DeleteSession`, `ClearCompletedSessions`, `DeleteAllLogs`

### Dependency Injection
- `AppDependencies` - Singleton service locator managing all dependencies
- Manual dependency injection with clear separation of concerns
- Configured in `lib/src/dependency_injection/service_locator.dart`

### Presentation Layer Controllers
Controllers manage UI state and coordinate with use cases:
- `HomeController` - Main timer screen state and actions
- `SessionsController` - Session history management
- `SessionLogsController` - Individual session log details
- `AllLogsController` - Complete log history with filtering
- `SettingsController` - App configuration management

### State Management
The app uses **Stream-based reactive architecture** via repositories:
- Timer operations expose streams through `WatchTimerDuration` and `WatchTimerState` use cases
- Controllers listen to streams and notify UI via `ChangeNotifier` pattern
- State persistence through SQLite database + SharedPreferences for settings

### Screen Architecture
- `HomeScreen` - Main timer with fixed controls and scrollable recent sessions
- `SessionsScreen` - Full session history with resume/delete/logs actions
- `SessionLogsScreen` - Detailed log view for individual sessions
- `AllLogsScreen` - Complete log history with filtering and statistics
- `SettingsScreen` - Configuration (sessions count, data management)
- `AboutScreen` - App information

### Critical Implementation Details
- **Clean Architecture**: Strict separation between Domain, Data, and Presentation layers
- **Pause Time Handling**: Uses `totalPausedDuration` field to preserve session time when resumed
- **Database Versioning**: Supports schema migrations (v1→v2) for logs table addition
- **Use Case Pattern**: All business logic encapsulated in single-responsibility use cases
- **Controller Pattern**: `ChangeNotifier`-based controllers manage UI state
- **Stream Management**: Reactive updates via repository streams
- **Dependency Injection**: Manual DI with singleton service locator pattern

### Key Dependencies
- `sqflite: ^2.3.0` - SQLite database operations
- `shared_preferences: ^2.2.2` - Settings storage
- `path: ^1.8.3` - Database file path resolution
- `package_info_plus: ^8.0.0` - App version info
- `flutter_launcher_icons: ^0.14.3` - Icon generation (dev dependency)