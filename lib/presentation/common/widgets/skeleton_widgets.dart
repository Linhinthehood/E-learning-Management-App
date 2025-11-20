import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../styles/colors.dart';

/// Base shimmer widget for skeleton loading
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.border,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Skeleton box with customizable width and height
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for course card
class SkeletonCourseCard extends StatelessWidget {
  const SkeletonCourseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image skeleton
          Expanded(
            flex: 3,
            child: SkeletonBox(width: double.infinity, borderRadius: 0),
          ),
          // Course info skeleton
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 20, width: double.infinity),
                  const SizedBox(height: 8),
                  SkeletonBox(height: 14, width: 120),
                  const Spacer(),
                  SkeletonBox(height: 36, width: double.infinity),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(height: 14, width: 100),
                      Row(
                        children: [
                          SkeletonBox(height: 24, width: 24),
                          const SizedBox(width: 8),
                          SkeletonBox(height: 24, width: 24),
                          const SizedBox(width: 8),
                          SkeletonBox(height: 24, width: 24),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for course grid
class SkeletonCourseGrid extends StatelessWidget {
  final int itemCount;

  const SkeletonCourseGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth < 1400) {
          crossAxisCount = 3;
          childAspectRatio = 1.0;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.1;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => const SkeletonCourseCard(),
        );
      },
    );
  }
}

/// Skeleton for announcement card
class SkeletonAnnouncementCard extends StatelessWidget {
  const SkeletonAnnouncementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 24, width: double.infinity),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 14, width: 120),
                  ],
                ),
              ),
              SkeletonBox(height: 24, width: 24),
            ],
          ),
          const SizedBox(height: 16),
          // Content lines
          SkeletonBox(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          SkeletonBox(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          SkeletonBox(height: 14, width: 200),
          const SizedBox(height: 16),
          // Divider
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          // Comments section
          SkeletonBox(height: 16, width: 100),
          const SizedBox(height: 12),
          // Comment input
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 40, width: double.infinity)),
              const SizedBox(width: 8),
              SkeletonBox(height: 40, width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for announcement list
class SkeletonAnnouncementList extends StatelessWidget {
  final int itemCount;

  const SkeletonAnnouncementList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonAnnouncementCard(),
    );
  }
}

/// Skeleton for people/student item
class SkeletonStudentItem extends StatelessWidget {
  const SkeletonStudentItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SkeletonBox(height: 40, width: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 150),
                const SizedBox(height: 4),
                SkeletonBox(height: 14, width: 200),
              ],
            ),
          ),
          SkeletonBox(height: 24, width: 60),
          const SizedBox(width: 8),
          SkeletonBox(height: 24, width: 24),
        ],
      ),
    );
  }
}

/// Skeleton for group card
class SkeletonGroupCard extends StatelessWidget {
  const SkeletonGroupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Row(
              children: [
                SkeletonBox(height: 40, width: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 18, width: 150),
                      const SizedBox(height: 4),
                      SkeletonBox(height: 14, width: 100),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Students list
            ...List.generate(3, (index) => const SkeletonStudentItem()),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for people tab
class SkeletonPeopleTab extends StatelessWidget {
  const SkeletonPeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(height: 24, width: 100),
                Wrap(
                  spacing: 12,
                  children: [
                    SkeletonBox(height: 40, width: 120),
                    SkeletonBox(height: 40, width: 140),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Instructor section skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SkeletonBox(height: 60, width: 60, borderRadius: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 16, width: 100),
                        const SizedBox(height: 8),
                        SkeletonBox(height: 20, width: 150),
                        const SizedBox(height: 4),
                        SkeletonBox(height: 14, width: 200),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          // Search bar skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 48, width: double.infinity),
          ),
          const SizedBox(height: 16),
          // Groups list skeleton
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const SkeletonGroupCard(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Skeleton for statistics card
class SkeletonStatisticsCard extends StatelessWidget {
  const SkeletonStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 16, width: 100),
          const SizedBox(height: 12),
          SkeletonBox(height: 32, width: 120),
          const SizedBox(height: 8),
          SkeletonBox(height: 14, width: 80),
        ],
      ),
    );
  }
}

/// Skeleton for dashboard statistics cards
class SkeletonDashboardStatistics extends StatelessWidget {
  const SkeletonDashboardStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 1.2 : 1.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const SkeletonStatisticsCard(),
        );
      },
    );
  }
}

