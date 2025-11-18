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
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: const Text(
          'MCQ',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: mcqs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No MCQs available for this chapter',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MCQs will appear here when they are added to videos',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final mcq = mcqs[index];
                  final fullUrl = MaterialService.getFullMaterialUrl(mcq.url);
                  
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
                        color: const Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.quiz, color: Color(0xFF4ECDC4), size: 24),
                    ),
                    title: Text(
                      mcq.videoName,
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
                          Icon(Icons.play_circle_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            mcq.lessonName,
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
                          const SnackBar(
                            content: Text('MCQ URL is not available'),
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

