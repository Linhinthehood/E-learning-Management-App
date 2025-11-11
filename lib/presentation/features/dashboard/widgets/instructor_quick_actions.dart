import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';

/// Quick Action Buttons Widget for Instructor Dashboard
class InstructorQuickActions extends StatelessWidget {
  const InstructorQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.campaign,
                label: 'Create Announcement',
                color: Colors.blue,
                onTap: () {
                  // Navigate to create announcement
                  _showComingSoon(context, 'Create Announcement');
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.assignment,
                label: 'Create Assignment',
                color: Colors.orange,
                onTap: () {
                  // Navigate to create assignment
                  _showComingSoon(context, 'Create Assignment');
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.quiz,
                label: 'Create Quiz',
                color: Colors.purple,
                onTap: () {
                  // Navigate to create quiz
                  _showComingSoon(context, 'Create Quiz');
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.description,
                label: 'Upload Material',
                color: Colors.green,
                onTap: () {
                  // Navigate to upload material
                  _showComingSoon(context, 'Upload Material');
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.school,
                label: 'View All Courses',
                color: Colors.teal,
                onTap: () {
                  // Navigate to course management
                  Navigator.pop(context); // Go back to main dashboard
                  // The instructor dashboard already has course management in sidebar
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.people,
                label: 'Manage Students',
                color: Colors.pink,
                onTap: () {
                  // Navigate to student management
                  _showComingSoon(context, 'Manage Students');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Navigate to respective screen from sidebar'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.buttonPrimary,
      ),
    );
  }
}