/// Skeleton for dashboard content
class SkeletonDashboardContent extends StatelessWidget {
  const SkeletonDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting skeleton
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 32, width: 250),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 16, width: 300),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width >= 600) ...[
                const SizedBox(width: 30),
                SkeletonBox(height: 120, width: 120, borderRadius: 15),
              ],
            ],
          ),
          const SizedBox(height: 30),
          // Statistics cards
          const SkeletonDashboardStatistics(),
          const SizedBox(height: 30),
          // Charts skeleton
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(height: 300, width: double.infinity),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SkeletonBox(height: 300, width: double.infinity),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  SkeletonBox(height: 300, width: double.infinity),
                  const SizedBox(height: 24),
                  SkeletonBox(height: 300, width: double.infinity),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          // Activity feed skeleton
          SkeletonBox(height: 400, width: double.infinity),
        ],
      ),
    );
  }
}

/// Skeleton for student dashboard content
class SkeletonStudentDashboardContent extends StatelessWidget {
  const SkeletonStudentDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting skeleton
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 32, width: 250),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 16, width: 200),
                  ],
                ),
              ),
              SkeletonBox(height: 120, width: 120, borderRadius: 15),
            ],
          ),
          const SizedBox(height: 30),
          // Semester switcher skeleton
          SkeletonBox(height: 48, width: double.infinity),
          const SizedBox(height: 20),
          // Statistics cards
          const SkeletonDashboardStatistics(),
          const SizedBox(height: 24),
          // Content sections
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          SkeletonBox(height: 300, width: double.infinity),
                          const SizedBox(height: 24),
                          SkeletonBox(height: 250, width: double.infinity),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SkeletonBox(height: 400, width: double.infinity),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  SkeletonBox(height: 300, width: double.infinity),
                  const SizedBox(height: 24),
                  SkeletonBox(height: 250, width: double.infinity),
                  const SizedBox(height: 24),
                  SkeletonBox(height: 400, width: double.infinity),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Skeleton for semester selector
class SkeletonSemesterSelector extends StatelessWidget {
  const SkeletonSemesterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SkeletonBox(height: 24, width: double.infinity),
    );
  }
}

/// Skeleton for classwork item card
class SkeletonClassworkItem extends StatelessWidget {
  const SkeletonClassworkItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 24, width: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 20, width: double.infinity),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 14, width: 150),
                  ],
                ),
              ),
              SkeletonBox(height: 24, width: 24),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonBox(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          SkeletonBox(height: 14, width: 200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(height: 24, width: 100),
              SkeletonBox(height: 32, width: 100),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for classwork tab
class SkeletonClassworkTab extends StatelessWidget {
  const SkeletonClassworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(height: 24, width: 150),
                SkeletonBox(height: 40, width: 100),
              ],
            ),
          ),
        ),
        // Search bar skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 48, width: double.infinity),
          ),
        ),
        // Filters skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SkeletonBox(
                        height: 56,
                        width: constraints.maxWidth < 400
                            ? double.infinity
                            : (constraints.maxWidth - 24) / 2,
                      ),
                      SkeletonBox(
                        height: 56,
                        width: constraints.maxWidth < 400
                            ? double.infinity
                            : (constraints.maxWidth - 24) / 2,
                      ),
                      SkeletonBox(
                        height: 56,
                        width: constraints.maxWidth < 400
                            ? double.infinity
                            : (constraints.maxWidth - 24) / 2,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(height: 56, width: double.infinity),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SkeletonBox(height: 56, width: double.infinity),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SkeletonBox(height: 56, width: double.infinity),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // Items list skeleton
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const SkeletonClassworkItem(),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for course detail screen
class SkeletonCourseDetailScreen extends StatelessWidget {
  const SkeletonCourseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: SkeletonBox(height: 24, width: 24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 18, width: 200),
            const SizedBox(height: 4),
            SkeletonBox(height: 12, width: 100),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 48, width: double.infinity)),
              Expanded(child: SkeletonBox(height: 48, width: double.infinity)),
              Expanded(child: SkeletonBox(height: 48, width: double.infinity)),
            ],
          ),
        ),
      ),
      body: const SkeletonAnnouncementList(),
    );
  }
}
