# E-Learning Management App - Comprehensive Development Plan

**Project**: Cross-platform Flutter E-Learning Management App (Google Classroom inspired)
**Target**: Faculty of Information Technology
**Architecture**: Clean Architecture with Domain-Data-Presentation layers

---

## Current Status ✅
- ✅ Flutter project initialized
- ✅ Clean Architecture folder structure created
- ✅ Login screen UI created (black & white theme)
- ✅ Student dashboard UI created (placeholder data)
- ✅ Basic widgets created (sidebar, course cards, etc.)
- ✅ Git repository set up
- 🔄 **Start committing regularly: ≥2 commits/week/member**

---

## Phase 1: 🚀 Foundation, Authentication & Core CRUD

**Goal**: Build the app skeleton, set up database, and complete basic admin management features.

### 1.1 Project Setup & Git (⚠️ CRITICAL for Teamwork Points)
- ✅ Initialize Flutter project
- ✅ Set up Git repository (GitHub/GitLab)
- **🚨 IMPORTANT**: Maintain ≥2 commits/week/member for ≥1 month
  - Start NOW and commit consistently
  - Deduction of 0.5pt if solo/no evidence
- ✅ Create folder structure following Clean Architecture:
  ```
  lib/
  ├── data/datasources/local/remote/models/repositories/
  ├── domain/entities/repositories/usecases/
  ├── presentation/common/features/
  └── utils/
  ```

### 1.2 Backend & Database Setup (⚠️ MANDATORY)
- Choose and set up **Online Database**:
  - Option A: Firebase (easier, free tier)
  - Option B: Self-built backend (bonus points)
- Integrate **Offline Database** (⚠️ MANDATORY):
  - Implement Hive or SQLite
  - Required for offline capability
  - Design 19 collections (see Database Schema section)
- Set up data synchronization between online/offline

### 1.3 Authentication & Role-Based Access (⚠️ MANDATORY)
- ✅ Login screen created
- Implement login logic for 2 roles:
  - **Instructor**: Fixed credentials `admin/admin`
  - **Students**: Accounts created by instructor
- Set up **Role-Based Routing**:
  - Admin → Instructor Dashboard
  - Student → Student Homepage
- Implement session management
- Add logout functionality

### 1.4 Domain & Data Layers (Core Entities)
- **In `domain/entities/`**, define:
  - `UserEntity` (uid, email, displayName, avatarUrl, role)
  - `SemesterEntity` (id, name, code, startDate, endDate)
  - `CourseEntity` (id, name, code, semesterId, instructorId, coverImageUrl, sessions)
  - `GroupEntity` (id, name, courseId, semesterId)
  - `StudentEntity` / enrollment structure

- **In `domain/repositories/`**, define interfaces:
  - `IUserRepository`
  - `ISemesterRepository`
  - `ICourseRepository`
  - `IGroupRepository`

- **In `data/repositories/`**, implement interfaces:
  - Handle logic: when to call API (remote), when to fetch from cache (local)

### 1.5 Build Instructor CRUD UI (⚠️ MANDATORY - 2.0 pts Data Management)
Complete screens in `presentation/features/` for Instructor to perform CRUD on:
- ✅ **Semester Management**
  - Create/Read/Update/Delete semesters
  - Set start/end dates to determine "current semester"

- ✅ **Course Management**
  - Create/Read/Update/Delete courses
  - Link to semester and instructor
  - Upload cover image
  - Set number of sessions (10 or 15)

- ✅ **Student Management**
  - Create student accounts independently
  - Real names required
  - Generate unique credentials

- ✅ **Group Management**
  - Create groups within courses
  - Assign existing students to groups
  - **Rule**: Student can belong to only ONE group per course

---

## Phase 2: 📦 Content Distribution & Basic Interaction

**Goal**: Build core e-learning features - create and consume content.

### 2.1 Expand Domain & Data Layers (Content Entities)
Define entities for 4 content types:
- `AnnouncementEntity` (title, content, attachments, courseId, authorId, scopedGroupIds, createdAt)
- `AssignmentEntity` (title, description, courseId, scopedGroupIds, startDate, deadline, lateDeadline, maxAttempts, fileFormats, sizeLimits)
- `QuizEntity` (title, courseId, timeOpen, timeClose, durationMinutes, numAttempts, structure, scopedGroupIds)
- `MaterialEntity` (title, description, filesOrLinks, courseId, createdAt)
- `QuestionBankEntity` (courseId, name)
- `QuestionEntity` (questionText, options, correctAnswerIndex, difficulty)

