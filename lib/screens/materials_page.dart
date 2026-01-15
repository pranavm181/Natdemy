import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/materials_config.dart';
import '../data/material.dart';
import '../data/joined_courses.dart';
import '../api/material_service.dart';
import '../api/course_service.dart';
import '../utils/animations.dart';
import 'pdf_viewer_screen.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({
    super.key,
    required this.courseTitle,
    this.courseId,
    this.chapter,
  });

  final String courseTitle;
  final int? courseId;
  final CourseChapter? chapter;

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  List<CourseMaterial> _materials = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔄 Loading materials for course: ${widget.courseTitle} (ID: ${widget.courseId})');
      
      // If chapter is provided, collect all materials from lessons in that chapter
      List<CourseMaterial> chapterMaterials = [];
      if (widget.chapter != null) {
        debugPrint('📚 Collecting materials from chapter: ${widget.chapter!.title}');
        for (final lesson in widget.chapter!.lessons) {
          // Add materials directly attached to the lesson
          chapterMaterials.addAll(lesson.materials);
          
          // Add materials attached to videos in this lesson
          for (final video in lesson.videos) {
            if (video.materialUrl != null && video.materialUrl!.isNotEmpty) {
              chapterMaterials.add(CourseMaterial(
                name: video.materialName ?? video.name,
                url: video.materialUrl!,
                fileType: 'pdf',
              ));
            }
          }
        }
        debugPrint('✅ Found ${chapterMaterials.length} material(s) from chapter lessons');
      }
      
      // Try to fetch from API first
      List<CourseMaterial> apiMaterials = [];
      int? courseIdToUse = widget.courseId;
      
      // If no courseId, try to find course by title
      if (courseIdToUse == null) {
        try {
          final allCourses = await CourseService.fetchCourses();
          final course = allCourses.firstWhere(
            (c) => c.title == widget.courseTitle,
            orElse: () => allCourses.isNotEmpty ? allCourses.first : throw Exception('Course not found'),
          );
          courseIdToUse = course.id;
          debugPrint('📚 Found course ID: $courseIdToUse for "${widget.courseTitle}"');
        } catch (e) {
          debugPrint('⚠️ Could not find course by title: $e');
        }
      }
      
      // Fetch materials from API
      if (courseIdToUse != null) {
        debugPrint('📥 Fetching materials for course ID: $courseIdToUse');
        apiMaterials = await MaterialService.fetchMaterialsForCourse(courseIdToUse);
        debugPrint('✅ Fetched ${apiMaterials.length} material(s) from API');
        
        // Also try to fetch materials from lessons/chapters
        try {
          final allMaterials = await MaterialService.fetchMaterials();
          debugPrint('📥 Fetched ${allMaterials.length} total material(s) from API');
          
          // Filter materials for this course
          final courseMaterials = allMaterials.where((m) => m.courseId == courseIdToUse.toString()).toList();
          debugPrint('📚 Found ${courseMaterials.length} material(s) for course $courseIdToUse');
          
          // Merge with existing materials (avoid duplicates)
          for (final material in courseMaterials) {
            if (!apiMaterials.any((m) => m.id == material.id || m.url == material.url)) {
              apiMaterials.add(material);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching all materials: $e');
        }
      } else {
        // Try to fetch all materials and match by course title
        try {
          final allMaterials = await MaterialService.fetchMaterials();
          debugPrint('📥 Fetched ${allMaterials.length} total material(s) from API');
          
          // Try to match by course title (if course info is in material)
          // This is a fallback if courseId is not available
          apiMaterials = allMaterials;
        } catch (e) {
          debugPrint('⚠️ Error fetching all materials: $e');
        }
      }

      if (mounted) {
        setState(() {
          // Combine chapter materials with API materials
          final allMaterials = <CourseMaterial>[];
          
          // Add chapter materials first (these are specific to the chapter)
          allMaterials.addAll(chapterMaterials);
          
          // Add API materials (avoid duplicates by URL)
          for (final apiMaterial in apiMaterials) {
            if (!allMaterials.any((m) => m.url == apiMaterial.url)) {
              allMaterials.add(apiMaterial);
            }
          }
          
          _materials = allMaterials;
          _isLoading = false;
          if (allMaterials.isEmpty) {
            _errorMessage = 'No materials available.';
          } else {
            debugPrint('✅ Displaying ${_materials.length} material(s) total (${chapterMaterials.length} from chapter, ${apiMaterials.length} from API)');
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading materials: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          // Combine chapter materials only
          final allMaterials = <CourseMaterial>[];
          
          // Add chapter materials first
          if (widget.chapter != null) {
            for (final lesson in widget.chapter!.lessons) {
              allMaterials.addAll(lesson.materials);
              for (final video in lesson.videos) {
                if (video.materialUrl != null && video.materialUrl!.isNotEmpty) {
                  allMaterials.add(CourseMaterial(
                    name: video.materialName ?? video.name,
                    url: video.materialUrl!,
                    fileType: 'pdf',
                  ));
                }
              }
            }
          }
          
          _materials = allMaterials;
          _isLoading = false;
          _errorMessage = allMaterials.isEmpty ? 'No materials available' : null;
        });
      }
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
          'MATERIALS',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaterials,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemBuilder: (context, index) => ShimmerLoading.rectangular(
                  height: 90.h,
                  width: double.infinity,
                  borderRadius: 16.r,
                ),
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemCount: 8,
              )
            : _materials.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: (_errorMessage != null ? AppColors.error : AppColors.primary).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _errorMessage != null ? Icons.error_outline : Icons.folder_open,
                              size: 64.r,
                              color: _errorMessage != null ? AppColors.error : AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            _errorMessage ?? 'No materials available',
                            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32.h),
                          FilledButton.icon(
                            onPressed: _loadMaterials,
                            icon: const Icon(Icons.refresh),
                            label: const Text('RETRY'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemBuilder: (context, index) {
                      final m = _materials[index];
                      // Ensure URL is properly formatted
                      final materialUrl = m.url;
                      final fullUrl = MaterialService.getFullMaterialUrl(materialUrl);
                      
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
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24.r),
                            ),
                            title: Text(
                              m.name,
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (m.sizeLabel != null)
                                    Row(
                                      children: [
                                        Icon(Icons.file_present, size: 14.r, color: AppColors.textSecondary),
                                        SizedBox(width: 4.w),
                                        Text(
                                          m.sizeLabel!,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 13.sp),
                                        ),
                                      ],
                                    ),
                                  if (m.fileType != null) ...[
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(Icons.insert_drive_file, size: 12.r, color: AppColors.textSecondary.withOpacity(0.7)),
                                        SizedBox(width: 4.w),
                                        Text(
                                          m.fileType!.toUpperCase(),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary.withOpacity(0.7),
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                debugPrint('📄 Opening material: ${m.name}');
                                debugPrint('   URL: $fullUrl');
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerScreen(
                                      pdfUrl: fullUrl,
                                      pdfTitle: m.name,
                                      allowDownload: false,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Material URL is not available'),
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
                    itemCount: _materials.length,
                  ),
      ),
    );
  }
}


