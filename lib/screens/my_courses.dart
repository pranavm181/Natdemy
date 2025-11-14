import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import '../data/student.dart';
import '../utils/course_utils.dart';
import '../widgets/rating_stars.dart';
import '../widgets/main_drawer.dart';
import '../api/course_service.dart';
import '../api/contact_service.dart';
import 'subject_detail.dart';
import 'home.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key, required this.student});
  final Student student;

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  JoinedCourse? _selected;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _loadCourses(forceRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh courses when screen becomes visible, but avoid reloading immediately after initState
    // Only reload if it's been more than 2 seconds since last load (to check for verification updates)
    final now = DateTime.now();
    final shouldReload = !_hasLoadedOnce || 
                        _lastLoadTime == null || 
                        now.difference(_lastLoadTime!).inSeconds > 2;
    
    if (shouldReload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadCourses(forceRefresh: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(MyCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if student email changed
    if (oldWidget.student.email != widget.student.email) {
      _loadCourses(forceRefresh: true);
    }
  }

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    try {
      setState(() => _isLoading = true);
      // Small delay to ensure platform channels are ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Always check verified status from API (forceRefresh ensures full reload)
      await JoinedCourses.instance.initialize(widget.student.email, forceRefresh: forceRefresh);
      
      if (mounted) {
        final joined = JoinedCourses.instance.all;
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
          _lastLoadTime = DateTime.now();
          if (joined.isNotEmpty) {
            // Update selected course to reflect latest status
            final currentSelectedId = _selected?.courseId;
            final currentSelectedStreamId = _selected?.streamId;
            if (currentSelectedId != null && currentSelectedStreamId != null) {
              final updatedCourse = joined.firstWhere(
                (c) => c.courseId == currentSelectedId && c.streamId == currentSelectedStreamId,
                orElse: () => joined.first,
              );
              _selected = updatedCourse;
            } else {
              _selected = joined.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
          _lastLoadTime = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joined = JoinedCourses.instance.all;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'MY COURSES',
            style: TextStyle(
              color: Color(0xFF582DB0),
              fontWeight: FontWeight.w900,
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: MainDrawer(
        student: widget.student,
        onNavigateToHome: () {
          // Navigate to HomeShell if we can find it in the widget tree
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeShell(student: widget.student),
            ),
          );
        },
        onNavigateToMyCourses: () {
          // Already on My Courses page
        },
        onNavigateToProfile: () {
          // Navigate to HomeShell and switch to Profile tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeShell(student: widget.student),
            ),
          );
          // Need to switch to profile tab after navigation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              // This will be handled by HomeShell
            }
          });
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'MY COURSES',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF582DB0)),
            onPressed: () => _loadCourses(forceRefresh: true),
            tooltip: 'Refresh courses',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCourses(forceRefresh: true),
        child: joined.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _emptyView(),
                  ),
                ],
              )
            : ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          children: [
          if (_selected != null) ...[
            _Banner(
              selected: _selected!,
              onChangeCourse: () => _showCourseSelectionDialog(context, joined),
            ),
            const SizedBox(height: 16),
            _subjectSection(context),
            const SizedBox(height: 24),
            _contactSection(context),
          ],
        ],
      ),
      ),
    );
  }

  Widget _emptyView() => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'No course joined.',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _subjectSection(BuildContext context) {
    final selectedCourse = _selected;
    if (selectedCourse == null) {
      return const SizedBox.shrink();
    }

    // Show locked message if course is not enrolled
    if (!selectedCourse.isEnrolled) {
      return Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Course Locked',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF000000),
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your enrollment is pending approval.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'You will be able to access this course once your enrollment is confirmed.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final streamTitle = _resolveStreamTitle(selectedCourse);
    final chapters = _resolveAssignedChapters(selectedCourse);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          streamTitle.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF000000),
                fontSize: 22,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 16),
        if (chapters.isEmpty)
          const Text(
            'No chapters available for this stream yet.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          ..._buildChapterTiles(context, chapters),
      ],
    );
  }

  List<Widget> _buildChapterTiles(BuildContext context, List<CourseChapter> chapters) {
    return chapters.map((chapter) {
      final lessonCount = chapter.lessons.length;
      // Count total videos across all lessons in this chapter
      final videoCount = chapter.lessons.fold<int>(
        0,
        (sum, lesson) => sum + lesson.videos.length,
      );
      
      // Build subtitle text showing lessons and videos
      String? subtitleText;
      if (lessonCount > 0 || videoCount > 0) {
        final parts = <String>[];
        if (lessonCount > 0) {
          parts.add('$lessonCount lesson${lessonCount == 1 ? '' : 's'}');
        }
        if (videoCount > 0) {
          parts.add('$videoCount video${videoCount == 1 ? '' : 's'}');
        }
        subtitleText = parts.join(' • ');
      }
      
      return Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF582DB0), width: 2),
        ),
        child: ListTile(
          leading: Icon(
            Icons.book_outlined,
            color: const Color(0xFF582DB0),
            size: 28,
          ),
          title: Text(
            chapter.title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          subtitle: subtitleText != null
              ? Text(
                  subtitleText,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF582DB0),
            size: 28,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubjectDetailPage(
                  courseTitle: _selected!.title,
                  chapter: chapter,
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _contactSection(BuildContext context) => Card(
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF582DB0), width: 2),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTACT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final whatsappNum = '+91 9207666621'.replaceAll(RegExp(r'[^0-9]'), ''); // +91 92076 66621
                  // Ensure it starts with 91
                  final cleanedNum = whatsappNum.startsWith('91') ? whatsappNum : '91$whatsappNum';
                  final message = Uri.encodeComponent('i am contacting from the natdemy app for some support');
                  final uri = Uri.parse('https://wa.me/$cleanedNum?text=$message');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFA1C95C), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20, color: Colors.white),
                label: const Text(
                  'WhatsApp Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showCourseSelectionDialog(BuildContext context, List<JoinedCourse> courses) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF582DB0),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Course',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final filteredCourses = courses.where((course) {
                        final streamName = course.streamName?.trim();
                        return streamName != null && streamName.isNotEmpty;
                      }).toList();

                      if (filteredCourses.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No courses with assigned streams found.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = filteredCourses[index];
                      final isSelected = _selected?.title == course.title;
                      final displayStreamTitle = _resolveStreamTitle(course);

                      return Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF582DB0) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selected = course;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: _StreamChip(
                              title: displayStreamTitle,
                              isSelectedChip: isSelected,
                              onTap: () {
                                setState(() {
                                  _selected = course;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveStreamTitle(JoinedCourse course) {
    final streamName = course.streamName?.trim();
    if (streamName != null && streamName.isNotEmpty) {
      return streamName;
    }
    return 'No stream assigned';
  }

  List<CourseChapter> _resolveAssignedChapters(JoinedCourse course) {
    if (course.chapters.isNotEmpty) {
      return course.chapters;
    }
    return const [];
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.selected, required this.onChangeCourse});
  final JoinedCourse selected;
  final VoidCallback onChangeCourse;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selected.thumbnailUrl != null && selected.thumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          CourseService.getFullImageUrl(selected.thumbnailUrl),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              CourseUtils.getCourseIcon(selected.title),
                              color: const Color(0xFF000000),
                              size: 48,
                            );
                          },
                        ),
                      )
                    : Icon(
                        CourseUtils.getCourseIcon(selected.title),
                        color: const Color(0xFF000000),
                        size: 48,
                      ),
                const SizedBox(height: 16),
                Text(
                  selected.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                RatingStars(rating: selected.rating),
                const SizedBox(height: 12),
                if (selected.streamName != null && selected.streamName!.trim().isNotEmpty)
                  _SelectedStreamBadge(streamName: selected.streamName!.trim()),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: onChangeCourse,
              icon: const Icon(
                Icons.swap_horiz,
                color: Color(0xFF582DB0),
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF582DB0), width: 1.5),
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamChip extends StatelessWidget {
  const _StreamChip({
    required this.title,
    required this.onTap,
    this.isSelectedChip = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isSelectedChip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelectedChip
              ? const LinearGradient(
                  colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelectedChip ? null : const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelectedChip ? const Color(0xFF582DB0) : const Color(0xFF582DB0).withOpacity(0.3),
            width: isSelectedChip ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelectedChip ? 0.15 : 0.05),
              blurRadius: isSelectedChip ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelectedChip)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.white,
              ),
            if (isSelectedChip) const SizedBox(width: 8),
            Text(
              title.trim(),
              style: TextStyle(
                color: isSelectedChip ? Colors.white : const Color(0xFF582DB0),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStreamBadge extends StatelessWidget {
  const _SelectedStreamBadge({required this.streamName});

  final String streamName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF582DB0), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_library_outlined,
            color: Color(0xFF582DB0),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            streamName.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF582DB0),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
