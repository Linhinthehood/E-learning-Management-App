import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user_entity.dart';
import '../utils/services/presence_service.dart';
import 'features/auth/login_screen.dart';
import 'features/instructor/instructor_dashboard.dart';
import 'features/student/student_dashboard.dart';
import 'providers/auth_provider.dart';

/// App router that handles role-based navigation
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // No user logged in - show login screen
          return const LoginScreen();
        }

        // User is logged in - wrap with presence tracking
        return PresenceWrapper(
          userId: user.uid,
          child: user.role == UserRole.instructor
              ? const InstructorDashboard()
              : const StudentDashboard(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const LoginScreen(),
    );
  }
}

/// Wrapper widget that initializes and manages user presence tracking
class PresenceWrapper extends ConsumerStatefulWidget {
  final String userId;
  final Widget child;

  const PresenceWrapper({super.key, required this.userId, required this.child});

  @override
  ConsumerState<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends ConsumerState<PresenceWrapper> {
  PresenceService? _presenceService;

  @override
  void initState() {
    super.initState();
    _initializePresence();
  }

  Future<void> _initializePresence() async {
    _presenceService = ref.read(presenceServiceProvider(widget.userId));
    await _presenceService?.initialize();
  }

  @override
  void dispose() {
    _presenceService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
