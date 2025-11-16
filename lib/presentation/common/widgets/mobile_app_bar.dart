import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/colors.dart';
import 'responsive_layout.dart';

/// Mobile-friendly AppBar with hamburger menu and actions
class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;
  final bool showEndDrawerButton;
  final VoidCallback? onMenuPressed;

  const MobileAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
    this.showEndDrawerButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final showLeftSidebar = ResponsiveHelper.showLeftSidebar(context);
    final showRightSidebar = ResponsiveHelper.showRightSidebar(context);

    return AppBar(
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      centerTitle: isMobile,
      // Show hamburger menu only on mobile
      leading: (isMobile && showMenuButton)
          ? IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: onMenuPressed ??
                  () {
                    Scaffold.of(context).openDrawer();
                  },
            )
          : null,
      // Show drawer button only when left sidebar is hidden
      automaticallyImplyLeading: !showLeftSidebar && showMenuButton,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // Custom actions
        if (actions != null) ...actions!,

        // Show end drawer button only when right sidebar is hidden
        if (!showRightSidebar && showEndDrawerButton)
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            tooltip: 'More',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
