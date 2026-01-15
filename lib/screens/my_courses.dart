import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import '../data/student.dart';
import '../utils/course_utils.dart';
import '../widgets/rating_stars.dart';
import '../widgets/main_drawer.dart';
import '../widgets/theme_loading_indicator.dart';
import '../widgets/shimmer_loading.dart';
import '../api/course_service.dart';
import '../api/contact_service.dart';
import '../utils/animations.dart';
import '../utils/haptic_feedback.dart';
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

  late Future<ContactInfo> _contactInfoFuture;

  @override
  void initState() {
    super.initState();
    // Removed scroll listener - all chapters are shown by default, no pagination needed
    // Check if app was restarted - if so, clear cache and load fresh
    _contactInfoFuture = ContactService.getContactInfo();
    _checkAppRestartAndLoad();
  }

  Future<void> _checkAppRestartAndLoad() async {
    // Normal navigation - load from cache first
    _loadCourses(forceRefresh: false);
  }

  @override
  void dispose() {
    _coursesScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When navigating from other pages, use cache - don't refresh
    // Only refresh if we haven't loaded yet (handled in initState)
    // This ensures cache is used when navigating between pages
    if (!_hasLoadedOnce && JoinedCourses.instance.all.isNotEmpty) {
      // We have cache but haven't loaded yet - load from cache
      _loadCourses(forceRefresh: false);
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
            // Clear loaded chapters - chapters will only load when user clicks "Load Chapters" button
            _loadedChapters.clear();
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
          // Clear loaded chapters - chapters will only load when user clicks "Load Chapters" button
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
          // Ensure all chapters are visible after loading
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
    // Always show all chapters - no pagination needed
    final current = _visibleChapterCounts[key] ?? chapters.length;
    if (current >= chapters.length) return;
    setState(() {
      _visibleChapterCounts[key] = chapters.length; // Show all chapters
    });
  }

  String _courseKey(JoinedCourse course) {
    final courseId = course.courseId?.toString() ?? course.title;
    final streamId = course.streamId?.toString() ?? 'stream';
    return '$courseId-$streamId';
  }

  void _resetChapterVisibilityForCourse(JoinedCourse course) {
    final key = _courseKey(course);
    final chapters = _resolveAssignedChapters(course);
    final total = chapters.length;
    _visibleChapterCounts[key] = total; // Show all chapters by default
  }

  void _ensureChapterVisibilityForCourse(JoinedCourse course) {
    final key = _courseKey(course);
    final chapters = _resolveAssignedChapters(course);
    final total = chapters.length;
    if (!_visibleChapterCounts.containsKey(key)) {
      _visibleChapterCounts[key] = total; // Show all chapters by default
      return;
    }
    final current = _visibleChapterCounts[key] ?? 0;
    // Always ensure all chapters are visible
    if (current < total) {
      _visibleChapterCounts[key] = total; // Show all chapters
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

    // Auto-fetch chapters in background if they are missing
    if (course.chapters.isEmpty && course.isEnrolled) {
      _loadChaptersForSelectedCourse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final joined = JoinedCourses.instance.all;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'MY COURSES',
            style: AppTextStyles.headline1.copyWith(
              color: AppColors.primary,
              fontSize: 20.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        body: Center(
          child: ShimmerLoading(
            width: 0.9.sw,
            height: 200.h,
            borderRadius: 20.r,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: MainDrawer(
        student: widget.student,
        onNavigateToHome: () {
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeShell(student: widget.student),
            ),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.textPrimary, size: 24.r),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'MY COURSES',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary, size: 24.r),
            onPressed: () async {
              await JoinedCourses.instance.clearCache();
              _loadCourses(forceRefresh: true);
            },
            tooltip: 'Refresh courses',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Clear cache and load fresh when pull-to-refresh
          await JoinedCourses.instance.clearCache();
          await _loadCourses(forceRefresh: true);
        },
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
                padding: EdgeInsets.fromLTRB(
                  16.w, 
                  16.h, 
                  16.w, 
                  MediaQuery.of(context).padding.bottom + 100.h
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

  Widget _emptyView() => Center(
    child: Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 64.r, color: AppColors.divider),
          SizedBox(height: 16.h),
          Text(
            'No course joined.',
            style: AppTextStyles.body1.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _subjectSection(BuildContext context) {
    final selectedCourse = _selected;
    if (selectedCourse == null) {
      return const SizedBox.shrink();
    }

    // Chapters are considered loaded if they are in the tracker OR already present in the course object
    final courseKey = '${selectedCourse.courseId}_${selectedCourse.streamId}';
    final chaptersLoaded = _loadedChapters.contains(courseKey) || selectedCourse.chapters.isNotEmpty;

    // Show locked message if course is not enrolled
    if (!selectedCourse.isEnrolled) {
      return Card(
        elevation: 8,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.warning, width: 2.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: 64.r,
                color: AppColors.warning,
              ),
              SizedBox(height: 16.h),
              Text(
                'Course Locked',
                style: AppTextStyles.headline1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your enrollment is pending approval.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                'You will be able to access this course once your enrollment is confirmed.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 14.sp,
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
    // Always show all chapters - no limit
    final visibleChapters = chapters; // Show all chapters, no pagination
    final hasMoreChapters = false; // Always show all chapters, no pagination needed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          streamTitle.toUpperCase(),
          style: AppTextStyles.headline2.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22.sp,
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
              padding: EdgeInsets.all(24.r),
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticUtils.buttonPress();
                  _loadChaptersForSelectedCourse();
                },
                icon: Icon(Icons.book_outlined, size: 20.r),
                label: Text('Load Chapters', style: AppTextStyles.button.copyWith(fontSize: 16.sp, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  side: BorderSide(color: AppColors.primary, width: 2.r),
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          )
        // Show empty state if chapters loaded but empty
        else if (chapters.isEmpty && chaptersLoaded)
          Text(
            'No chapters available for this stream yet.',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
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
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: AppColors.primary, width: 2.r),
                ),
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  leading: Icon(
                    Icons.book_outlined,
                    color: AppColors.primary,
                    size: 28.r,
                  ),
                  title: Text(
                    chapter.title,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                  subtitle: subtitleText != null
                      ? Text(
                          subtitleText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 28.r,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  onTap: () async {
                    HapticUtils.subtleTap();
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
                          HapticUtils.navigationTap();
                          Navigator.of(context).push(
                            BouncePageRoute(
                              builder: (_) => SubjectDetailPage(
                                courseTitle: selectedCourse.title,
                                chapter: updatedChapter,
                              ),
                              direction: SlideDirection.right,
                            ),
                          );
                        }
                      }
                    } else {
                      // Chapters already loaded, navigate directly
                      HapticUtils.navigationTap();
                      Navigator.of(context).push(
                        BouncePageRoute(
                          builder: (_) => SubjectDetailPage(
                            courseTitle: selectedCourse.title,
                            chapter: chapter,
                          ),
                          direction: SlideDirection.right,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          // Removed "Load more chapters" button - all chapters are shown by default
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
      future: _contactInfoFuture,
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
            icon: Icon(Icons.headset_mic, size: 20.r),
            label: Text(
              isLoading ? 'Contacting...' : supportLabel,
              style: AppTextStyles.button.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 18.h),
              side: BorderSide(color: AppColors.primary, width: 2.r),
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
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
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.r,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.background,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 24.r,
                    offset: Offset(0, 12.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Container(
                          width: 52.r,
                          height: 52.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20.r,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 26.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supportLabel,
                                style: AppTextStyles.headline2.copyWith(
                                  fontSize: 20.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Reach us on WhatsApp at $displayNumber',
                                style: AppTextStyles.body2.copyWith(
                                  fontSize: 14.sp,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.primary, size: 24.r),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.whatsapp,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                        ),
                        icon: FaIcon(FontAwesomeIcons.whatsapp, size: 20.r),
                        label: Text(
                          'WhatsApp',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
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
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supportLabel,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Available Mon - Sat · 9:00 AM to 6:00 PM',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.sp,
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
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.primary,
              width: 2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 24.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Course',
                        style: AppTextStyles.headline1.copyWith(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white, size: 24.r),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 400.h),
                  padding: EdgeInsets.all(16.r),
                  child: Builder(
                    builder: (context) {
                      final filteredCourses = courses.where((course) {
                        final streamName = course.streamName?.trim();
                        return streamName != null && streamName.isNotEmpty;
                      }).toList();

                      if (filteredCourses.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Text(
                              'No courses with assigned streams found.',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14.sp,
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
                        shadowColor: AppColors.shadow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 2.r : 1.r,
                          ),
                        ),
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () {
                            _setSelectedCourse(course, resetVisibility: true);
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
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
    // Show chapters if they are already present in the course object (e.g. from cache)
    if (course.chapters.isNotEmpty) {
      return course.chapters;
    }
    
    // Fallback: only track explicitly loaded if we actually made a network call
    final courseKey = '${course.courseId}_${course.streamId}';
    if (_loadedChapters.contains(courseKey) && course.chapters.isNotEmpty) {
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.divider,
          width: 2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selected.thumbnailUrl != null && selected.thumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: CourseService.getFullImageUrl(selected.thumbnailUrl!),
                          width: 64.w,
                          height: 64.h,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 64.w,
                            height: 64.h,
                            color: AppColors.divider.withOpacity(0.1),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            CourseUtils.getCourseIcon(selected.title),
                            color: AppColors.textPrimary,
                            size: 48.r,
                          ),
                          memCacheWidth: 128,
                          memCacheHeight: 128,
                        ),
                      )
                    : Icon(
                        CourseUtils.getCourseIcon(selected.title),
                        color: AppColors.textPrimary,
                        size: 48.r,
                      ),
                SizedBox(height: 16.h),
                Text(
                  selected.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12.h),
                RatingStars(rating: selected.rating),
                SizedBox(height: 12.h),
                if (selected.streamName != null && selected.streamName!.trim().isNotEmpty)
                  _SelectedStreamBadge(streamName: selected.streamName!.trim()),
              ],
            ),
          ),
          Positioned(
            top: 12.h,
            right: 12.w,
            child: IconButton(
              onPressed: onChangeCourse,
              icon: Icon(
                Icons.swap_horiz,
                color: AppColors.primary,
                size: 24.r,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide(color: AppColors.primary, width: 1.5.r),
                ),
                padding: EdgeInsets.all(8.r),
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isSelectedChip
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelectedChip ? null : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: isSelectedChip ? AppColors.primary : AppColors.primary.withOpacity(0.3),
            width: isSelectedChip ? 1.6.r : 1.2.r,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isSelectedChip ? 0.15 : 0.05),
              blurRadius: isSelectedChip ? 10.r : 6.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelectedChip)
              Icon(
                Icons.check_circle,
                size: 18.r,
                color: Colors.white,
              ),
            if (isSelectedChip) SizedBox(width: 8.w),
            Text(
              title.trim(),
              style: AppTextStyles.body1.copyWith(
                color: isSelectedChip ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.primary, width: 1.4.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_library_outlined,
            color: AppColors.primary,
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Text(
            streamName.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
