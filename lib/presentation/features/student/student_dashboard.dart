import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/student_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../auth/login_screen.dart';
import '../messaging/chat_list_screen.dart';
import '../notifications/notification_list_screen.dart';
import 'student_homepage.dart';
import 'student_profile_screen.dart';

/// Student Dashboard with sidebar navigation
class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const StudentHomepage(), // 0: Homepage
    const StudentProfileScreen(), // 1: Profile
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {
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
      body: Row(
        children: [
          // Left Sidebar
          StudentSidebar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
          // Main Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      floatingActionButton: userAsync.when(
        data: (user) {
          if (user == null) return null;

          final unreadChatCountAsync = ref.watch(unreadChatCountProvider(user.uid));
          final unreadNotificationCountAsync = ref.watch(
            unreadNotificationCountProvider(user.uid),
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Notifications FAB
              unreadNotificationCountAsync.when(
                data: (unreadNotificationCount) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FloatingActionButton(
                      heroTag: 'notifications',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationListScreen(),
                          ),
                        );
                      },
                      backgroundColor: AppColors.buttonPrimary,
                      child: const Icon(Icons.notifications, color: Colors.white),
                    ),
                    if (unreadNotificationCount > 0)
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
                              unreadNotificationCount > 99
                                  ? '99+'
                                  : unreadNotificationCount.toString(),
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
                  heroTag: 'notifications',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationListScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.buttonPrimary,
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                error: (_, __) => FloatingActionButton(
                  heroTag: 'notifications',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationListScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.buttonPrimary,
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              // Messages FAB
              unreadChatCountAsync.when(
                data: (unreadChatCount) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FloatingActionButton(
                      heroTag: 'messages',
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
                    if (unreadChatCount > 0)
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
                              unreadChatCount > 99
                                  ? '99+'
                                  : unreadChatCount.toString(),
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
                  heroTag: 'messages',
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
                  heroTag: 'messages',
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
              ),
            ],
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