### 2.2 Instructor: Content Creation UI (⚠️ MANDATORY - 2.0 pts Content Distribution)
Build forms/screens for Instructor to create:

#### 2.2.1 Announcements
- Rich-text editor for content
- File attachments
- **Scope selector**: Choose one/multiple/all groups
- Display in Stream tab
- Track views

#### 2.2.2 Assignments
- Title, description, attachments
- **Scope selector**: Choose groups
- Set dates: startDate, deadline, lateDeadline (optional)
- Configure: maxAttempts, accepted file formats, size limits
- Display in Classwork tab

#### 2.2.3 Materials
- Upload files or add links
- **Auto-visible** to all students in course (no scope)
- Track downloads
- Display in Classwork tab

#### 2.2.4 Question Bank & Quizzes
- **Question Bank**:
  - Create per course
  - Add questions with: text, options, correct answer, difficulty (easy/medium/hard)
  - Reusable across quizzes

- **Quiz Creation**:
  - Select questions from Question Bank
  - Filter by difficulty
  - Configure structure (e.g., 10 easy, 5 medium, 2 hard)
  - Set time window (timeOpen, timeClose)
  - Set duration and attempt limits
  - Randomization support
  - **Scope selector**: Choose groups

### 2.3 Student: Course Space with 3 Tabs (⚠️ MANDATORY)
Build Course Space screen with tabs:

#### 2.3.1 Stream Tab
- Display announcements chronologically
- Allow short comments
- View tracking

#### 2.3.2 Classwork Tab
- List assignments, quizzes, materials
- **⚠️ MANDATORY**: Implement Search and Sort
- Filter by type, status, date
- Show deadlines prominently

#### 2.3.3 People Tab
- Display list of groups
- Show students in each group
- Show instructor info

### 2.4 Student: Submit & Take Actions
#### Assignment Submission
- Upload files/images
- Track attempt number
- Show submission status (submitted/late/graded)
- View grade and feedback

#### Quiz Taking
- Multiple choice interface
- Timer countdown
- Auto-submit on timeout
- Show score after completion
- Track attempts

---

## Phase 3: 📊 Interaction, Tracking & Feature Completion

**Goal**: Complete all mandatory interaction features, tracking, and analytics.

### 3.1 Interaction Features (⚠️ MANDATORY - 2.0 pts)

#### 3.1.1 Forum System (Course-Level)
- Create discussion topics (title, content, attachments)
- Reply to topics (threaded replies supported)
- Search and filter posts
- Attach files
- **🚨 CRITICAL RULE**: NO student-to-student direct messaging

#### 3.1.2 Private Messaging (⚠️ MANDATORY)
- **ONLY Student ↔ Instructor** chat allowed
- Build chat UI with inbox/sent folders
- Real-time message indicators (read/unread)
- Message timestamps
- Document ID format: `studentId_instructorId`

### 3.2 Notifications (⚠️ MANDATORY - 2.0 pts)

#### 3.2.1 In-App Notifications (Students only)
- Display notification list
- Mark as read/unread
- Deep link to related content (assignment, announcement, etc.)
- Badge counter

#### 3.2.2 Email Notifications
- Integrate email service (Firebase Functions + SendGrid, or similar)
- Auto-send emails for:
  - New announcement posted
  - Assignment graded
  - Deadline reminders
  - Submission confirmation
  - Quiz available

### 3.3 Tracking & Analytics (⚠️ MANDATORY - 2.0 pts)

#### 3.3.1 Instructor Tracking Screens
Build detailed tracking for:
- **Announcements/Materials**: Who viewed, who downloaded, timestamps
- **Assignments**:
  - Submission status (submitted/not submitted/late)
  - Attempt count
  - Grades
  - Download submitted files
- **Quizzes**:
  - Who completed
  - Scores
  - Time taken
  - Detailed answers

