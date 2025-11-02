# Phase 2: Remaining Implementation Guide

##  What's Left to Implement

### 🚧 Step 4: Remote Data Sources (4 remaining)

Following the pattern in `announcement_remote_datasource.dart`, create:

1. **`assignment_remote_datasource.dart`**
   - Collection: `'assignments'`
   - Follow same CRUD pattern
   - Add query methods for open/upcoming assignments

2. **`quiz_remote_datasource.dart`**
   - Collection: `'quizzes'`
   - CRUD operations
   - Query for open/upcoming quizzes

3. **`material_remote_datasource.dart`**
   - Collection: `'materials'`
   - CRUD + file upload method
   - Filter by type

4. **`question_remote_datasource.dart`**
   - Collections: `'questionBanks'` and `'questions'`
   - Dual collection handling
   - Random question selection logic

### ⏳ Step 5: Repository Implementations (5 files)

Pattern (see existing `course_repository_impl.dart`):

```dart
class AnnouncementRepositoryImpl implements IAnnouncementRepository {
  final AnnouncementRemoteDataSource _remoteDataSource;

  AnnouncementRepositoryImpl({required AnnouncementRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<AnnouncementEntity>> getAnnouncementsByCourse(String courseId) async {
    final models = await _remoteDataSource.getAnnouncementsByCourse(courseId);
    return models.map((m) => m.toEntity()).toList();
  }

  // ... implement all interface methods
}
```

Create:
1. `announcement_repository_impl.dart`
2. `assignment_repository_impl.dart`
3. `quiz_repository_impl.dart`
4. `material_repository_impl.dart`
5. `question_repository_impl.dart`

### ⏳ Step 6: Providers (5 files)

Pattern (see existing `semester_provider.dart`):

```dart
// Provider for remote data source
final announcementRemoteDataSourceProvider = Provider<AnnouncementRemoteDataSource>((ref) {
  return AnnouncementRemoteDataSourceImpl();
});

// Provider for repository
final announcementRepositoryProvider = Provider<IAnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remoteDataSource: ref.read(announcementRemoteDataSourceProvider),
  );
});

// State notifier
class AnnouncementNotifier extends StateNotifier<AsyncValue<List<AnnouncementEntity>>> {
  final IAnnouncementRepository _repository;

  AnnouncementNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadAnnouncements(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getAnnouncementsByCourse(courseId);
      state = AsyncValue.data(announcements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // ... other methods
}

// Provider for state notifier
final announcementProvider = StateNotifierProvider<AnnouncementNotifier, AsyncValue<List<AnnouncementEntity>>>((ref) {
  return AnnouncementNotifier(ref.read(announcementRepositoryProvider));
});
```

Create in `lib/presentation/providers/`:
1. `announcement_provider.dart`
2. `assignment_provider.dart`
3. `quiz_provider.dart`
4. `material_provider.dart`
5. `question_provider.dart`

### ⏳ Step 7: UI Screens

Create management screens in `lib/presentation/features/`:

1. **Announcements** (`announcements/`)
   - `announcement_management_screen.dart` - List view
   - `announcement_form_dialog.dart` - Create/Edit form
   - `announcement_detail_screen.dart` - View details

2. **Assignments** (`assignments/`)
   - `assignment_management_screen.dart`
   - `assignment_form_dialog.dart`
   - `assignment_detail_screen.dart`

3. **Quizzes** (`quizzes/`)
   - `quiz_management_screen.dart`
   - `quiz_form_dialog.dart`
   - `quiz_builder_screen.dart` - Build quiz structure

4. **Materials** (`materials/`)
   - `material_management_screen.dart`
   - `material_form_dialog.dart`
   - `file_upload_widget.dart`

5. **Questions** (`questions/`)
   - `question_bank_screen.dart`
   - `question_list_screen.dart`
   - `question_form_dialog.dart`

## Quick Start Commands

### To create a file:
```bash
touch lib/data/datasources/remote/assignment_remote_datasource.dart
```

### To test:
```bash
flutter analyze
flutter test
```

## Firestore Collections Structure

```
firestore/
├── announcements/
│   └── {announcementId}
├── assignments/
│   └── {assignmentId}
├── quizzes/
│   └── {quizId}
├── materials/
│   └── {materialId}
├── questionBanks/
│   └── {bankId}
└── questions/
    └── {questionId}
```

## Current Status: ~55% Complete

✅ Foundation layers complete
🚧 Data access layer in progress
⏳ Presentation layer pending

## Next Steps

1. Complete remaining 4 remote data sources
2. Implement 5 repositories
3. Create 5 providers
4. Build UI screens

Estimated remaining: ~25-30 files
