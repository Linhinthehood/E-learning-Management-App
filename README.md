# E-Learning Management Application

A comprehensive cross-platform Flutter application for managing e-learning courses, inspired by Google Classroom. Built for the Faculty of Information Technology, this application supports both instructors and students with full CRUD operations, content distribution, tracking, and interaction features.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Quick Links](#quick-links)
3. [System Requirements](#system-requirements)
4. [Running Instructions](#running-instructions)
5. [Web Deployment](#web-deployment)
6. [Login Credentials](#login-credentials)
7. [Architecture](#architecture)
8. [Features](#features)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Testing](#testing)
11. [Troubleshooting](#troubleshooting)

---

## Project Overview

This application is built using **Flutter 3.35.7** with **Clean Architecture** principles, ensuring maintainability, testability, and scalability. It supports three platforms:
- **Android** (APK - arm64)
- **Windows** (EXE - x64)
- **Web** (HTML renderer)

The application uses **Firebase** for backend services (Firestore, Authentication, Storage) and **Hive** for offline data caching.

---

## Quick Links

- **GitHub Repository**: [https://github.com/Linhinthehood/E-learning-Management-App](https://github.com/Linhinthehood/E-learning-Management-App)
- **Android APK (Firebase App Distribution)**: [https://appdistribution.firebase.dev/i/e000c11646b8d18f](https://appdistribution.firebase.dev/i/e000c11646b8d18f)
- **Web Application (GitHub Pages)**: [https://linhinthehood.github.io/E-learning-Management-App/](https://linhinthehood.github.io/E-learning-Management-App/) 
- **Windows EXE & Other Artifacts**: Available in [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions) or [GitHub Releases](https://github.com/Linhinthehood/E-learning-Management-App/releases)

### Download Pre-built Applications

All pre-built applications are available through automated CI/CD:

1. **Android APK**: Use the Firebase App Distribution link above (recommended) or download from GitHub Actions artifacts
2. **Windows EXE**: Download from GitHub Actions artifacts or GitHub Releases
3. **Web Application**: Access directly via GitHub Pages link above

**Note**: To download artifacts from GitHub Actions:
- Go to [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions)
- Select a completed workflow run
- Scroll to the "Artifacts" section at the bottom
- Download the desired artifact (APK, Windows ZIP, or Web build)

---

## System Requirements

### Development Environment
- **Flutter SDK**: 3.35.7 or higher
- **Dart SDK**: 3.9.2 or higher
- **Android Studio** (for Android builds)
- **Visual Studio 2022** (for Windows builds)
- **Git**
- **Firebase CLI** (for Firebase configuration)

### Runtime Requirements
- **Android**: API level 21 (Android 5.0) or higher
- **Windows**: Windows 10/11 (64-bit)
- **Web**: Modern browsers (Chrome, Firefox, Edge, Safari)

---

## Running Instructions

### Running Locally (Development)

1. **Start the application**:
```bash
flutter run
```

2. **Run on specific platform**:
```bash
# Android
flutter run -d android

# Windows
flutter run -d windows

# Web (Chrome)
flutter run -d chrome 
```

3. **Run with hot reload**:
   - Press `r` in the terminal to hot reload
   - Press `R` to hot restart
   - Press `q` to quit application

### Running Pre-built Applications

#### Android APK
1. **Download from Firebase App Distribution** (recommended):
   - Click the link: [https://appdistribution.firebase.dev/i/e000c11646b8d18f](https://appdistribution.firebase.dev/i/e000c11646b8d18f)
   - Follow the instructions to install on your Android device
   - Enable "Install from Unknown Sources" if prompted

2. **Or download from GitHub Actions**:
   - Go to [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions)
   - Select a completed Android build workflow
   - Download the APK artifact
   - Transfer to Android device and install

#### Windows EXE
1. **Download from GitHub Actions**:
   - Go to [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions)
   - Select a completed Windows build workflow
   - Download the Windows ZIP artifact
   - Extract the ZIP file
   - Run `e_learning_management_app.exe` from the extracted folder

2. **Or download from GitHub Releases**:
   - Go to [GitHub Releases](https://github.com/Linhinthehood/E-learning-Management-App/releases)
   - Download the Windows ZIP from the latest release
   - Extract and run the executable

#### Web Application
- **Access directly**: [https://linhinthehood.github.io/E-learning-Management-App/](https://linhinthehood.github.io/E-learning-Management-App/)
- No installation required - works in any modern web browser

---

## Web Deployment

The application is automatically deployed to **GitHub Pages** when changes are pushed to the `main` branch via GitHub Actions.

**Public URL**: [https://linhinthehood.github.io/E-learning-Management-App/](https://linhinthehood.github.io/E-learning-Management-App/)

The web application is built using the HTML renderer for better compatibility and performance. It supports all modern browsers including Chrome, Firefox, Edge, and Safari.

---

## Login Credentials

### Instructor Account
- **Email**: `admin@example.com`
- **Password**: `admin123`

**Capabilities**:
- Full CRUD operations (Semesters, Courses, Students, Groups)
- Create and manage content (Announcements, Assignments, Quizzes, Materials)
- View tracking and analytics
- Export CSV reports
- Import CSV files (Students, Courses, Groups)
- Grade assignments
- Manage forum discussions
- Reply to student messages

### Student Account 1 (With Avatar & Completed Deadlines)
- **Email**: `duclinh@student.com`
- **Password**: `000000`

**Pre-loaded Data**:
- Has avatar profile picture
- Has completed all assignments and quizzes
- Can view grades and feedback

### Student Account 2 (Without Avatar & Pending Deadlines)
- **Email**: `hoanglong@student.com`
- **Password**: `000000`

**Pre-loaded Data**:
- No avatar profile picture
- Has pending assignments and quizzes
- Can demonstrate submission workflow

---

## Architecture

The application follows **Clean Architecture** principles with three main layers:

### Layer Structure

```
lib/
├── data/                    # Data Layer
│   ├── datasources/
│   │   ├── local/          # Hive/SQLite (Offline Cache)
│   │   ├── remote/         # Firebase/API calls
│   │   └── models/         # DTOs (Data Transfer Objects)
│   └── repositories/       # Repository implementations
│
├── domain/                  # Domain Layer (Business Logic)
│   ├── entities/           # Core business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business logic use cases
│
├── presentation/            # Presentation Layer (UI)
│   ├── common/
│   │   ├── widgets/        # Reusable widgets
│   │   └── styles/         # Colors, themes, text styles
│   └── features/           # Feature modules
│       ├── auth/           # Authentication screens
│       ├── dashboard/      # Dashboard screens
│       ├── course/          # Course management screens
│       └── ...
│
└── utils/                   # Utilities & Helpers
    ├── constants.dart
    └── services/           # Services (CSV import, file upload, etc.)
```

### Data Flow

```
UI (Presentation)
  ↓ calls
Use Case (Domain)
  ↓ calls
Repository Interface (Domain)
  ↓ implemented by
Repository Implementation (Data)
  ↓ calls
Data Source (Local/Remote)
  ↓ returns
Models (Data)
  ↓ converts to
Entities (Domain)
  ↓ returns to
UI (Presentation)
```

### Key Principles

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Dependency Inversion**: Domain layer doesn't depend on data/presentation layers
3. **Testability**: Business logic can be tested independently
4. **Maintainability**: Changes in one layer don't affect others

---

## Features

### Core Features (Mandatory)

#### 1. Authentication & Role-Based Access
- Login for Instructor and Student roles
- Session management
- Role-based routing

#### 2. Instructor Features
- **CRUD Operations**:
  - Semester Management (Create, Read, Update, Delete)
  - Course Management (with cover image upload)
  - Student Management (with account creation)
  - Group Management (within courses)

- **Content Creation**:
  - Announcements (with attachments, scope selection)
  - Assignments (with deadlines, file formats, size limits)
  - Quizzes (from question bank, with randomization)
  - Materials (files or links)

- **Tracking & Analytics**:
  - View tracking for announcements/materials
  - Assignment submission tracking
  - Quiz attempt tracking
  - CSV export functionality

- **CSV Import** (with Preview):
  - Import Students (with duplicate detection)
  - Import Courses (with validation)
  - Import Groups (with enrollment creation)
  - Preview screen showing row-by-row status

#### 3. Student Features
- **Dashboard**:
  - Course progress overview
  - Upcoming deadlines (excludes completed items)
  - Recent grades
  - Statistics

- **Course Space** (3 Tabs):
  - **Stream Tab**: Announcements with comments
  - **Classwork Tab**: Assignments, Quizzes, Materials (with search/filter/sort)
  - **People Tab**: Groups and students list

- **Submissions**:
  - Submit assignments (with file upload)
  - Take quizzes (with timer)
  - View grades and feedback

- **Interaction**:
  - Forum discussions (create topics, reply)
  - Private messaging (Student ↔ Instructor only)
  - In-app notifications (with deep linking)

#### 4. Performance & UX
- **Offline Capability**: Cache data locally using Hive
- **Semester Switcher**: Switch between semesters (past semesters read-only for students)
- **Search/Filter/Sort**: Available on all list views (14 screens)
- **Responsive Design**: Works on mobile, tablet, and desktop

### Technical Features

- **State Management**: Riverpod
- **Offline Storage**: Hive (local database)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **File Upload**: Cloudinary integration
- **CSV Processing**: CSV import/export with validation
- **Real-time Updates**: Firestore streams for live data

---

## CI/CD Pipeline

The project uses **GitHub Actions** for automated CI/CD with 5 workflows:

### 1. Continuous Integration (`ci.yml`)
**Triggers**: Push to `main`/`Hvan`, Pull Requests

**Actions**:
- Code formatting verification (`flutter format`)
- Static code analysis (`flutter analyze`)
- Run all 34 tests (`flutter test`)
- Check for outdated dependencies (`flutter pub outdated`)

### 2. Android Build (`build-android.yml`)
**Triggers**: Push to `main`, Version tags, PR, Manual

**Outputs**:
- Android APK (arm64) - `app-release.apk`
- Android App Bundle (AAB) - `app-release.aab`
- Auto-uploads to GitHub Releases on tags

### 3. Windows Build (`build-windows.yml`)
**Triggers**: Push to `main`, Version tags, PR, Manual

**Outputs**:
- Windows EXE with dependencies - `e_learning_management_app-windows.zip`
- Auto-uploads to GitHub Releases on tags

### 4. Web Deployment (`deploy-web.yml`)
**Triggers**: Push to `main`, Manual

**Actions**:
- Builds web app with HTML renderer
- Auto-deploys to GitHub Pages
- Configures Pages environment

### 5. Multi-Platform Release (`release.yml`)
**Triggers**: Version tags (`v*.*.*`), Manual

**Comprehensive Release Process**:
1. Runs all tests (34 tests)
2. Creates GitHub Release with auto-generated notes
3. Builds Android APK (arm64) → Uploads to Release
4. Builds Windows EXE → Uploads to Release
5. Builds Web application → Deploys to GitHub Pages
6. Uploads all artifacts to GitHub Release

### Usage

**To trigger a full release**:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**To manually trigger builds**:
- Go to [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions)
- Select the workflow (Android/Windows/Web)
- Click "Run workflow"

**To download build artifacts**:
- Go to [GitHub Actions](https://github.com/Linhinthehood/E-learning-Management-App/actions)
- Select a completed workflow run
- Scroll to the "Artifacts" section
- Download the desired artifact (APK, Windows ZIP, or Web build)

---

## Testing

### Test Suite

The project includes **34 automated tests** (all passing):

#### Unit Tests (19 tests)
- **Entity Tests** (16 tests):
  - `semester_entity_test.dart` - 6 tests
  - `course_entity_test.dart` - 5 tests
  - `user_entity_test.dart` - 5 tests

- **Validation Tests** (8 tests):
  - `validation_test.dart` - Email, Student ID, Course Code, Name, Date validation

#### Widget Tests (12 tests)
- `login_screen_test.dart` - 3 tests
- `common_widgets_test.dart` - 9 tests

#### Integration Tests (3 tests)
- `app_integration_test.dart` - Navigation flows, form submission, search/filter

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/entities/semester_entity_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage

Tests run automatically on every push and PR via GitHub Actions CI workflow.

---

## Troubleshooting

### Common Issues

#### 1. Firebase Initialization Failed
**Error**: `Firebase initialization FAILED`

**Solution**:
- Ensure `google-services.json` is in `android/app/`
- Ensure `firebase-config.js` is in `web/`
- Run `flutterfire configure` to regenerate configs
- Verify Firebase project is active

#### 2. Build Fails
**Solution**:
```bash
flutter clean
flutter pub get
flutter build <platform> --release
```

#### 3. Web Build Fails with CanvasKit Error
**Solution**: Use HTML renderer instead:
```bash
flutter build web --release --web-renderer html
```

#### 4. Offline Mode Not Working
**Solution**:
- Ensure Hive is initialized (`HiveInitializer.initialize()`)
- Check connectivity status indicator
- Verify local datasources are configured

#### 5. CSV Import Fails
**Solution**:
- Check CSV format matches template
- Verify required fields are present
- Check Firebase permissions for write operations

#### 6. APK Not Installing on Android
**Solution**:
- Enable "Install from Unknown Sources" in device settings
- Check device API level (minimum 21)
- Try: `adb install -r app-release.apk`

### Getting Help

1. Check Firebase Console for error logs
2. Review GitHub Actions logs for build errors
3. Verify all dependencies are installed: `flutter doctor -v`
4. Ensure Flutter version matches: `flutter --version` (should be 3.35.7)

---

## Additional Notes

### Project Status
- ✅ All mandatory features implemented
- ✅ All platforms built and tested
- ✅ CI/CD pipeline operational
- ✅ 34 tests passing
- ✅ Documentation complete

### Important Files
- `pubspec.yaml` - Dependencies and project configuration
- `firestore.rules` - Firestore security rules
- `.github/workflows/` - CI/CD workflow definitions
- `lib/main.dart` - Application entry point

### Development Notes
- The application uses **Clean Architecture** for maintainability
- **Riverpod** is used for state management
- **Hive** provides offline data caching
- **Firebase** handles backend services
- **Cloudinary** is used for file storage