**⚠️ Technical Note**: Use separate `viewTracking` collection to avoid hotspotting (too many writes to one document)

#### 3.3.2 CSV Export (⚠️ MANDATORY)
- Export assignment submissions (individual or bulk)
- Export quiz results (individual or bulk)
- Formatted CSV with proper headers
- One-click download

### 3.4 Complete Dashboards (⚠️ MANDATORY - 2.0 pts Student Features)

#### 3.4.1 Instructor Dashboard
- ✅ Basic layout exists
- Add statistics: number of courses, students, assignments
- Progress charts: submission rates, average scores
- Recent activity feed

#### 3.4.2 Student Personal Dashboard
- ✅ Basic layout exists
- Show progress per course
- Upcoming deadlines (sorted by date)
- Recent grades
- Completed assignments/quizzes
- Timeline view

---

## Phase 4: ✨ Optimization, CSV Import & Deployment

**Goal**: Complete non-functional requirements and prepare for submission.

### 4.1 CSV Import with Preview (⚠️ CRITICAL - Heavily Emphasized)

This is a **complex, mandatory feature** with specific requirements:

#### 4.1.1 Implementation Requirements
- Build bulk import for: Students, Courses, Groups
- **⚠️ MANDATORY**: Preview screen after file upload
- Show status for each row:
  - "Already exists" (will skip)
  - "Will be added" (new)
  - "Invalid data" (error with reason)
- User confirms before actual import
- **Intelligent duplicate handling**:
  - Detect duplicates by email/student ID
  - Skip duplicates, only import new records
- Show success/error summary after import

#### 4.1.2 UI Flow
1. Upload CSV file
2. Parse and validate
3. Show preview table with row-by-row status
4. User clicks "Confirm Import"
5. Process only valid, non-duplicate rows
6. Show results (X added, Y skipped, Z errors)

### 4.2 Performance Optimization & UX

#### 4.2.1 Offline Capability (⚠️ MANDATORY)
- Test thoroughly: users should see previously accessed data when offline
- Sync mechanism when back online
- Clear cache indicators
- Offline banner/indicator

#### 4.2.2 Semester Switcher (⚠️ MANDATORY)
- Dropdown to switch between semesters
- Current semester as default
- **Past semesters = read-only for students**:
  - Cannot submit assignments
  - Cannot take quizzes
  - Can view materials and grades

#### 4.2.3 Search/Filter/Sort (⚠️ MANDATORY)
- Ensure ALL list views support:
  - Search (text-based)
  - Filter (by date, status, type, etc.)
  - Sort (by name, date, score, etc.)
- Optimize queries (indexes in database)
- Implement debouncing for search

#### 4.2.4 Responsive Design (⚠️ MANDATORY)
- Test on mobile, tablet, desktop sizes
- Ensure UI adapts properly
- No overflow errors
- Touch-friendly on mobile, mouse-friendly on desktop

### 4.3 Deployment (⚠️ MANDATORY - 1.0 pt)

#### 4.3.1 Build Files (⚠️ MANDATORY or 0 points)
- **Android APK** (arm64): `bin/app-release.apk`
- **Windows EXE** (64-bit): `bin/app-release.exe`
- **macOS** (optional but recommended): `bin/app-release.app`

#### 4.3.2 Web Deployment (0.5 pts)
- Build Flutter web version
- Deploy to public hosting:
  - Firebase Hosting (recommended)
  - GitHub Pages
  - Netlify
  - Vercel
- Provide public URL
- **Handle cold starts**: If using free backend, prepare wake-up script

#### 4.3.3 Deployment Testing
- Test web version on multiple browsers
- Test APK on Android device
- Test Windows/macOS executables
- Ensure all features work on all platforms

### 4.4 Submission Preparation

#### 4.4.1 Video Demo (⚠️ MANDATORY or features not shown = not graded)
- Record ≥1080p video (`demo.mp4`)
- **Must show ALL team members**
- Demonstrate ALL features:
  - Login as instructor (admin/admin)
  - All instructor features (CRUD, tracking, export, etc.)
  - Login as student
  - All student features (submit, quiz, forum, messaging, etc.)
  - Responsive design (resize browser)
  - Offline capability
  - Bonus features (if implemented)
- Keep it clear and concise

