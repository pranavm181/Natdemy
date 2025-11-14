import 'package:flutter/material.dart';
import '../data/student.dart';
import '../data/auth_helper.dart';
import '../data/course_catalog.dart';
import '../screens/classes.dart';
import '../screens/course_detail.dart';
import '../screens/all_courses_page.dart';
import '../screens/about_page.dart';
import '../screens/privacy_policy_page.dart';
import '../utils/image_utils.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    required this.student,
    this.onNavigateToHome,
    this.onNavigateToMyCourses,
    this.onNavigateToProfile,
  });

  final Student student;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToMyCourses;
  final VoidCallback? onNavigateToProfile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF582DB0).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: ImageUtils.getProfileImageProvider(student.profileImagePath),
                      child: ImageUtils.hasProfileImage(student.profileImagePath)
                          ? null
                          : const Icon(Icons.person, size: 40, color: Color(0xFF582DB0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          student.name.isEmpty ? 'Student' : student.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Navigation Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Navigation Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'NAVIGATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      if (onNavigateToHome != null) {
                        onNavigateToHome!();
                      } else {
                        // Navigate to home if coming from different screen
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.menu_book_outlined,
                    title: 'All Courses',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AllCoursesPage()),
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.play_circle_outline,
                    title: 'My Courses',
                    onTap: () {
                      Navigator.pop(context);
                      if (onNavigateToMyCourses != null) {
                        onNavigateToMyCourses!();
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      if (onNavigateToProfile != null) {
                        onNavigateToProfile!();
                      }
                    },
                  ),
                  const Divider(height: 32, indent: 20, endIndent: 20),
                  // Settings Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      if (onNavigateToProfile != null) {
                        onNavigateToProfile!();
                      }
                    },
                  ),
                  const Divider(height: 32, indent: 20, endIndent: 20),
                  // About Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Sign Out Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _DrawerMenuItem(
                icon: Icons.logout,
                title: 'Sign Out',
                iconColor: const Color(0xFFEF4444),
                textColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await AuthHelper.clearLoginData();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          },
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Drawer Menu Item Widget ---

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? const Color(0xFF582DB0);
    final defaultTextColor = textColor ?? const Color(0xFF1E293B);

    return ListTile(
      leading: Icon(icon, color: defaultIconColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: defaultTextColor,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

