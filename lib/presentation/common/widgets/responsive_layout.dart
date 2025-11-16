import 'package:flutter/material.dart';

/// Responsive layout breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Helper class to determine device type
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
        MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  static bool showSidebars(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  static bool showLeftSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  static bool showRightSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }
}

/// Responsive layout wrapper that adapts to screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget? leftSidebar;
  final Widget body;
  final Widget? rightSidebar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ResponsiveLayout({
    super.key,
    this.leftSidebar,
    required this.body,
    this.rightSidebar,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final showLeft = ResponsiveHelper.showLeftSidebar(context);
    final showRight = ResponsiveHelper.showRightSidebar(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: appBar,
      // Drawer for mobile - contains left sidebar content
      drawer: (isMobile && leftSidebar != null)
          ? Drawer(child: leftSidebar!)
          : null,
      // End drawer for right sidebar on mobile/tablet
      endDrawer: (!showRight && rightSidebar != null)
          ? Drawer(
              width: MediaQuery.of(context).size.width * 0.75,
              child: rightSidebar!,
            )
          : null,
      body: Row(
        children: [
          // Left sidebar - show on tablet and desktop
          if (showLeft && leftSidebar != null && !isMobile) leftSidebar!,

          // Main content area
          Expanded(child: body),

          // Right sidebar - show only on desktop
          if (showRight && rightSidebar != null) rightSidebar!,
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
