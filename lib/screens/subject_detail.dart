import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import 'materials_page.dart';
import 'live_upcoming.dart';
import 'lesson_detail.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({
    super.key,
    required this.chapter,
    this.courseTitle,
  });

  final CourseChapter chapter;
  final String? courseTitle;

  @override
  Widget build(BuildContext context) {
    final actionColors = [
      const Color(0xFFE100FF), // Live
      const Color(0xFF0072FF), // Material
      const Color(0xFFFF6B6B), // Assignments
      const Color(0xFF4ECDC4), // Mock Tests
    ];

    final actions = [
      _ActionItem('Live', Icons.live_tv_outlined, actionColors[0], () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveUpcomingPage()));
      }),
      _ActionItem('Material', Icons.folder_open_outlined, actionColors[1], () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MaterialsPage(
              courseTitle: courseTitle ?? chapter.title,
              courseId: chapter.courseId,
            ),
          ),
        );
      }),
      _ActionItem('Assignments', Icons.assignment_outlined, actionColors[2], () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignments coming soon')));
      }),
      _ActionItem('Mock Tests', Icons.fact_check_outlined, actionColors[3], () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock tests coming soon')));
      }),
    ];

    final lessons = chapter.lessons.isNotEmpty
        ? chapter.lessons
        : getLessonsForChapter(chapter.title)
            .map((name) => CourseLesson(title: name))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: Text(
          chapter.title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final a = actions[index];
              return OutlinedButton.icon(
                onPressed: a.onTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                  foregroundColor: const Color(0xFF582DB0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(a.icon, size: 20),
                label: Text(
                  a.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF582DB0), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LESSONS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF000000),
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...lessons.map(
                    (lesson) => Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.15),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF582DB0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.play_circle_outline, color: Color(0xFF582DB0), size: 28),
                        ),
                        title: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF582DB0), size: 28),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LessonDetailPage(
                                lessonName: lesson.title,
                                lesson: lesson,
                                courseTitle: courseTitle ?? chapter.title,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening question bank...'),
                    backgroundColor: Color(0xFF582DB0),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF582DB0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.help_outline, size: 20),
              label: const Text(
                'Question Bank',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
