import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/course_catalog.dart';
import '../api/course_service.dart';
import '../utils/course_utils.dart';
import '../utils/animations.dart';
import '../utils/haptic_feedback.dart';
import '../widgets/rating_stars.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/responsive.dart';
import 'course_detail.dart';
import 'question_bank_page.dart';

class AllCoursesPage extends StatefulWidget {
  const AllCoursesPage({super.key});

  @override
  State<AllCoursesPage> createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await CourseService.fetchCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      setState(() {
        _errorMessage = 'Failed to load courses. Please try again.';
        _isLoading = false;
        _courses = [];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'ALL COURSES',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: _isLoading && _courses.isEmpty
          ? GridView.builder(
              padding: EdgeInsets.all(16.r),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.getGridColumns(context),
                mainAxisSpacing: Responsive.getCardSpacing(context),
                crossAxisSpacing: Responsive.getCardSpacing(context),
                childAspectRatio: kIsWeb ? 0.75 : 1.0,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => ShimmerLoading.courseCard(),
            )
          : _errorMessage != null && _courses.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.error_outline_rounded, size: 48.r, color: AppColors.error),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.title1.copyWith(color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body2,
                        ),
                        SizedBox(height: 24.h),
                        FilledButton.icon(
                          onPressed: _loadCourses,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  color: AppColors.primary,
                  child: _courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.school_outlined, size: 64.r, color: AppColors.primary),
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                'No courses available',
                                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16.r),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.getGridColumns(context),
                            mainAxisSpacing: Responsive.getCardSpacing(context),
                            crossAxisSpacing: Responsive.getCardSpacing(context),
                            childAspectRatio: kIsWeb ? 0.75 : 1.0,
                          ),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            return AnimatedListItem(
                              index: index,
                              child: _CourseCard(course: course),
                            );
                          },
                        ),
                ),
    );
  }
}

class _CourseCard extends StatefulWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        child: GestureDetector(
          onTap: () {
            HapticUtils.navigationTap();
            Navigator.of(context).push(
              BouncePageRoute(
                builder: (_) => CourseDetailPage(course: widget.course),
                direction: SlideDirection.right,
              ),
            );
          },
          child: Card(
            elevation: _isHovered ? 12 : 4,
            shadowColor: AppColors.primary.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
              side: BorderSide(
                color: _isHovered ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                width: 1.5.r,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    _isHovered ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Section
                  Expanded(
                    flex: 12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.course.thumbnailUrl != null && widget.course.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: CourseService.getFullImageUrl(widget.course.thumbnailUrl),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => ShimmerLoading.rectangular(
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                errorWidget: (context, url, error) => _PlaceholderIcon(title: widget.course.title),
                              )
                            : _PlaceholderIcon(title: widget.course.title),
                        
                        // Rating Badge (Top Right)
                        Positioned(
                          top: 8.r,
                          right: 8.r,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4.r,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 14.r),
                                SizedBox(width: 4.w),
                                Text(
                                  widget.course.rating.toStringAsFixed(1),
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info Section
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.title,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.sp,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Course',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_rounded, 
                                 size: 16.r, 
                                 color: AppColors.primary.withOpacity(_isHovered ? 1.0 : 0.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.05),
      child: Center(
        child: Icon(
          CourseUtils.getCourseIcon(title),
          color: AppColors.primary.withOpacity(0.3),
          size: 48.r,
        ),
      ),
    );
  }
}
