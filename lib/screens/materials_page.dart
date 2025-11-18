import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/materials_config.dart';
import '../data/material.dart';
import '../data/joined_courses.dart';
import '../api/material_service.dart';
import '../api/course_service.dart';
import '../widgets/theme_loading_indicator.dart';
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
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: const Text(
          'MATERIALS',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaterials,
        child: _isLoading
            ? const Center(child: ThemePulsingDotsIndicator(size: 12.0, spacing: 16.0))
            : _materials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No materials available',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadMaterials,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF582DB0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final m = _materials[index];
                      // Ensure URL is properly formatted
                      final materialUrl = m.url;
                      final fullUrl = MaterialService.getFullMaterialUrl(materialUrl);
                      
                      return AnimatedListItem(
                        index: index,
                        child: Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                          ),
                          title: Text(
                            m.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (m.sizeLabel != null)
                                  Row(
                                    children: [
                                      Icon(Icons.file_present, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.sizeLabel!,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                if (m.fileType != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.insert_drive_file, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.fileType!.toUpperCase(),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF582DB0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.visibility_outlined, color: Color(0xFF582DB0), size: 20),
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
                                const SnackBar(
                                  content: Text('Material URL is not available'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _materials.length,
                  ),
      ),
    );
  }
}


