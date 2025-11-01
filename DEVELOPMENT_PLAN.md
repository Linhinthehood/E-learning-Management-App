# E-Learning Management App - Development Plan

## Phase 1: Foundation & Setup

### 1.1 Project Infrastructure
- ✅ Set up Flutter project structure with proper folder organization
- ✅ Create constants (colors, themes, strings)
- ✅ Set up basic routing and navigation
- Set up state management solution (Provider/Riverpod/Bloc)
- Configure environment variables and app configuration

### 1.2 Database & Local Storage
- Implement SQLite/Hive for offline capability
- Design database schema:
  - Users (Instructor, Students)
  - Semesters
  - Courses
  - Groups
  - Assignments
  - Quizzes
  - Announcements
  - Materials
  - Messages
  - Notifications
- Create data models and repository pattern
- Implement data synchronization logic

### 1.3 Authentication System
- ✅ Complete login screen UI
- Implement authentication logic
- Create user roles (Instructor: admin/admin, Students)
- Implement session management
- Add logout functionality
- Create protected routes

## Phase 2: Core Features - Interface Structure

### 2.1 Role-Based Homepage
- ✅ Student homepage with course cards (partially complete)
- Instructor homepage with dashboard metrics
- Implement semester switcher with current/past semesters
- Make past semesters read-only for students

### 2.2 Course Space - Three Tabs
- **Stream Tab**: Display announcements and recent activities
- **Classwork Tab**: Show assignments, quizzes, and materials
- **People Tab**: List instructors, students, and groups

### 2.3 User Profile
- Create user profile screen
- Display avatar and basic information
- Allow profile editing (real names required)
- Upload/change profile picture

## Phase 3: Core Features - Data Management (2.0 pts)

### 3.1 Hierarchy Implementation
- Implement Semester → Course → Group → Student hierarchy
- Create CRUD operations for all entities
- Ensure data integrity and relationships

### 3.2 CSV Import
- Build CSV import interface with preview
- Implement validation logic
- Handle duplicate detection intelligently
- Enforce rule: Students can belong to only one group per course
- Show import success/error feedback

## Phase 4: Core Features - Content Distribution (2.0 pts)

### 4.1 Announcements
- Create announcement posting interface (Instructor)
- Implement group-scoped announcements
- Add commenting functionality
- Track who viewed announcements
- Display announcements in Stream tab

### 4.2 Assignments
- Create assignment creation interface (Instructor)
- Implement deadline management
- Handle late submissions
- Set attempt limits
- Grade tracking and submission review
- Student submission interface
- File upload/download functionality

### 4.3 Quizzes
- Build question bank system with difficulty levels
- Implement quiz creation with randomization
- Add timer functionality for timed quizzes
- Track quiz attempts and scores
- Auto-grading for multiple choice/true-false
- Show results and feedback

### 4.4 Materials
- Create materials upload interface (Instructor)
- Implement course-wide visibility
- Track download counts
- Support multiple file formats
- Organize materials by topics/modules

## Phase 5: Core Features - Interaction & Notifications (2.0 pts)

### 5.1 Forum System
- Build course-level discussion forum
- Create thread and reply functionality
- Implement upvoting/helpful marking
- Add search and filter for forum posts
- No student-to-student direct messaging (enforce rule)

### 5.2 Private Messaging
- Implement Student ↔ Instructor only messaging
- Create message inbox/sent folders
- Real-time message indicators
- Mark as read/unread functionality

### 5.3 Notifications
- In-app notification system for students
- Email notifications for key events:
  - New assignment posted
  - Assignment graded
  - Upcoming deadline reminders
  - New announcements
  - Quiz available
- Notification preferences/settings

## Phase 6: Core Features - Analytics & Reports (2.0 pts)

### 6.1 Instructor Dashboard
- Create comprehensive dashboard with metrics:
  - Student progress charts
  - Assignment submission rates
  - Quiz performance statistics
  - Course engagement metrics
- Visualize data with charts/graphs

### 6.2 CSV Export
- Implement export for assignments (grades, submissions)
- Implement export for quizzes (scores, attempts)
- Support individual and bulk export
- Generate formatted CSV reports

### 6.3 Search, Filter, Sort
- Add search functionality to all list views:
  - Courses
  - Students
  - Assignments
  - Quizzes
  - Announcements
- Implement filters (by date, status, group, etc.)
- Add sorting options (name, date, score, etc.)

## Phase 7: Core Features - Student Features (2.0 pts)

### 7.1 Personal Dashboard
- ✅ Basic dashboard layout complete
- Add progress tracking widgets
- Display upcoming deadlines
- Show recent grades
- Course completion percentage
- Personal statistics

### 7.2 Past Semesters
- Implement read-only access to past semesters
- Archive completed courses
- View historical grades and submissions
- Cannot submit new work for past semesters

## Phase 8: UI/UX Polish (1.0 pt)

### 8.1 UI Refinement
- ✅ Implement black and white theme consistently
- Ensure responsive design for mobile, tablet, desktop
- Polish all screens for visual consistency
- Add loading states and skeletons
- Create empty states
- Add smooth transitions and animations

### 8.2 UX Improvements
- Optimize navigation flow
- Add breadcrumbs for deep navigation
- Implement intuitive error messages
- Add confirmation dialogs for destructive actions
- Create onboarding/tutorial for first-time users
- Ensure accessibility (keyboard navigation, screen readers)

## Phase 9: Performance Optimization

### 9.1 Caching
- Implement data caching strategies
- Cache images and files locally
- Use pagination for large lists
- Lazy load content where appropriate

### 9.2 Search/Filter/Sort Optimization
- Index database tables properly
- Optimize query performance
- Implement debouncing for search
- Use virtual scrolling for long lists

