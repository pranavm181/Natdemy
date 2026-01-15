import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/joined_courses.dart';
import '../api/material_service.dart';
import '../utils/animations.dart';
import 'pdf_viewer_screen.dart';

class QuestionBankPage extends StatelessWidget {
  const QuestionBankPage({
    super.key,
    required this.chapter,
    required this.courseTitle,
  });

  final CourseChapter chapter;
  final String courseTitle;

  List<_McqItem> _collectMcqs() {
    final mcqs = <_McqItem>[];
    
    debugPrint('🔍 Collecting MCQs from chapter: ${chapter.title}');
    debugPrint('   Chapter has ${chapter.lessons.length} lesson(s)');
    
    for (final lesson in chapter.lessons) {
      debugPrint('   📚 Lesson "${lesson.title}": ${lesson.videos.length} video(s)');
      for (final video in lesson.videos) {
        debugPrint('      🎥 Video "${video.name}": mcqUrl=${video.mcqUrl}');
        if (video.mcqUrl != null && video.mcqUrl!.isNotEmpty) {
          mcqs.add(_McqItem(
            title: '${video.name} - ${lesson.title}',
            url: video.mcqUrl!,
            videoName: video.name,
            lessonName: lesson.title,
          ));
          debugPrint('         ✅ Added MCQ: ${video.mcqUrl}');
        }
      }
    }
    
    debugPrint('📊 Total MCQs collected: ${mcqs.length}');
    return mcqs;
  }

  @override
  Widget build(BuildContext context) {
    final mcqs = _collectMcqs();

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
          'MCQ',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: mcqs.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.quiz_outlined, size: 64.r, color: AppColors.primary),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'No MCQs available for this chapter',
                        style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'MCQs will appear here when they are added to videos',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemBuilder: (context, index) {
                  final mcq = mcqs[index];
                  final fullUrl = MaterialService.getFullMaterialUrl(mcq.url);
                  
                  return AnimatedListItem(
                    index: index,
                    child: Card(
                      elevation: 2,
                      shadowColor: AppColors.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(color: AppColors.divider, width: 1.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        leading: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.quiz, color: AppColors.accent, size: 24.r),
                        ),
                        title: Text(
                          mcq.videoName,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_outline, size: 14.r, color: AppColors.textSecondary),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  mcq.lessonName,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 13.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20.r),
                        ),
                        onTap: () {
                          if (fullUrl.isNotEmpty) {
                            debugPrint('📝 Opening MCQ: ${mcq.title}');
                            debugPrint('   URL: $fullUrl');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  pdfUrl: fullUrl,
                                  pdfTitle: mcq.title,
                                  allowDownload: false,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('MCQ URL is not available'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemCount: mcqs.length,
              ),
      ),
    );
  }
}

class _McqItem {
  const _McqItem({
    required this.title,
    required this.url,
    required this.videoName,
    required this.lessonName,
  });

  final String title;
  final String url;
  final String videoName;
  final String lessonName;
}

