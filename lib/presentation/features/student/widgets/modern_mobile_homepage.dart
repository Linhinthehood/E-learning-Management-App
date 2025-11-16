import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../messaging/chat_list_screen.dart';
import '../../notifications/notification_list_screen.dart';
import '../student_profile_screen.dart';
import '../student_homepage.dart';

/// Modern mobile-first homepage design for students
class ModernMobileHomepage extends ConsumerStatefulWidget {
  const ModernMobileHomepage({super.key});

  @override
  ConsumerState<ModernMobileHomepage> createState() => _ModernMobileHomepageState();
}

class _ModernMobileHomepageState extends ConsumerState<ModernMobileHomepage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper methods for responsive sizing
  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 320) return 3; // Very small phones
    if (width < 380) return 3; // Small phones
    return 4; // Normal phones
  }

  double _getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 320) return 48; // Very small
    if (width < 380) return 56; // Small
    return 60; // Normal
  }

  double _getCarouselHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 120;
    if (width < 400) return 140;
    return 160;
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header
                _buildTopHeader(user.displayName, user.avatarUrl),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Banner Carousel
                        _buildBannerCarousel(),

                        const SizedBox(height: 24),

                        // Recently Used Section
                        _buildSection(
                          'Recently Used',
                          Icons.history,
                          _getRecentlyUsedItems(),
                        ),

                        const SizedBox(height: 24),

                        // Academic Services Section
                        _buildSection(
                          'Academic Services',
                          Icons.school_outlined,
                          _getAcademicItems(),
                        ),

                        const SizedBox(height: 24),

                        // Student Affairs Section
                        _buildSection(
                          'Student Affairs',
                          Icons.people_outline,
                          _getStudentAffairsItems(),
                        ),

                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Navigation Bar
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  /// Top header with profile, search, and notifications
  Widget _buildTopHeader(String displayName, String? photoURL) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile and Notification Row
          Row(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.buttonPrimary,
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                child: photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Notification Bell
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
                    // Notification badge
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search features...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner carousel for announcements
  Widget _buildBannerCarousel() {
    final banners = [
      {
        'title': 'Welcome Back!',
        'subtitle': 'Continue your learning journey',
        'icon': Icons.waving_hand,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Upcoming Deadlines',
        'subtitle': 'Check your assignments',
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFFEC4899),
      },
      {
        'title': 'New Announcements',
        'subtitle': 'View latest updates',
        'icon': Icons.campaign_outlined,
        'color': const Color(0xFF10B981),
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: _getCarouselHeight(context),
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: banners.map((banner) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                banner['color'] as Color,
                (banner['color'] as Color).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (banner['color'] as Color).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banner['subtitle'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  banner['icon'] as IconData,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build a section with title and grid of items
  Widget _buildSection(String title, IconData icon, List<QuickAccessItem> items) {
    final padding = _getResponsivePadding(context);
    final columns = _getGridColumns(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grid of Items - Responsive columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildQuickAccessButton(
                item.icon,
                item.label,
                item.onTap,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Quick access button with uniform design
  Widget _buildQuickAccessButton(IconData icon, String label, VoidCallback onTap) {
    final iconSize = _getIconSize(context);
    final iconPadding = iconSize * 0.47; // Icon is 47% of container size

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container - Rounded Square (responsive size)
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(iconSize * 0.27), // ~16px for 60px
              border: Border.all(
                color: AppColors.textPrimary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: iconPadding,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Label (responsive font size)
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: iconSize < 56 ? 10 : 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', true, () {}),
              _buildNavItem(Icons.school_outlined, Icons.school, 'Courses', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentHomepage()),
                );
              }),
              _buildNavItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationListScreen()),
                );
              }),
              _buildNavItem(Icons.message_outlined, Icons.message, 'Messages', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatListScreen()),
                );
              }),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              size: 26,
              color: isActive ? AppColors.buttonPrimary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isActive ? AppColors.buttonPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get items for each section
  List<QuickAccessItem> _getRecentlyUsedItems() {
    return [
      QuickAccessItem(Icons.school_outlined, 'My Courses', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomepage()),
        );
      }),
      QuickAccessItem(Icons.message_outlined, 'Messages', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      }),
      QuickAccessItem(Icons.notifications_outlined, 'Notifications', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationListScreen()),
        );
      }),
      QuickAccessItem(Icons.person_outline, 'Profile', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
        );
      }),
    ];
  }

  List<QuickAccessItem> _getAcademicItems() {
    return [
      QuickAccessItem(Icons.school_outlined, 'Courses', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomepage()),
        );
      }),
      QuickAccessItem(Icons.person_outline, 'Profile', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
        );
      }),
      QuickAccessItem(Icons.message_outlined, 'Messages', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      }),
      QuickAccessItem(Icons.notifications_outlined, 'Notifications', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationListScreen()),
        );
      }),
    ];
  }

  List<QuickAccessItem> _getStudentAffairsItems() {
    return [
      QuickAccessItem(Icons.school_outlined, 'My Courses', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomepage()),
        );
      }),
      QuickAccessItem(Icons.message_outlined, 'Messages', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      }),
      QuickAccessItem(Icons.notifications_outlined, 'Notifications', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationListScreen()),
        );
      }),
      QuickAccessItem(Icons.person_outline, 'Profile', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
        );
      }),
    ];
  }
}

/// Model for quick access items
class QuickAccessItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  QuickAccessItem(this.icon, this.label, this.onTap);
}