#### 4.4.2 GitHub Evidence
- Take screenshots from GitHub Insights:
  - Contributor graphs
  - Commit history (show ≥2 commits/week/member)
  - Code frequency
- Save in `git/` folder

#### 4.4.3 Documentation Files
- **Readme.txt** (⚠️ -2.0 pts if missing build instructions):
  - How to build from source
  - How to run locally
  - Web deployment URL
  - Test account credentials:
    - Instructor: admin/admin
    - Students: list with emails/passwords
- **Rubrik.docx**: Self-assessment checklist

#### 4.4.4 Folder Structure for Submission
```
id1_fullname1_id2_fullname2.zip
├── source/          # Complete source code (cleaned)
├── bin/             # APK + Windows EXE + macOS (optional)
├── demo.mp4         # Demo video
├── git/             # GitHub Insights screenshots
├── Readme.txt       # Build instructions, URLs, credentials
├── Bonus/           # Evidence of bonus features (if any)
└── Rubrik.docx      # Self-assessment
```

---

## Database Schema - 19 Collections

### Core Collections (Roles & Academic Structure)

#### 1. users
- **Purpose**: Store both Instructor and Student accounts
- **Document ID**: `uid` (from authentication)
- **Fields**:
  - `email`: string
  - `displayName`: string (real name required)
  - `avatarUrl`: string (optional)
  - `role`: string ('instructor' or 'student')

#### 2. semesters
- **Purpose**: Manage academic semesters
- **Fields**:
  - `name`: string (e.g., "Semester 1 2025-2026")
  - `code`: string
  - `startDate`: timestamp
  - `endDate`: timestamp (determines current semester)

#### 3. courses
- **Purpose**: Store course information
- **Fields**:
  - `name`: string (IT-related only)
  - `code`: string
  - `semesterId`: reference to semesters
  - `instructorId`: reference to users (role = instructor)
  - `coverImageUrl`: string
  - `sessions`: number (10 or 15)

#### 4. groups
- **Purpose**: Manage groups (classes) within a course
- **Fields**:
  - `name`: string (e.g., "Group 1")
  - `courseId`: reference to courses
  - `semesterId`: reference to semesters (for query optimization)

#### 5. enrollments
- **Purpose**: Linking collection for student-group-course relationships
- **⚠️ Critical**: Enforces "student can only be in ONE group per course"
- **Fields**:
  - `studentId`: reference to users
  - `courseId`: reference to courses
  - `groupId`: reference to groups
  - `semesterId`: reference to semesters (for query optimization)

### Content Collections

#### 6. announcements
- **Purpose**: Store announcements
- **Fields**:
  - `title`: string
  - `content`: string (rich-text)
  - `attachments`: array of URLs
  - `courseId`: reference to courses
  - `authorId`: reference to users (instructor)
  - `scopedGroupIds`: array of group IDs (which groups see this)
  - `createdAt`: timestamp

#### 7. materials
- **Purpose**: Store learning materials
- **Fields**:
  - `title`: string
  - `description`: string
  - `filesOrLinks`: array of URLs/links
  - `courseId`: reference to courses (auto-visible to ALL students)
  - `createdAt`: timestamp

#### 8. assignments
- **Purpose**: Store assignment details
- **Fields**:
  - `title`: string
  - `description`: string
  - `attachments`: array of URLs
  - `courseId`: reference to courses
  - `scopedGroupIds`: array of group IDs
  - `startDate`: timestamp
  - `deadline`: timestamp
  - `lateDeadline`: timestamp (optional, if late submissions allowed)
  - `maxAttempts`: number
  - `fileFormats`: array of strings
  - `sizeLimits`: number

#### 9. questionBanks
- **Purpose**: Store question banks per course
- **Fields**:
  - `courseId`: reference to courses
  - `name`: string (e.g., "OOP Questions")

#### 10. questions (Sub-collection of questionBanks)
- **Purpose**: Store individual questions
- **Document ID**: `questionId`
- **Fields**:
  - `questionText`: string
  - `options`: array of strings (e.g., ['A', 'B', 'C', 'D'])
  - `correctAnswerIndex`: number (e.g., 0 for 'A')
  - `difficulty`: string ('easy', 'medium', 'hard')

