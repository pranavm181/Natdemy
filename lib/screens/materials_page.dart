import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/materials_config.dart';
import '../data/material.dart';
import '../api/material_service.dart';
import '../api/course_service.dart';
import 'pdf_viewer_screen.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key, required this.courseTitle, this.courseId});

  final String courseTitle;
  final int? courseId;

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
      // Try to fetch from API first
      List<CourseMaterial> apiMaterials = [];
      if (widget.courseId != null) {
        apiMaterials = await MaterialService.fetchMaterialsForCourse(widget.courseId);
      } else {
        // If no courseId, try to find course by title
        final allCourses = await CourseService.fetchCourses();
        final course = allCourses.firstWhere(
          (c) => c.title == widget.courseTitle,
          orElse: () => allCourses.isNotEmpty ? allCourses.first : throw Exception('Course not found'),
        );
        if (course.id != null) {
          apiMaterials = await MaterialService.fetchMaterialsForCourse(course.id);
        }
      }

      if (mounted) {
        setState(() {
          if (apiMaterials.isNotEmpty) {
            _materials = apiMaterials;
            _isLoading = false;
          } else {
            // Fallback to hardcoded materials
            final fallbackMaterials = getMaterialsForCourse(widget.courseTitle);
            _materials = fallbackMaterials.map((m) => CourseMaterial(
              name: m.name,
              url: m.url,
              sizeLabel: m.sizeLabel,
            )).toList();
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading materials: $e');
      if (mounted) {
        setState(() {
          // Fallback to hardcoded materials
          final fallbackMaterials = getMaterialsForCourse(widget.courseTitle);
          _materials = fallbackMaterials.map((m) => CourseMaterial(
            name: m.name,
            url: m.url,
            sizeLabel: m.sizeLabel,
          )).toList();
          _isLoading = false;
          _errorMessage = 'Using offline materials';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final m = _materials[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: Row(
                  children: [
                    Icon(Icons.file_present, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      m.sizeLabel ?? 'Unknown size',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
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
                final fullUrl = MaterialService.getFullMaterialUrl(m.url);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      pdfUrl: fullUrl,
                      pdfTitle: m.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _materials.length,
                ),
    );
  }
}


