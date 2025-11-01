import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../widgets/course_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'E-Learning Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                'JD',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSemesterSelector(context),
            _buildCoursesSection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  'John Doe',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'student@example.com',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Courses'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assignments'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Quizzes'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.forum),
            title: const Text('Forums'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'John Doe',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('8', 'Courses', Icons.book),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard('12', 'Assignments', Icons.assignment),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard('5', 'Upcoming', Icons.schedule),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Semester 1 - 2024',
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: [
                    'Semester 1 - 2024',
                    'Semester 2 - 2023',
                    'Semester 1 - 2023',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection(BuildContext context) {
    final courses = [
      {
        'title': 'Mobile App Development',
        'instructor': 'Dr. Sarah Johnson',
        'code': 'CS401',
        'color': const Color(0xFF6366F1),
        'students': 45,
        'assignments': 3,
      },
      {
        'title': 'Database Management Systems',
        'instructor': 'Prof. Michael Chen',
        'code': 'CS302',
        'color': const Color(0xFFEC4899),
        'students': 38,
        'assignments': 5,
      },
      {
        'title': 'Artificial Intelligence',
        'instructor': 'Dr. Emily Watson',
        'code': 'CS501',
        'color': const Color(0xFF10B981),
        'students': 52,
        'assignments': 2,
      },
      {
        'title': 'Web Development',
        'instructor': 'Prof. David Martinez',
        'code': 'CS305',
        'color': const Color(0xFFF59E0B),
        'students': 41,
        'assignments': 4,
      },
      {
        'title': 'Data Structures & Algorithms',
        'instructor': 'Dr. Lisa Anderson',
        'code': 'CS201',
        'color': const Color(0xFF8B5CF6),
        'students': 56,
        'assignments': 6,
      },
      {
        'title': 'Machine Learning',
        'instructor': 'Prof. James Wilson',
        'code': 'CS502',
        'color': const Color(0xFF06B6D4),
        'students': 34,
        'assignments': 3,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Courses',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                // Desktop: 3 columns
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) => CourseCard(
                    title: courses[index]['title'] as String,
                    instructor: courses[index]['instructor'] as String,
                    courseCode: courses[index]['code'] as String,
                    color: courses[index]['color'] as Color,
                    students: courses[index]['students'] as int,
                    assignments: courses[index]['assignments'] as int,
                  ),
                );
              } else if (constraints.maxWidth > 600) {
                // Tablet: 2 columns
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) => CourseCard(
                    title: courses[index]['title'] as String,
                    instructor: courses[index]['instructor'] as String,
                    courseCode: courses[index]['code'] as String,
                    color: courses[index]['color'] as Color,
                    students: courses[index]['students'] as int,
                    assignments: courses[index]['assignments'] as int,
                  ),
                );
              } else {
                // Mobile: 1 column
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: CourseCard(
                      title: courses[index]['title'] as String,
                      instructor: courses[index]['instructor'] as String,
                      courseCode: courses[index]['code'] as String,
                      color: courses[index]['color'] as Color,
                      students: courses[index]['students'] as int,
                      assignments: courses[index]['assignments'] as int,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
