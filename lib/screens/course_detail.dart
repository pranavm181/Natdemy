import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/course_catalog.dart';
import '../utils/course_utils.dart';
import '../api/contact_service.dart';
import '../api/course_service.dart';
import '../widgets/rating_stars.dart';
import '../data/course_stream.dart';
import '../utils/animations.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/haptic_feedback.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<CourseStream> _streams = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // If streams are already cached, use them but still allow refresh if needed
    final cached = CourseService.cachedStreams.where((s) => 
      s.resolvedCourseId == widget.course.id || 
      s.courseId == widget.course.id || 
      (s.course?.id == widget.course.id)
    ).toList();

    if (cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _streams = cached;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // fetchCourses also populates cachedStreams
      await CourseService.fetchCourses();
      
      final updatedStreams = CourseService.cachedStreams.where((s) => 
        s.resolvedCourseId == widget.course.id || 
        s.courseId == widget.course.id || 
        (s.course?.id == widget.course.id)
      ).toList();

      if (mounted) {
        setState(() {
          _streams = updatedStreams;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading course details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load additional course details.';
          _isLoading = false;
        });
      }
    }
  }

  // Get icon for stream based on stream name or index
  IconData _getStreamIcon(String streamName, int index) {
    final nameLower = streamName.toLowerCase();
    
    // Check stream name for keywords
    if (nameLower.contains('science') || nameLower.contains('physics') || nameLower.contains('chemistry') || nameLower.contains('biology')) {
      return Icons.science;
    } else if (nameLower.contains('math') || nameLower.contains('mathematics')) {
      return Icons.calculate;
    } else if (nameLower.contains('english') || nameLower.contains('language')) {
      return Icons.menu_book;
    } else if (nameLower.contains('computer') || nameLower.contains('programming') || nameLower.contains('coding')) {
      return Icons.computer;
    } else if (nameLower.contains('commerce') || nameLower.contains('business') || nameLower.contains('accounting')) {
      return Icons.account_balance;
    } else if (nameLower.contains('arts') || nameLower.contains('history') || nameLower.contains('geography')) {
      return Icons.palette;
    } else if (nameLower.contains('medical') || nameLower.contains('health')) {
      return Icons.medical_services;
    } else if (nameLower.contains('engineering') || nameLower.contains('tech')) {
      return Icons.engineering;
    } else if (nameLower.contains('law') || nameLower.contains('legal')) {
      return Icons.gavel;
    } else if (nameLower.contains('management') || nameLower.contains('mba')) {
      return Icons.business_center;
    }
    
    // Default icons based on index if no keyword matches
    final defaultIcons = [
      Icons.stream,
      Icons.school,
      Icons.library_books,
      Icons.auto_stories,
      Icons.workspace_premium,
      Icons.rocket_launch,
      Icons.lightbulb,
      Icons.trending_up,
    ];
    
    return defaultIcons[index % defaultIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

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
          'COURSE DETAILS',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: Column(
          children: [
            AppAnimations.scaleIn(
              delay: 150,
            child: Container(
                margin: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.primary,
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
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: CachedNetworkImage(
                                  imageUrl: CourseService.getFullImageUrl(course.thumbnailUrl),
                                  width: 64.w,
                                  height: 64.h,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) {
                                    return Icon(
                                      CourseUtils.getCourseIcon(course.title),
                                      color: AppColors.textPrimary,
                                      size: 48.r,
                                    );
                                  },
                                  memCacheWidth: 128,
                                  memCacheHeight: 128,
                                ),
                              )
                            : Icon(
                                CourseUtils.getCourseIcon(course.title),
                                color: AppColors.textPrimary,
                                size: 48.r,
                              ),
                        SizedBox(height: 16.h),
                        Text(
                          course.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline1.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 24.sp,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 12.h),
                        RatingStars(
                          rating: course.rating,
                          textStyle: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ABOUT THIS COURSE',
                        style: AppTextStyles.headline2.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 24.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 3.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    course.description,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.8,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  if (_isLoading) ...[
                    Text(
                      'COURSE STREAMS',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 24.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 150.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, __) => SizedBox(width: 16.w),
                        itemBuilder: (context, index) => ShimmerLoading.rectangular(
                          width: 220.w,
                          height: 150.h,
                          borderRadius: 20.r,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ] else if (_errorMessage != null && _streams.isEmpty) ...[
                    // Just show error if we can't load streams
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.error),
                      ),
                    ),
                  ] else if (_streams.isNotEmpty) ...[
                    Text(
                      'COURSE STREAMS',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 24.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 150.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _streams.length,
                        separatorBuilder: (_, __) => SizedBox(width: 16.w),
                        itemBuilder: (context, index) {
                          final stream = _streams[index];
                          final streamCourse = stream.course ?? course;
                          final streamIcon = _getStreamIcon(stream.name, index);

                          return AnimatedListItem(
                            index: index,
                            child: Container(
                            width: 220.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: AppColors.primary, width: 2.r),
                              color: AppColors.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 12.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Icon(
                                          streamIcon,
                                          color: AppColors.primary,
                                          size: 24.r,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          streamCourse?.title ?? course.title,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                        Text(
                                          stream.name,
                                          style: AppTextStyles.body1.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18.sp,
                                          ),
                                    maxLines: 2,
                                               overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                  SizedBox(height: 16.h),
                  Card(
                    elevation: 8,
                    shadowColor: AppColors.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(color: AppColors.primary, width: 2.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.people,
                            course.studentCount != null
                                ? course.studentCount! >= 1000
                                    ? '${(course.studentCount! / 1000).toStringAsFixed(1)}K+'
                                    : '${course.studentCount}+'
                                : '0',
                            'Students',
                          ),
                          _buildStatItem(
                            Icons.access_time,
                            course.durationHours != null
                                ? '${(course.durationHours! / 160).round()} months'
                                : course.duration != null
                                    ? '${(course.duration! / 160).round()} months'
                                    : '0 months',
                            'Duration',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10.r,
                  offset: Offset(0, -2.h),
                ),
              ],
            ),
            child: SafeArea(
              child: FutureBuilder(
                future: ContactService.getContactInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ShimmerLoading.rectangular(
                      height: 56.h,
                      width: double.infinity,
                      borderRadius: 12.r,
                    );
                  }
                  final contactInfo = snapshot.data ?? ContactInfo.getDefault();
                  final whatsappNum = _resolveCourseWhatsAppNumber(course, contactInfo);
                  final displayNumber = _formatWhatsAppDisplay(whatsappNum);
                  final supportLabel = _resolveCourseSupportLabel(course);

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!context.mounted) return;
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
                                                    'Need help with this course?',
                                                    style: AppTextStyles.headline2.copyWith(
                                                      fontSize: 20.sp,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6.h),
                                                  Text(
                                                    'Our team is ready on WhatsApp or call to answer any questions.',
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
                                        SizedBox(height: 24.h),
                                        Container(
                                          padding: EdgeInsets.all(16.r),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(18.r),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.2),
                                              width: 1.2.r,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.school_rounded,
                                                color: AppColors.primary,
                                                size: 24.r,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  'Course: ${course.title}',
                                                  style: AppTextStyles.body1.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 28.h),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(10.r),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F9ED),
                                                borderRadius: BorderRadius.circular(14.r),
                                                border: Border.all(
                                                  color: const Color(0xFFBFEFCF),
                                                  width: 1.2.r,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.phone_android,
                                                color: AppColors.whatsapp,
                                                size: 24.r,
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
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    displayNumber,
                                                    style: AppTextStyles.headline1.copyWith(
                                                      color: AppColors.textPrimary,
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
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
                                              'WhatsApp ($displayNumber)',
                                              style: AppTextStyles.button.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16.sp,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final uri = Uri.parse(
                                                'https://wa.me/$whatsappNum?text=${Uri.encodeComponent('I have a question about ${course.title}')}',
                                              );
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
                                                      'Service Hours',
                                                      style: AppTextStyles.body1.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      'Mon - Sat · 9:00 AM to 6:00 PM',
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
                      },
                      icon: Icon(Icons.headset_mic, size: 20.r),
                      label: Text(
                        'Contact',
                        style: AppTextStyles.button.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        side: BorderSide(color: AppColors.primary, width: 2.r),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
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
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32.r),
        SizedBox(height: 12.h),
        Text(
          value,
          style: AppTextStyles.headline2.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22.sp,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  String _resolveCourseWhatsAppNumber(Course course, ContactInfo contactInfo) {
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

  String _resolveCourseSupportLabel(Course course) {
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

