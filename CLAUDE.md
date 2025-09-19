# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter timer application project with minimal setup. The app is in its initial state with:
- A basic Material Design app structure
- `HomeScreen` currently showing a placeholder widget
- Standard Flutter project structure with `lib/` and `test/` directories

## Commands

### Code Quality
- `flutter analyze` - Run static analysis on Dart code
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file

### Dependencies
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade all dependencies
- `flutter pub deps` - Show dependency tree

### Icon Generation
- `flutter pub run flutter_launcher_icons` - Generate app icons from assets/icon/app_icon.png

## Architecture

### Core Structure
- `lib/main.dart` - App entry point with `MyApp` root widget
- `lib/home_screen.dart` - Main screen (currently placeholder)
- Material Design with Deep Purple color scheme

### Current State
The project is in its initial phase:
- `HomeScreen` needs to be implemented with timer functionality
- No state management solution implemented yet
- Basic Flutter test structure in place but needs updating for actual functionality

### Assets
- App icons stored in `assets/icon/`
- Additional images can be placed in `assets/images/`