#### 11. quizzes
- **Purpose**: Store quiz configurations
- **Fields**:
  - `title`: string
  - `courseId`: reference to courses
  - `timeOpen`: timestamp
  - `timeClose`: timestamp
  - `durationMinutes`: number
  - `numAttempts`: number
  - `structure`: object (e.g., `{ 'easy': 10, 'medium': 5, 'hard': 2 }`)
  - `scopedGroupIds`: array of group IDs

### Interaction & Tracking Collections

#### 12. assignmentSubmissions
- **Purpose**: Track student assignment submissions
- **Fields**:
  - `assignmentId`: reference to assignments
  - `studentId`: reference to users
  - `courseId`: reference to courses
  - `submissionTime`: timestamp
  - `files`: array of URLs
  - `attemptNumber`: number
  - `grade`: number (set by instructor)
  - `status`: string ('submitted', 'late', 'graded')

#### 13. quizAttempts
- **Purpose**: Track student quiz attempts
- **Fields**:
  - `quizId`: reference to quizzes
  - `studentId`: reference to users
  - `courseId`: reference to courses
  - `startTime`: timestamp
  - `endTime`: timestamp
  - `score`: number (auto-graded)
  - `answers`: array of objects (e.g., `[{ questionId: '...', selectedOption: 1 }, ...]`)

#### 14. viewTracking
- **Purpose**: Track views/downloads of announcements and materials
- **⚠️ Technical Note**: Separate collection to avoid hotspotting (too many writes to one document)
- **Fields**:
  - `contentId`: string (ID of announcement or material)
  - `contentType`: string ('announcement' or 'material')
  - `studentId`: reference to users
  - `action`: string ('view' or 'download')
  - `timestamp`: timestamp

#### 15. forumTopics
- **Purpose**: Store forum discussion topics
- **Fields**:
  - `courseId`: reference to courses
  - `title`: string
  - `content`: string
  - `authorId`: reference to users
  - `createdAt`: timestamp
  - `attachments`: array of URLs

#### 16. forumReplies
- **Purpose**: Store replies to forum topics
- **Fields**:
  - `topicId`: reference to forumTopics
  - `content`: string
  - `authorId`: reference to users
  - `createdAt`: timestamp
  - `replyToId`: reference to forumReplies (optional, for threaded replies)

#### 17. chats
- **Purpose**: Manage private conversations (Student ↔ Instructor ONLY)
- **Document ID**: `studentId_instructorId` (composite key)
- **Fields**:
  - `participantIds`: array of 2 IDs (student and instructor)
  - `lastMessage`: string (for preview)
  - `lastMessageTimestamp`: timestamp

#### 18. messages (Sub-collection of chats)
- **Purpose**: Store individual chat messages
- **Fields**:
  - `senderId`: reference to users
  - `content`: string
  - `timestamp`: timestamp

#### 19. notifications
- **Purpose**: Store in-app notifications (Students only)
- **Fields**:
  - `studentId`: reference to users (recipient)
  - `title`: string
  - `message`: string
  - `isRead`: boolean
  - `createdAt`: timestamp
  - `linkTo`: string (deep-link to related content)

---

## Bonus Features (Max 4 features, 0.25-0.5 pts each)

Choose up to 4 bonus features to implement for extra points (max +2 pts total).

### 1. Real-time WebSocket Features (0.5 pts) ⭐ HIGHLY RECOMMENDED
**Why**: Easy to demonstrate, adds "wow factor", enhances core features

**Implement**:
- WebSocket connection (Socket.io or similar)
- Real-time notifications (appear instantly without refresh)
- Live messaging (instant chat updates)
- Real-time forum updates (new replies appear without refresh)
- Online/offline status indicators
- Live quiz participation counter

**Evidence**:
- Screen recording showing multiple users interacting simultaneously
- Network tab showing WebSocket connections
- Before/after comparison (polling vs real-time)

### 2. Docker + Kubernetes (0.5 pts) ⭐ HIGHLY RECOMMENDED
**Why**: Shows professional deployment, solves cold start problem

**Implement**:
- Dockerize Flutter web app, backend, database
- Create `docker-compose.yml` for local development
- Create Kubernetes manifests:
  - Deployments, Services, ConfigMaps, Secrets
  - Auto-scaling (HPA)
  - Health checks and probes
  - Rolling updates
  - Resource limits

