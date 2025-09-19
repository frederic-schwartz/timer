# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter timer application with comprehensive session management and logging capabilities. The app allows users to:
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

### Dependencies
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade all dependencies
- `flutter pub deps` - Show dependency tree

### Icon Generation
- `flutter pub run flutter_launcher_icons` - Generate app icons from assets/icon/app_icon.png

## Architecture

### Data Layer
The app uses **SQLite** (sqflite) for persistence with database versioning:
- `DatabaseService` - Singleton managing database operations with version migration (v1→v2)
- `timer_sessions` table - Stores session data with pause time tracking
- `session_logs` table - Records all user actions with foreign key relationships

### Models
- `TimerSession` - Core session model with duration calculation and state management
- `SessionLog` - Action logging model with enum-based actions (start, pause, resume, stop, resume_session)

### Services Architecture
- `TimerService` - Core timer logic with Stream-based reactive updates
  - Handles complex pause time calculations across app restarts
  - Manages session states: stopped, running, paused, ready
  - Integrates automatic logging for all user actions
- `SettingsService` - SharedPreferences wrapper for app configuration
- `DatabaseService` - Database abstraction with transaction support

### State Management
The app uses **Stream-based reactive architecture**:
- `TimerService` exposes `durationStream` and `stateStream`
- UI components subscribe to streams for real-time updates
- State persistence through database + SharedPreferences for temporary data

### Screen Architecture
- `HomeScreen` - Main timer with fixed controls and scrollable recent sessions
- `SessionsScreen` - Full session history with resume/delete/logs actions
- `SessionLogsScreen` - Detailed log view for individual sessions
- `AllLogsScreen` - Complete log history with filtering and statistics
- `SettingsScreen` - Configuration (sessions count, data management)

### Critical Implementation Details
- **Pause Time Handling**: Uses frozen duration concept to preserve session time when resumed
- **Database Versioning**: Supports schema migrations for logs table addition
- **Stream Management**: Proper subscription lifecycle management in StatefulWidgets
- **Navigation**: Comprehensive navigation between session views and log details

### Key Dependencies
- `sqflite` - SQLite database operations
- `shared_preferences` - Temporary state storage
- `path` - Database file path resolution