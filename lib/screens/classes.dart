import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/student.dart';
import 'loginscreen.dart';
import '../utils/animations.dart';
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key, required this.student});

  final Student student;

  List<ClassItem> _mockAssignedClasses(Student student) {
    return [
      ClassItem(
        title: 'Algebra I - Quadratic Functions',
        teacher: 'Ms. Rivera',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        videoUrl: 'https://www.youtube.com/watch?v=ZK3O402wf1c',
        thumbnailUrl: 'https://img.youtube.com/vi/ZK3O402wf1c/hqdefault.jpg',
      ),
      ClassItem(
        title: 'Biology - Cell Structure',
        teacher: 'Dr. Chen',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        videoUrl: 'https://www.youtube.com/watch?v=URUJD5NEXC8',
        thumbnailUrl: 'https://img.youtube.com/vi/URUJD5NEXC8/hqdefault.jpg',
      ),
      ClassItem(
        title: 'History - World War II Overview',
        teacher: 'Mr. Patel',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        videoUrl: 'https://www.youtube.com/watch?v=HUqy-OQvVtI',
        thumbnailUrl: 'https://img.youtube.com/vi/HUqy-OQvVtI/hqdefault.jpg',
      ),
    ];
  }

  Future<void> _watch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _mockAssignedClasses(student);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY CLASSES',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            icon: Icon(Icons.logout, color: AppColors.textPrimary, size: 24.r),
          ),
        ],
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            elevation: 4,
            shadowColor: AppColors.shadow,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: AppColors.divider, width: 1.r),
            ),
            child: InkWell(
              onTap: () => _watch(context, item.videoUrl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
                      width: 140.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 140.w,
                        height: 100.h,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(Icons.play_circle_outline, color: AppColors.primary, size: 32.r),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 12.h, 12.w, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            item.teacher,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(item.startTime),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary.withOpacity(0.7),
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(
                                height: 32.h,
                                child: FilledButton(
                                  onPressed: () => _watch(context, item.videoUrl),
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                    backgroundColor: AppColors.primary,
                                  ),
                                  child: Text('Watch', style: AppTextStyles.button.copyWith(fontSize: 12.sp, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemCount: items.length,
      ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}