**Evidence**:
- Dockerfile, docker-compose.yml, K8s manifests in repo
- Screenshots of Kubernetes dashboard
- `kubectl` commands showing running pods
- Demo of auto-scaling or zero-downtime deployment

### 3. AI Chatbot with RAG (0.5 pts) ⭐ PRIMARY FOCUS
**Why**: Most visible to users, clear value proposition, easiest to demonstrate

**Implement**:
- Integrate AI API (OpenAI, Claude, Gemini, etc.)
- RAG (Retrieval-Augmented Generation) on course materials
- Chat interface in app
- Course-specific query support
- Context from announcements, materials, FAQs

**Evidence**:
- Demo video showing chatbot answering course-related questions
- Screenshots of chat interface
- Documentation of RAG implementation
- Sample conversations

### 4. AI Question Generator (0.5 pts) ⭐ SECONDARY
**Why**: Directly helps instructors, measurable output quality

**Implement**:
- Integrate AI API for question generation
- Allow instructor to generate quiz questions from topics
- Support multiple question types (multiple choice, true/false)
- Allow editing generated questions before saving
- Quality control (difficulty level assignment)

**Evidence**:
- Demo video showing question generation
- Examples of generated questions
- Before/after editing interface

### 5. Advanced Testing Suite (0.5 pts) ⭐ RECOMMENDED
**Why**: Concrete metrics, proves code quality

**Implement**:
- Unit tests: >70% coverage for business logic (domain/usecases)
- Widget tests: Flutter UI components
- Integration tests: API endpoints, database operations
- E2E tests: Critical flows (login, submit assignment, take quiz, post announcement)
- HTML coverage reports

**Evidence**:
- Coverage badge in README (e.g., "coverage: 82%")
- Screenshots of test execution and coverage reports
- GitHub Actions showing automated test runs

### 6. CI/CD Pipeline (0.25 pts)
**Implement**:
- GitHub Actions or GitLab CI
- Automated testing on every commit
- Automated builds for Android/Web
- Automated deployment to staging/production
- Build status badges

**Evidence**:
- `.github/workflows/` files in repo
- Build status badges in README
- Screenshots of successful CI/CD runs

### 7. Self-Built Backend (0.5 pts)
**Why**: Instead of Firebase, build custom REST API

**Implement**:
- Node.js/Express, Python/FastAPI, or similar
- RESTful API endpoints
- Database integration (PostgreSQL, MongoDB, etc.)
- Authentication/authorization
- Proper error handling

**Evidence**:
- Backend code in `source/backend/` folder
- API documentation (Swagger/OpenAPI)
- Postman collection
- Demo of API calls

### 8. Microservices Architecture (0.5 pts)
**Implement**:
- Split backend into microservices:
  - Auth service
  - Content service
  - Notification service
  - Analytics service
- Inter-service communication (REST/gRPC)
- API Gateway

**Evidence**:
- Architecture diagram
- Docker-compose with multiple services
- Service-to-service communication demo

---

## Critical Checkpoints - Avoid 0 Points! ⚠️

### Must Have (or receive 0 points):

1. ✅ **IT-Related Content ONLY**
   - All courses, materials, assignments must be IT topics
   - Examples: Programming, Databases, AI, Machine Learning, Web Dev, Mobile Dev, Data Structures, Algorithms, Cybersecurity
   - ❌ Non-IT content = 0 points

2. ✅ **Source Code Submitted**
   - Must include complete, runnable source code
   - ❌ No source code = 0 points

3. ✅ **Rubric.docx Submitted**
   - Self-assessment checklist filled out
   - ❌ No rubric = 0 points

4. ✅ **All Deployments**
   - Web (public URL) + APK + Windows/macOS executables
   - ❌ Missing any = 0 points

5. ✅ **Demo Video Shows ALL Features**
   - Features not shown in video will NOT be graded
   - ❌ Missing demo = 0 points

6. ✅ **Project Must Run**
   - Instructor must be able to run your project
   - ❌ Cannot run despite effort = 0 points

7. ✅ **No Plagiarism**
   - Original work required
   - ❌ Plagiarism detected = 0 points

