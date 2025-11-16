import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/left_sidebar.dart';
import '../../common/widgets/offline_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../messaging/chat_list_screen.dart';
import '../semester/semester_management_screen.dart';
import '../course/course_management_screen.dart';
import '../student/student_management_screen.dart';

class InstructorDashboard extends ConsumerStatefulWidget {
  const InstructorDashboard({super.key});

  @override
  ConsumerState<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState extends ConsumerState<InstructorDashboard> {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Home/Dashboard
    const SemesterManagementScreen(), // 1: Semesters
    const CourseManagementScreen(), // 2: Courses
    const StudentManagementScreen(), // 3: Students
    const Placeholder(), // 4: Settings (TODO)
  ];

  void _onItemTapped(int index) async {
    if (index == 5) {
      // Logout
      await _handleLogout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Offline Indicator
          const OfflineIndicator(),

          // Main Content Row
          Expanded(
            child: Row(
              children: [
                // Left Sidebar
                LeftSidebar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
                // Main Content
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: userAsync.when(
        data: (user) {
          if (user == null) return null;

          final unreadCountAsync = ref.watch(unreadChatCountProvider(user.uid));

          return unreadCountAsync.when(
            data: (unreadCount) => Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.buttonPrimary,
                  child: const Icon(Icons.message, color: Colors.white),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            loading: () => FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.buttonPrimary,
              child: const Icon(Icons.message, color: Colors.white),
            ),
            error: (_, __) => FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.buttonPrimary,
              child: const Icon(Icons.message, color: Colors.white),
            ),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
