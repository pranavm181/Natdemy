import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import '../data/student.dart';
import '../utils/course_utils.dart';
import '../widgets/rating_stars.dart';
import '../widgets/main_drawer.dart';
import '../widgets/theme_loading_indicator.dart';
import '../api/course_service.dart';
import '../api/contact_service.dart';
import '../utils/animations.dart';
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
  bool _isLoadingChapters = false;
  Set<String> _loadedChapters = {}; // Track which courses have loaded chapters
  static const int _chapterChunkSize = 5;
  final ScrollController _coursesScrollController = ScrollController();
  final Map<String, int> _visibleChapterCounts = {};

  @override
  void initState() {
    super.initState();
    _coursesScrollController.addListener(_handleCoursesScroll);
    // Load from cache first for instant display, then refresh in background
    _loadCourses(forceRefresh: false);
  }

  @override
  void dispose() {
    _coursesScrollController.removeListener(_handleCoursesScroll);
    _coursesScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh in background if we haven't loaded yet or it's been a while
    // Don't block UI - use cache first, refresh in background
    final now = DateTime.now();
    final shouldRefreshInBackground = !_hasLoadedOnce || 
                        _lastLoadTime == null || 
                        now.difference(_lastLoadTime!).inSeconds > 30; // Only refresh after 30 seconds
    
    if (shouldRefreshInBackground) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Refresh in background without blocking UI
          _loadCourses(forceRefresh: true).catchError((e) {
            debugPrint('Background refresh error: $e');
          });
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
      // Only show loading if we don't have cached data
      if (forceRefresh || JoinedCourses.instance.all.isEmpty) {
        setState(() => _isLoading = true);
      }
      
      // Load from cache first if available, then refresh in background if needed
      if (!forceRefresh && JoinedCourses.instance.all.isNotEmpty) {
        // We have cached data, show it immediately
        final joined = JoinedCourses.instance.all;
        JoinedCourse? nextSelected;
        if (joined.isNotEmpty && _selected == null) {
          nextSelected = joined.first;
        } else if (joined.isNotEmpty) {
          // Try to keep current selection
          final currentSelectedId = _selected?.courseId;
          final currentSelectedStreamId = _selected?.streamId;
          if (currentSelectedId != null && currentSelectedStreamId != null) {
            nextSelected = joined.firstWhere(
              (c) => c.courseId == currentSelectedId && c.streamId == currentSelectedStreamId,
              orElse: () => joined.first,
            );
          } else {
            nextSelected = joined.first;
          }
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLoadedOnce = true;
            _lastLoadTime = DateTime.now();
          });
          if (nextSelected != null && _selected == null) {
            _setSelectedCourse(nextSelected!, resetVisibility: true);
          }
        }
        
        // Refresh in background without blocking
        JoinedCourses.instance.initialize(widget.student.email, forceRefresh: true)
          .then((_) {
            if (mounted) {
              final updated = JoinedCourses.instance.all;
              if (updated.isNotEmpty) {
                setState(() {
                  _lastLoadTime = DateTime.now();
                  // Update selected course if it still exists
                  if (_selected != null) {
                    final updatedSelected = updated.firstWhere(
                      (c) => c.courseId == _selected!.courseId && c.streamId == _selected!.streamId,
                      orElse: () => updated.first,
                    );
                    if (updatedSelected.courseId != _selected!.courseId || 
                        updatedSelected.streamId != _selected!.streamId) {
                      _setSelectedCourse(updatedSelected, resetVisibility: false);
                    }
                  }
                });
              }
            }
          })
          .catchError((e) {
            debugPrint('Background refresh error: $e');
          });
        
        return; // Exit early - we've shown cached data
      }
      
      // No cache or force refresh - load from API
      await JoinedCourses.instance.initialize(widget.student.email, forceRefresh: forceRefresh);
      
      if (mounted) {
        final joined = JoinedCourses.instance.all;
        JoinedCourse? nextSelected;
        if (joined.isNotEmpty) {
          final currentSelectedId = _selected?.courseId;
          final currentSelectedStreamId = _selected?.streamId;
          if (currentSelectedId != null && currentSelectedStreamId != null) {
            nextSelected = joined.firstWhere(
              (c) => c.courseId == currentSelectedId && c.streamId == currentSelectedStreamId,
              orElse: () => joined.first,
            );
          } else {
            nextSelected = joined.first;
          }
        }
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
          _lastLoadTime = DateTime.now();
          // Reset loaded chapters when courses are refreshed
          _loadedChapters.clear();
        });
        if (nextSelected != null) {
          _setSelectedCourse(nextSelected!, resetVisibility: true);
        }
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

  Future<void> _loadChaptersForSelectedCourse() async {
    final selectedCourse = _selected;
    if (selectedCourse == null || 
        selectedCourse.courseId == null || 
        selectedCourse.streamId == null ||
        !selectedCourse.isEnrolled) {
      return;
    }

    final courseKey = '${selectedCourse.courseId}_${selectedCourse.streamId}';
    if (_loadedChapters.contains(courseKey)) {
      return; // Already loaded
    }

    if (_isLoadingChapters) {
      return; // Already loading
    }

    setState(() {
      _isLoadingChapters = true;
    });

    try {
      await JoinedCourses.instance.loadChaptersForCourse(
        selectedCourse.courseId!,
        selectedCourse.streamId!,
      );

      if (mounted) {
        // Update selected course with loaded chapters
        final updated = JoinedCourses.instance.all.firstWhere(
          (c) => c.courseId == selectedCourse.courseId && c.streamId == selectedCourse.streamId,
          orElse: () => selectedCourse,
        );
        
        setState(() {
          _selected = updated;
          _loadedChapters.add(courseKey);
          _isLoadingChapters = false;
          _resetChapterVisibilityForCourse(updated);
        });
      }
    } catch (e) {
      debugPrint('Error loading chapters: $e');
      if (mounted) {
        setState(() {
          _isLoadingChapters = false;
        });
      }
    }
  }

  void _handleCoursesScroll() {
    if (!_coursesScrollController.hasClients) return;
    final position = _coursesScrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 150) {
      _increaseVisibleChaptersForSelected();
    }
  }

  void _increaseVisibleChaptersForSelected() {
    final selectedCourse = _selected;
    if (selectedCourse == null) return;
    final chapters = _resolveAssignedChapters(selectedCourse);
    if (chapters.isEmpty) return;
    final key = _courseKey(selectedCourse);
    final current = _visibleChapterCounts[key] ?? math.min(_chapterChunkSize, chapters.length);
    if (current >= chapters.length) return;
    setState(() {
      _visibleChapterCounts[key] = math.min(current + _chapterChunkSize, chapters.length);
    });
  }

  String _courseKey(JoinedCourse course) {
    final courseId = course.courseId?.toString() ?? course.title;
    final streamId = course.streamId?.toString() ?? 'stream';
    return '$courseId-$streamId';
  }

  void _resetChapterVisibilityForCourse(JoinedCourse course) {
    final key = _courseKey(course);
    final total = _resolveAssignedChapters(course).length;
    _visibleChapterCounts[key] = total == 0 ? 0 : math.min(_chapterChunkSize, total);
  }

  void _ensureChapterVisibilityForCourse(JoinedCourse course) {
    final key = _courseKey(course);
    if (!_visibleChapterCounts.containsKey(key)) {
      _resetChapterVisibilityForCourse(course);
      return;
    }
    final total = _resolveAssignedChapters(course).length;
    final current = _visibleChapterCounts[key] ?? 0;
    if (current == 0 && total > 0) {
      _visibleChapterCounts[key] = math.min(_chapterChunkSize, total);
    } else if (current > total) {
      _visibleChapterCounts[key] = total;
    }
  }

  void _setSelectedCourse(JoinedCourse course, {bool resetVisibility = false}) {
    setState(() {
      _selected = course;
      _isLoadingChapters = false;
      if (resetVisibility) {
        _resetChapterVisibilityForCourse(course);
      } else {
        _ensureChapterVisibilityForCourse(course);
      }
    });
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
        body: const Center(
          child: ThemePulsingDotsIndicator(
            size: 12.0,
            spacing: 16.0,
          ),
        ),
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
                controller: _coursesScrollController,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _emptyView(),
                  ),
                ],
              )
            : AppAnimations.fadeSlideIn(
              delay: 100,
              child: ListView(
                controller: _coursesScrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 100,
                ),
                children: [
                  if (_selected != null) ...[
                    AppAnimations.scaleIn(
                      delay: 150,
                      child: _Banner(
                        selected: _selected!,
                        onChangeCourse: () => _showCourseSelectionDialog(context, joined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppAnimations.fadeSlideIn(
                      delay: 200,
                      child: _subjectSection(context),
                    ),
                    const SizedBox(height: 24),
                    AppAnimations.fadeSlideIn(
                      delay: 250,
                      child: _contactSection(context),
                    ),
                  ],
                ],
              ),
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

    // Don't load chapters automatically - only load when user wants to view them
    final courseKey = '${selectedCourse.courseId}_${selectedCourse.streamId}';
    final chaptersLoaded = _loadedChapters.contains(courseKey);

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
    final totalChapters = chapters.length;
    final visibleCount = _visibleChapterCounts[courseKey] ??
        (totalChapters == 0 ? 0 : math.min(_chapterChunkSize, totalChapters));
    final visibleChapters = chapters.take(visibleCount).toList();
    final hasMoreChapters = visibleCount < totalChapters;

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
        // Show loading state
        if (_isLoadingChapters && !chaptersLoaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: ThemePulsingDotsIndicator(size: 10.0, spacing: 12.0),
            ),
          )
        // Show button to load chapters if not loaded yet
        else if (!chaptersLoaded && selectedCourse.courseId != null && selectedCourse.streamId != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton.icon(
                onPressed: _loadChaptersForSelectedCourse,
                icon: const Icon(Icons.book_outlined),
                label: const Text('Load Chapters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                  foregroundColor: const Color(0xFF582DB0),
                ),
              ),
            ),
          )
        // Show empty state if chapters loaded but empty
        else if (chapters.isEmpty && chaptersLoaded)
          const Text(
            'No chapters available for this stream yet.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        // Show chapters list if loaded
        else if (chaptersLoaded && visibleChapters.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleChapters.length,
            itemBuilder: (context, index) {
              final chapter = visibleChapters[index];
              final lessonCount = chapter.lessons.length;
              final videoCount = chapter.lessons.fold<int>(
                0,
                (sum, lesson) => sum + lesson.videos.length,
              );
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
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.book_outlined,
                    color: Color(0xFF582DB0),
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
                  onTap: () async {
                    // Ensure chapters are loaded before navigating
                    if (!chaptersLoaded && selectedCourse.courseId != null && selectedCourse.streamId != null) {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ThemePulsingDotsIndicator(size: 12.0, spacing: 16.0),
                                  SizedBox(height: 16),
                                  Text('Loading chapter...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      
                      await _loadChaptersForSelectedCourse();
                      
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        
                        // Get updated course with chapters
                        final updated = JoinedCourses.instance.all.firstWhere(
                          (c) => c.courseId == selectedCourse.courseId && c.streamId == selectedCourse.streamId,
                          orElse: () => selectedCourse,
                        );
                        
                        // Find the chapter in updated course
                        final updatedChapters = updated.chapters;
                        final updatedChapter = updatedChapters.firstWhere(
                          (c) => c.id == chapter.id || c.title == chapter.title,
                          orElse: () => chapter,
                        );
                        
                        if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SubjectDetailPage(
                                courseTitle: selectedCourse.title,
                                chapter: updatedChapter,
                              ),
                            ),
                          );
                        }
                      }
                    } else {
                      // Chapters already loaded, navigate directly
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubjectDetailPage(
                            courseTitle: selectedCourse.title,
                            chapter: chapter,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          if (hasMoreChapters)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _increaseVisibleChaptersForSelected,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more chapters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF582DB0),
                  side: const BorderSide(color: Color(0xFF582DB0), width: 1.5),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _contactSection(BuildContext context) {
    final selectedCourse = _selected;
    if (selectedCourse == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: ContactService.getContactInfo(),
      builder: (context, snapshot) {
        final contactInfo = snapshot.data ?? ContactInfo.getDefault();
        final whatsappNum = _resolveCourseWhatsAppNumber(selectedCourse, contactInfo);
        final displayNumber = _formatWhatsAppDisplay(whatsappNum);
        final supportLabel = _resolveCourseSupportLabel(selectedCourse);
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    if (!context.mounted) return;
                    await _showContactDialog(
                      context,
                      whatsappNum: whatsappNum,
                      displayNumber: displayNumber,
                      supportLabel: supportLabel,
                    );
                  },
            icon: const Icon(Icons.headset_mic, size: 20),
            label: Text(
              isLoading ? 'Contacting...' : supportLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Color(0xFF582DB0), width: 2),
              foregroundColor: const Color(0xFF582DB0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContactDialog(
    BuildContext context, {
    required String whatsappNum,
    required String displayNumber,
    required String supportLabel,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF582DB0),
                  width: 2,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F0FF),
                    Color(0xFFFFFFFF),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33582DB0),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFA5ED),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4D23AA),
                                Color(0xFF6435C8),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40582DB0),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supportLabel,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF582DB0),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Reach us on WhatsApp at $displayNumber',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF4C3B82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF582DB0)),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          final message = Uri.encodeComponent('i am contacting from the natdemy app for some support');
                          final uri = Uri.parse('https://wa.me/$whatsappNum?text=$message');
                          Navigator.of(sheetContext).pop();
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE0D2FF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF582DB0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supportLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF452D8A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Available Mon - Sat · 9:00 AM to 6:00 PM',
                                  style: TextStyle(
                                    color: Color(0xFF5B4A9B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
                            _setSelectedCourse(course, resetVisibility: true);
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: _StreamChip(
                              title: displayStreamTitle,
                              isSelectedChip: isSelected,
                              onTap: () {
                                _setSelectedCourse(course, resetVisibility: true);
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

  String _resolveCourseWhatsAppNumber(JoinedCourse course, ContactInfo contactInfo) {
    final title = course.title.toLowerCase();
    if (title.contains('nios')) {
      return '919207666621';
    }
    if (title.contains('bosse')) {
      return '919207666623';
    }
    if (title.contains('gmvss') || title.contains('gmv')) {
      return '919207666628';
    }
    final fallback = contactInfo.whatsappNumber ??
        contactInfo.phone ??
        '+91 92076 666621';
    return _sanitizeWhatsappDigits(fallback);
  }

  String _sanitizeWhatsappDigits(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '919207666621';
    if (digits.startsWith('91')) return digits;
    return '91$digits';
  }

  String _formatWhatsAppDisplay(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('91') && cleaned.length > 2) {
      final local = cleaned.substring(2);
      if (local.length > 5) {
        final first = local.substring(0, 5);
        final second = local.substring(5);
        return '+91 $first $second';
      }
      return '+91 $local';
    }
    if (cleaned.isNotEmpty) {
      return '+$cleaned';
    }
    return '+91 92076 66621';
  }

  String _resolveCourseSupportLabel(JoinedCourse course) {
    final title = course.title.toLowerCase();
    if (title.contains('nios')) {
      return 'NIOS Support';
    }
    if (title.contains('bosse')) {
      return 'BOSSE Support';
    }
    if (title.contains('gmvss') || title.contains('gmv')) {
      return 'GMVSS Support';
    }
    return 'Course Support';
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF582DB0)),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              CourseUtils.getCourseIcon(selected.title),
                              color: const Color(0xFF000000),
                              size: 48,
                            );
                          },
                          cacheWidth: 128, // Cache smaller image for better performance
                          cacheHeight: 128,
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