### Penalties to Avoid:

- **Late Submission**: -1.0 pt per day
- **Missing Build Instructions**: -2.0 pts
- **Unclean Project Files**: -0.5 pt (remove `node_modules`, `.dart_tool`, etc.)
- **Missing Login Credentials**: -1.0 pt
- **Insufficient Git Commits**: -0.5 pt (need ≥2 commits/week/member)

---

## Testing Checklist Before Submission

### Functional Testing
- [ ] Login works for instructor (admin/admin) and students
- [ ] CRUD works for all entities (Semester, Course, Group, Student)
- [ ] Can create all content types (Announcements, Assignments, Quizzes, Materials)
- [ ] Students can submit assignments and take quizzes
- [ ] Forum works (create topics, reply)
- [ ] Private messaging works (Student ↔ Instructor only)
- [ ] Notifications work (in-app and email)
- [ ] Tracking works (views, submissions, quiz attempts)
- [ ] CSV Import works with preview and validation
- [ ] CSV Export generates correct files
- [ ] Search, filter, sort work on all list views
- [ ] Semester switcher works, past semesters are read-only for students

### Non-Functional Testing
- [ ] Offline capability works (can view cached data offline)
- [ ] Responsive design works on mobile, tablet, desktop
- [ ] App runs on all platforms (Web, Android, Windows/macOS)
- [ ] Performance is acceptable (no lag, smooth scrolling)
- [ ] No UI overflow errors
- [ ] All images and assets load properly
- [ ] Error messages are clear and helpful

### Security Testing
- [ ] Instructor-only features blocked for students
- [ ] Students can only access their own data
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Passwords are hashed (not stored in plain text)
- [ ] Session tokens expire appropriately

---

## Quick Reference: Folder Structure

```
lib/
├── data/
│   ├── datasources/
│   │   ├── local/              # Hive, SQLite (Offline Capability)
│   │   ├── remote/             # API calls (HTTP, Firebase)
│   │   └── models/             # DTOs (Data Transfer Objects)
│   └── repositories/           # Implement domain interfaces
│
├── domain/
│   ├── entities/               # Core business entities (pure Dart)
│   ├── repositories/           # Abstract interfaces (contracts)
│   └── usecases/               # Business logic (CRUD, Tracking, etc.)
│
├── presentation/
│   ├── common/
│   │   ├── widgets/            # Reusable widgets
│   │   └── styles/             # Colors, themes, text styles
│   ├── features/
│   │   ├── auth/               # Login screens
│   │   ├── dashboard/          # Homepage (role-based)
│   │   ├── semester_course_management/  # CRUD screens
│   │   ├── student_import/     # CSV Import with Preview
│   │   ├── content_delivery/   # Announcement, Assignment, Quiz, Material
│   │   ├── tracking_reporting/ # Submission tracking, CSV Export
│   │   ├── interaction_notification/  # Forum, Messaging, Notifications
│   │   └── user_profile/       # Profile view/edit
│   └── main_app.dart
│
└── utils/
    ├── constants.dart
    ├── helper_functions.dart
    └── services/               # Email service, etc.
```

---

## Tips for Success

1. **Start Git commits NOW**: Don't wait until the end
2. **Test offline mode early**: It's mandatory and can be tricky
3. **CSV Import is complex**: Allocate enough time, it's heavily emphasized
4. **Record demo video last**: After everything is working perfectly
5. **Keep test accounts ready**: With sample data for easy testing
6. **Document as you go**: Don't leave README for the last minute
7. **Clean code before submission**: Remove debugging logs, unused files
8. **Test on multiple devices**: Web on different browsers, APK on real Android device
9. **Backup regularly**: Use Git properly, push to remote often
10. **Read rubric carefully**: Self-assess honestly to catch missing features

---

## Notes

- **Only 4 bonus features count** for points (choose wisely)
- **Features not in demo video = not graded** (record comprehensively)
- **Quality over quantity**: Better to have fewer features working perfectly than many broken features
- **IT content only**: Double-check all sample data is IT-related
- **Two roles only**: Instructor and Student (no other roles)
- **Test thoroughly**: Allocate time for testing and bug fixes

---

**Good luck! 🚀**
