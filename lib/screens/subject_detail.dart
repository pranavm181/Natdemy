import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import '../utils/animations.dart';
import 'materials_page.dart';
import 'live_upcoming.dart';
import 'lesson_detail.dart';
import 'question_bank_page.dart';

class SubjectDetailPage extends StatefulWidget {
  const SubjectDetailPage({
    super.key,
    required this.chapter,
    this.courseTitle,
  });

  final CourseChapter chapter;
  final String? courseTitle;

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  static const int _lessonChunkSize = 6;
  late final List<CourseLesson> _lessons;
  late int _visibleLessonCount;

  @override
  void initState() {
    super.initState();
    _lessons = widget.chapter.lessons.isNotEmpty
        ? widget.chapter.lessons
        : getLessonsForChapter(widget.chapter.title)
            .map((name) => CourseLesson(title: name))
            .toList();
    _visibleLessonCount =
        _lessons.isEmpty ? 0 : math.min(_lessonChunkSize, _lessons.length);
  }

  void _loadMoreLessons() {
    if (_visibleLessonCount >= _lessons.length) return;
    setState(() {
      _visibleLessonCount =
          math.min(_visibleLessonCount + _lessonChunkSize, _lessons.length);
    });
  }

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
              courseTitle: widget.courseTitle ?? widget.chapter.title,
              courseId: widget.chapter.courseId,
              chapter: widget.chapter,
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

    final lessonsToShow = _lessons.take(_visibleLessonCount).toList();
    final hasMoreLessons = _visibleLessonCount < _lessons.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: Text(
          widget.chapter.title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppAnimations.scaleIn(
              delay: 150,
              child: GridView.builder(
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
                  if (_lessons.isEmpty)
                    const Text(
                      'No lessons available yet.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lessonsToShow.length,
                      itemBuilder: (context, index) {
                        final lesson = lessonsToShow[index];
                        return Card(
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.15),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF582DB0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.play_circle_outline,
                                  color: Color(0xFF582DB0), size: 28),
                            ),
                            title: Text(
                              lesson.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                              ),
                            ),
                            trailing:
                                const Icon(Icons.chevron_right, color: Color(0xFF582DB0), size: 28),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LessonDetailPage(
                                    lessonName: lesson.title,
                                    lesson: lesson,
                                    courseTitle: widget.courseTitle ?? widget.chapter.title,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    if (hasMoreLessons)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _loadMoreLessons,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Load more lessons'),
                        ),
                      ),
                  ],
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuestionBankPage(
                      chapter: widget.chapter,
                      courseTitle: widget.courseTitle ?? widget.chapter.title,
                    ),
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
                'MCQ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        ),
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
