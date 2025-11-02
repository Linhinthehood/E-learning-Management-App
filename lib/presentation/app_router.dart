import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user_entity.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/instructor/instructor_dashboard.dart';
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

        // User is logged in - check role and route accordingly
        if (user.role == UserRole.instructor) {
          // Navigate to Instructor Dashboard
          return const InstructorDashboard();
        } else {
          // Navigate to Student Dashboard
          // For now, using the existing DashboardScreen
          // TODO: Create separate StudentDashboard
          return const DashboardScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