## Phase 10: Deployment (1.0 pt)

### 10.1 Web Deployment (0.5 pts)
- Build Flutter web version
- Optimize for web performance
- Handle cold start issues
- Deploy to hosting platform (Firebase Hosting, Netlify, Vercel)
- Ensure public accessibility
- Test on multiple browsers

### 10.2 Mobile & Desktop Build
- Build Android APK (arm64) - Mandatory
- Build Windows executable - Mandatory
- Build macOS executable - Mandatory
- Test on physical devices
- Optimize app size
- Handle platform-specific issues

## Phase 11: Testing & Quality Assurance

### 11.1 Manual Testing
- Test all user flows (student and instructor)
- Test on different screen sizes
- Test offline functionality
- Test edge cases and error scenarios
- Security testing (SQL injection, XSS, etc.)

### 11.2 Bug Fixes
- Fix identified bugs
- Handle error cases gracefully
- Improve error messages
- Test fixes thoroughly

## Phase 12: Bonus Features (Max 4 features, 0.25-0.5 pts each)

### 12.1 Real-time WebSocket Features (0.5 pts) - HIGHLY RECOMMENDED
- Implement WebSocket connection (Socket.io)
- Real-time notifications (new announcement, assignment graded)
- Live messaging between student-instructor
- Real-time forum updates (replies appear instantly)
- Online/offline status indicators
- Live quiz participation counter
- Document with before/after comparisons

### 12.2 Docker + Kubernetes (0.5 pts) - HIGHLY RECOMMENDED
- Dockerize Flutter web application
- Dockerize backend services
- Dockerize database
- Create docker-compose.yml for local development
- Create Kubernetes manifests:
  - Deployments
  - Services
  - ConfigMaps
  - Secrets
- Implement auto-scaling (HPA)
- Add health checks and probes
- Configure rolling updates
- Set resource limits
- Document deployment process

### 12.3 AI Chatbot with RAG (0.5 pts) - PRIMARY FOCUS
- Integrate AI chatbot API
- Implement RAG (Retrieval-Augmented Generation)
- Train on course materials and FAQs
- Add chat interface in app
- Support course-specific queries
- Document AI implementation

### 12.4 AI Question Generator (0.5 pts) - SECONDARY
- Integrate AI question generation API
- Allow instructors to generate quiz questions
- Support multiple question types
- Allow editing of generated questions
- Demonstrate quality of generated content

### 12.5 Advanced Testing Suite (0.5 pts) - RECOMMENDED
- Write unit tests (>70% coverage for business logic)
- Write widget tests for Flutter UI components
- Write integration tests for API endpoints and database
- Write E2E tests for critical flows:
  - Login
  - Submit assignment
  - Take quiz
  - Post announcement
- Generate HTML coverage reports
- Add coverage badge to README
- Set up automated test runs in CI/CD

### 12.6 CI/CD Pipeline
- Set up GitHub Actions or GitLab CI
- Automate testing on every commit
- Automate builds for Android/Web
- Automate deployment to staging/production
- Add build status badges to README

## Phase 13: Documentation & Submission

### 13.1 Code Documentation
- Clean up code and remove unused files
- Add comments for complex logic
- Update README.txt with:
  - Build instructions
  - Deployment URLs
  - Login credentials (admin/admin for instructor, test student accounts)
- Create API documentation if backend exists

### 13.2 Video Demo
- Plan demo script covering all features
- Record demo video (≥1080p):
  - Show login as instructor
  - Demonstrate all instructor features
  - Show login as student
  - Demonstrate all student features
  - Show responsive design (mobile, tablet, desktop)
  - Show offline capability
  - Demonstrate bonus features
- Edit video to be clear and concise

### 13.3 GitHub Evidence
- Ensure ≥2 commits/week/member for ≥1 month
- Take screenshots of GitHub Insights:
  - Contributor graphs
  - Commit history
  - Pull request activity
- Clean commit messages and proper branching

### 13.4 Submission Package
- Create folder structure: `id1_fullname1_id2_fullname2.zip`
  - `source/`: Complete cleaned source code
  - `bin/`: APK + Windows EXE (+ macOS if available)
  - `demo.mp4`: Feature demonstration video
  - `git/`: GitHub Insights screenshots only
  - `Readme.txt`: Build instructions, URLs, credentials
  - `Bonus/`: Evidence of bonus features
  - `Rubrik.docx`: Self-assessment checklist
- Verify all files are included
- Test that builds work from source
- Submit before deadline

## Critical Checkpoints

### Content Validation
- ✅ Ensure all courses, materials, and content are IT-related ONLY
- ✅ No irrelevant content (non-IT topics) = 0 points penalty
- ✅ Examples: Programming, Databases, AI, Machine Learning, Web Dev, Mobile Dev, etc.

### Mandatory Requirements
- ✅ Source code included and runnable
- ✅ Rubric.docx submitted
- ✅ Web deployment + APK + Windows/macOS executables
- ✅ Demo video shows ALL features
- ✅ Offline capability implemented (SQLite/Hive)
- ✅ Two roles properly implemented
- ✅ GitHub collaboration evidence

### Avoid Penalties
- ✅ Submit on time (late = -1.0 pt per day)
- ✅ Include build instructions (-2.0 pts if missing)
- ✅ Clean project files (-0.5 pt if unclean)
- ✅ Include login credentials (-1.0 pt if missing)
- ✅ No code plagiarism (0 points if detected)

## Notes
- Features not shown in demo video will NOT be graded
- Maximum 4 bonus features for points
- Focus on quality over quantity
- Test thoroughly before submission
- Keep backups of all work
