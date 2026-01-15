import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/joined_courses.dart';
import '../data/lessons_config.dart';
import '../utils/animations.dart';
import 'materials_page.dart';
import 'live_upcoming.dart';
import 'lesson_detail.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/haptic_feedback.dart';
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
  static const int _lessonChunkSize = 8;
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
    HapticUtils.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final actionColors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo/Violet - Live
      [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)], // Blue/Teal - Material
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber/Red - Assignments
      [const Color(0xFF10B981), const Color(0xFF3B82F6)], // Emerald/Blue - Mock Tests
    ];

    final actions = [
      _ActionItem('Live', Icons.live_tv_rounded, actionColors[0], () {
        HapticUtils.mediumImpact();
        Navigator.of(context).push(BouncePageRoute(builder: (_) => const LiveUpcomingPage()));
      }),
      _ActionItem('Material', Icons.auto_stories_rounded, actionColors[1], () {
        HapticUtils.mediumImpact();
        Navigator.of(context).push(
          BouncePageRoute(
            builder: (_) => MaterialsPage(
              courseTitle: widget.courseTitle ?? widget.chapter.title,
              courseId: widget.chapter.courseId,
              chapter: widget.chapter,
            ),
          ),
        );
      }),
      _ActionItem('Assignments', Icons.edit_note_rounded, actionColors[2], () {
        HapticUtils.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignments coming soon'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }),
      _ActionItem('Mock Tests', Icons.quiz_rounded, actionColors[3], () {
        HapticUtils.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mock tests coming soon'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }),
    ];

    final lessonsToShow = _lessons.take(_visibleLessonCount).toList();
    final hasMoreLessons = _visibleLessonCount < _lessons.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced SliverAppBar
          SliverAppBar(
            expandedHeight: 120.h,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, 
                        color: AppColors.textPrimary, size: 20.r),
                  onPressed: () {
                    HapticUtils.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 60.w, bottom: 16.h, right: 16.w),
              title: Text(
                widget.chapter.title,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Grid
          SliverPadding(
            padding: EdgeInsets.all(16.r),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWeb ? 4 : 2,
                mainAxisSpacing: 16.r,
                crossAxisSpacing: 16.r,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppAnimations.fadeScaleIn(
                  delay: 100 + (index * 50),
                  child: _SubjectActionCard(action: actions[index]),
                ),
                childCount: actions.length,
              ),
            ),
          ),

          // MCQs Section - Full Width Horizontal
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: AppAnimations.fadeSlideIn(
                delay: 400,
                child: GestureDetector(
                  onTap: () {
                    HapticUtils.mediumImpact();
                    Navigator.of(context).push(
                      BouncePageRoute(
                        builder: (_) => QuestionBankPage(
                          chapter: widget.chapter,
                          courseTitle: widget.courseTitle ?? widget.chapter.title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.library_books_rounded, color: Colors.white, size: 28.r),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MCQs / Question Bank',
                                style: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18.sp,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Practice with chapter-wise questions',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20.r),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Lessons Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'COURSE CURRICULUM',
                    style: AppTextStyles.title2.copyWith(
                      letterSpacing: 1.2,
                      fontSize: 16.sp,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_lessons.length} Lessons',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lessons List
          if (_lessons.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_outlined, 
                         size: 64.r, color: AppColors.textSecondary.withOpacity(0.3)),
                    SizedBox(height: 16.h),
                    Text(
                      'No lessons available yet',
                      style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < lessonsToShow.length) {
                      final lesson = lessonsToShow[index];
                      return AppAnimations.slideInBottom(
                        delay: 200 + (index * 30),
                        child: _LessonTile(
                          lesson: lesson,
                          index: index + 1,
                          courseTitle: widget.courseTitle ?? widget.chapter.title,
                        ),
                      );
                    } else if (hasMoreLessons) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _loadMoreLessons,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              'Show More Lessons',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox(height: 32.h); // Bottom padding
                  },
                  childCount: lessonsToShow.length + (hasMoreLessons ? 1 : 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectActionCard extends StatefulWidget {
  const _SubjectActionCard({required this.action});
  final _ActionItem action;

  @override
  State<_SubjectActionCard> createState() => _SubjectActionCardState();
}

class _SubjectActionCardState extends State<_SubjectActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: GestureDetector(
          onTap: widget.action.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.action.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.action.colors.first.withOpacity(0.3),
                  blurRadius: 12.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.action.icon, color: Colors.white, size: 24.r),
                ),
                Text(
                  widget.action.label,
                  style: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.courseTitle,
  });

  final CourseLesson lesson;
  final int index;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticUtils.mediumImpact();
          Navigator.of(context).push(
            BouncePageRoute(
              builder: (_) => LessonDetailPage(
                lessonName: lesson.title,
                lesson: lesson,
                courseTitle: courseTitle,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // Index / Status indicator
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: AppTextStyles.title3.copyWith(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, 
                             size: 14.r, color: AppColors.textSecondary),
                        SizedBox(width: 4.w),
                        Text(
                          'Video Lesson',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play button
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.label, this.icon, this.colors, this.onTap);
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
}

