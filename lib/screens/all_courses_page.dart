import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/course_catalog.dart';
import '../api/course_service.dart';
import '../utils/course_utils.dart';
import '../utils/animations.dart';
import '../utils/haptic_feedback.dart';
import '../widgets/rating_stars.dart';
import '../widgets/theme_loading_indicator.dart';
import 'course_detail.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: const Text(
          'ALL COURSES',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: _isLoading && _courses.isEmpty
          ? const Center(child: ThemePulsingDotsIndicator(size: 12.0, spacing: 16.0))
          : _errorMessage != null && _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No courses available',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250.0,
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                        childAspectRatio: 1.15,
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
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF582DB0), width: 2),
      ),
      child: InkWell(
        onTap: () {
          HapticUtils.navigationTap();
          Navigator.of(context).push(
            BouncePageRoute(
              builder: (_) => CourseDetailPage(course: course),
              direction: SlideDirection.right,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: CourseService.getFullImageUrl(course.thumbnailUrl),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Icon(
                            CourseUtils.getCourseIcon(course.title),
                            color: const Color(0xFFA1C95C),
                            size: 48,
                          );
                        },
                        memCacheWidth: 112,
                        memCacheHeight: 112,
                      ),
                    )
                  : Icon(
                      CourseUtils.getCourseIcon(course.title),
                      color: const Color(0xFFA1C95C),
                      size: 48,
                    ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  course.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              RatingStars(
                rating: course.rating,
                textStyle: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

