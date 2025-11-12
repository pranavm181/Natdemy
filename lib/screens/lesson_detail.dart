import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';
import '../data/lesson_videos_config.dart';
import '../data/joined_courses.dart';
import '../api/material_service.dart';
import 'materials_page.dart';
import 'pdf_viewer_screen.dart';

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({
    super.key,
    required this.lessonName,
    this.lesson,
    this.courseTitle,
  });

  final String lessonName;
  final CourseLesson? lesson;
  final String? courseTitle;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late List<LessonVideo> fallbackVideos;
  late List<CourseVideo> apiVideos;
  late bool useApiVideos;
  int selectedVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    if (lesson != null && lesson.videos.isNotEmpty) {
      useApiVideos = true;
      apiVideos = lesson.videos;
    } else {
      useApiVideos = false;
      fallbackVideos = getVideosForLesson(widget.lessonName);
    }
  }

  void _selectVideo(int index) {
    setState(() {
      selectedVideoIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!useApiVideos && fallbackVideos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.black,
          ),
          title: Text(
            widget.lessonName.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF582DB0),
              fontWeight: FontWeight.w900,
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        body: const Center(child: Text('No videos available')),
      );
    }

    final CourseVideo? currentCourseVideo =
        useApiVideos ? apiVideos[selectedVideoIndex] : null;
    final LessonVideo? currentFallbackVideo =
        useApiVideos ? null : fallbackVideos[selectedVideoIndex];

    final videoId = useApiVideos
        ? (currentCourseVideo?.vimeoId ?? currentCourseVideo?.videoUrl ?? '')
        : currentFallbackVideo?.vimeoId ?? '';

    final lessonMaterials = widget.lesson?.materials ?? const [];
    final materialUrl = lessonMaterials.isNotEmpty
        ? MaterialService.getFullMaterialUrl(lessonMaterials.first.url)
        : getMaterialForLesson(widget.lessonName);

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
        ),
        title: Text(
          widget.lessonName.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF582DB0), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  if (videoId.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VimeoVideoPlayer(
                        key: ValueKey('video_${selectedVideoIndex}_$videoId'),
                        videoId: videoId,
                        isAutoPlay: false,
                        isLooping: false,
                        showControls: true,
                        showTitle: true,
                        showByline: false,
                        isMuted: false,
                        enableDNT: false,
                        backgroundColor: Colors.black,
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      height: 220,
                      child: const Center(
                        child: Text(
                          'Video not available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            useApiVideos
                                ? (currentCourseVideo?.name ?? 'Lesson Video')
                                : (currentFallbackVideo?.name ?? 'Lesson Video'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: materialUrl != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            pdfUrl: materialUrl,
                            pdfTitle: 'Lesson Materials',
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text(
                'View Materials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF582DB0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF582DB0), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDEOS IN THIS LESSON',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF000000),
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ..._currentVideoList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final videoTitle = entry.value;
                      final isSelected = index == selectedVideoIndex;
                      return Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.15),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF582DB0) : const Color(0xFF582DB0),
                            width: isSelected ? 3 : 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF582DB0).withOpacity(0.15)
                                  : const Color(0xFF582DB0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSelected ? Icons.play_circle_filled : Icons.play_circle_outline,
                              color: const Color(0xFF582DB0),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            videoTitle,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: const Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF582DB0), size: 28)
                              : const Icon(Icons.chevron_right, color: Color(0xFF582DB0), size: 28),
                          onTap: () => _selectVideo(index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
    );
  }

  List<String> _currentVideoList() {
    if (useApiVideos) {
      if (apiVideos.isEmpty) return const ['Video not available'];
      return apiVideos.map((v) => v.name).toList();
    }
    return fallbackVideos.map((v) => v.name).toList();
  }
}

