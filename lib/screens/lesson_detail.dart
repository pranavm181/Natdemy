import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../data/lesson_videos_config.dart';
import '../data/joined_courses.dart';
import '../api/material_service.dart';
import '../utils/animations.dart';
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
  late List<CourseVideo> apiVideos;
  late bool useApiVideos;
  int selectedVideoIndex = 0;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    if (lesson != null && lesson.videos.isNotEmpty) {
      useApiVideos = true;
      apiVideos = lesson.videos;
    } else {
      useApiVideos = false;
      apiVideos = [];
    }
  }

  void _selectVideo(int index) {
    setState(() {
      selectedVideoIndex = index;
    });
  }

  Future<void> _toggleFullscreen() async {
    if (_webViewController == null) return;
    
    try {
      // Use Vimeo Player API to toggle fullscreen
      await _webViewController?.evaluateJavascript(source: '''
        (function() {
          try {
            if (typeof player !== 'undefined' && player) {
              player.getFullscreen().then(function(isFullscreen) {
                if (isFullscreen) {
                  player.exitFullscreen();
                } else {
                  player.requestFullscreen();
                }
              }).catch(function(error) {
                console.log('Fullscreen error: ' + error);
                // Fallback: try iframe fullscreen
                var iframe = document.getElementById('player');
                if (iframe && iframe.requestFullscreen) {
                  iframe.requestFullscreen();
                } else if (iframe && iframe.webkitRequestFullscreen) {
                  iframe.webkitRequestFullscreen();
                }
              });
            } else {
              // Fallback if player not ready
              var iframe = document.getElementById('player');
              if (iframe && iframe.requestFullscreen) {
                iframe.requestFullscreen();
              } else if (iframe && iframe.webkitRequestFullscreen) {
                iframe.webkitRequestFullscreen();
              }
            }
          } catch (e) {
            console.log('Fullscreen error: ' + e);
          }
        })();
      ''');
    } catch (e) {
      debugPrint('Error toggling fullscreen: $e');
      // Fallback: Show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fullscreen may not be available on this device'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!useApiVideos || apiVideos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
            color: const Color(0xFF582DB0),
          ),
          automaticallyImplyLeading: true,
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
        body: AppAnimations.fadeSlideIn(
          delay: 100,
          child: const Center(child: Text('No videos available')),
        ),
      );
    }

    final CourseVideo? currentCourseVideo = apiVideos[selectedVideoIndex];
    final videoId = currentCourseVideo?.vimeoId ?? currentCourseVideo?.videoUrl ?? '';

    final lessonMaterials = widget.lesson?.materials ?? const [];
    final hasMaterials = lessonMaterials.isNotEmpty;
    
    // Debug: Log materials count
    if (lessonMaterials.isNotEmpty) {
      debugPrint('📄 Lesson "${widget.lessonName}": Found ${lessonMaterials.length} material(s)');
      for (int i = 0; i < lessonMaterials.length; i++) {
        debugPrint('   Material ${i + 1}: ${lessonMaterials[i].name} (${lessonMaterials[i].url})');
      }
    }
    
    // Get material for currently selected video
    final currentVideoMaterial = useApiVideos && currentCourseVideo != null
        ? currentCourseVideo!.materialUrl
        : null;
    final currentVideoMaterialName = useApiVideos && currentCourseVideo != null
        ? (currentCourseVideo!.materialName ?? currentCourseVideo!.name)
        : null;
    
    // Collect MCQs from all videos in the lesson
    final lessonMcqs = <_McqItem>[];
    if (useApiVideos && widget.lesson != null) {
      for (final video in widget.lesson!.videos) {
        if (video.mcqUrl != null && video.mcqUrl!.isNotEmpty) {
          lessonMcqs.add(_McqItem(
            title: video.name,
            url: video.mcqUrl!,
            videoName: video.name,
          ));
        }
      }
    }
    final hasMcqs = lessonMcqs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: const Color(0xFF582DB0),
        ),
        automaticallyImplyLeading: true,
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
                      child: Stack(
                        children: [
                          VimeoVideoPlayer(
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
                            onInAppWebViewCreated: (controller) {
                              _webViewController = controller;
                              
                              // Wait for video player to load before injecting scripts
                              Future.delayed(const Duration(milliseconds: 2000), () {
                                // Inject script to hide/disable ONLY the "Share" option
                                controller.evaluateJavascript(source: '''
                                (function() {
                                  window.hideShareOption = function() {
                                    try {
                                      // Only run if video player is loaded
                                      var videoIframe = document.querySelector('iframe[src*="vimeo"], iframe[src*="player"]');
                                      if (!videoIframe || !videoIframe.offsetParent) {
                                        return;
                                      }
                                      
                                      // Inject CSS to hide share options at CSS level
                                      if (!document.getElementById('hide-share-css')) {
                                        var style = document.createElement('style');
                                        style.id = 'hide-share-css';
                                        style.textContent = `
                                          [aria-label*="Share" i],
                                          [title*="Share" i],
                                          *:has-text("Share"),
                                          button:has([aria-label*="Share" i]),
                                          li:has-text("Share"),
                                          [role="menuitem"]:has-text("Share") {
                                            display: none !important;
                                            visibility: hidden !important;
                                            opacity: 0 !important;
                                            width: 0 !important;
                                            height: 0 !important;
                                            padding: 0 !important;
                                            margin: 0 !important;
                                            pointer-events: none !important;
                                          }
                                        `;
                                        (document.head || document.documentElement).appendChild(style);
                                      }
                                      
                                      // Target ALL elements and check for "Share" text
                                      var allElements = document.querySelectorAll('*');
                                      allElements.forEach(function(el) {
                                        try {
                                          var ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase().trim();
                                          var title = (el.getAttribute('title') || '').toLowerCase().trim();
                                          var text = (el.textContent || '').trim().toLowerCase();
                                          
                                          // Check if it's the "Share" option - be very specific
                                          var isShare = false;
                                          
                                          // Exact match
                                          if (ariaLabel === 'share' || title === 'share' || text === 'share') {
                                            isShare = true;
                                          }
                                          
                                          // Text starts with "share" and is short (likely just "Share")
                                          if (!isShare && text.startsWith('share') && text.length < 20) {
                                            // Make sure it's not part of a longer word
                                            var words = text.split(/[\s\n\r]+/);
                                            if (words.some(function(word) { return word === 'share'; })) {
                                              isShare = true;
                                            }
                                          }
                                          
                                          if (isShare) {
                                            // Completely hide and remove
                                            el.style.cssText = 'display: none !important; visibility: hidden !important; opacity: 0 !important; width: 0 !important; height: 0 !important; padding: 0 !important; margin: 0 !important; pointer-events: none !important; position: absolute !important; left: -9999px !important;';
                                            
                                            // Remove from DOM
                                            try {
                                              if (el.parentNode) {
                                                el.parentNode.removeChild(el);
                                              }
                                            } catch (e) {}
                                          }
                                        } catch (e) {}
                                      });
                                    } catch (e) {
                                      console.log('Error hiding share option: ' + e);
                                    }
                                  };
                                  
                                  // Run immediately
                                  hideShareOption();
                                  
                                  // Run on DOM ready
                                  if (document.readyState === 'loading') {
                                    document.addEventListener('DOMContentLoaded', hideShareOption);
                                  }
                                  
                                  // Run on window load
                                  window.addEventListener('load', hideShareOption);
                                  
                                  // Global click interceptor to catch share button clicks
                                  document.addEventListener('click', function(e) {
                                    var target = e.target;
                                    if (target) {
                                      var text = (target.textContent || '').toLowerCase().trim();
                                      var ariaLabel = (target.getAttribute('aria-label') || '').toLowerCase().trim();
                                      var title = (target.getAttribute('title') || '').toLowerCase().trim();
                                      
                                      if (text === 'share' || 
                                          ariaLabel === 'share' || 
                                          title === 'share' ||
                                          (text.startsWith('share') && text.length < 15)) {
                                        e.preventDefault();
                                        e.stopPropagation();
                                        e.stopImmediatePropagation();
                                        return false;
                                      }
                                      
                                      // Also check parent elements
                                      var parent = target.parentElement;
                                      if (parent) {
                                        var parentText = (parent.textContent || '').toLowerCase().trim();
                                        var parentAriaLabel = (parent.getAttribute('aria-label') || '').toLowerCase().trim();
                                        if (parentText === 'share' || parentAriaLabel === 'share') {
                                          e.preventDefault();
                                          e.stopPropagation();
                                          e.stopImmediatePropagation();
                                          return false;
                                        }
                                      }
                                    }
                                  }, true); // Use capture phase
                                  
                                  // MutationObserver to catch dynamically added share options
                                  var targetNode = document.body || document.documentElement;
                                  if (targetNode && targetNode.nodeType === 1) {
                                    var observer = new MutationObserver(function(mutations) {
                                      var hasMenuChanges = false;
                                      mutations.forEach(function(mutation) {
                                        if (mutation.addedNodes.length > 0) {
                                          mutation.addedNodes.forEach(function(node) {
                                            if (node.nodeType === 1) {
                                              var text = (node.textContent || '').toLowerCase();
                                              if (text.includes('share') || 
                                                  (node.getAttribute && (node.getAttribute('aria-label') || '').toLowerCase().includes('share'))) {
                                                hasMenuChanges = true;
                                              }
                                            }
                                          });
                                        }
                                      });
                                      if (hasMenuChanges) {
                                        hideShareOption();
                                      }
                                    });
                                    
                                    observer.observe(targetNode, {
                                      childList: true,
                                      subtree: true,
                                      attributes: true,
                                      attributeFilter: ['aria-label', 'title']
                                    });
                                  }
                                  
                                  // Check very frequently to catch share options immediately
                                  var checkCount = 0;
                                  var intervalId = setInterval(function() {
                                    checkCount++;
                                    var iframe = document.querySelector('iframe[src*="vimeo"], iframe[src*="player"]');
                                    if (iframe && iframe.offsetParent) {
                                      hideShareOption();
                                    }
                                    // Keep checking for longer to catch dynamically opened menus
                                    if (checkCount > 200) {
                                      clearInterval(intervalId);
                                    }
                                  }, 200);
                                })();
                              ''');
                              });
                              
                              // Also inject after delays to catch late-loading share options
                              Future.delayed(const Duration(milliseconds: 5000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption();');
                              });
                              Future.delayed(const Duration(milliseconds: 8000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption();');
                              });
                            },
                          ),
                          // Fullscreen button overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleFullscreen(),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                                : 'Lesson Video',
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
          // View Lesson Materials Button
          if (hasMaterials) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FilledButton.icon(
                onPressed: () {
                  // Scroll to materials section or show materials dialog
                  if (lessonMaterials.isNotEmpty) {
                    // If multiple materials, show them in a dialog or scroll to section
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Lesson Materials',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF582DB0),
                          ),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: lessonMaterials.length,
                            itemBuilder: (context, index) {
                              final material = lessonMaterials[index];
                              final fullUrl = MaterialService.getFullMaterialUrl(material.url);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                                  title: Text(material.name),
                                  subtitle: material.sizeLabel != null
                                      ? Text(material.sizeLabel!)
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          pdfUrl: fullUrl,
                                          pdfTitle: material.name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No material available'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 22),
                label: Text(
                  lessonMaterials.isNotEmpty
                      ? 'View Lesson Materials (${lessonMaterials.length})'
                      : 'View Lesson Material',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF582DB0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          // Lesson Materials Section
          if (hasMaterials) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'MATERIALS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (lessonMaterials.isNotEmpty)
              // Show all materials from API
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lessonMaterials.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${lessonMaterials.length} materials available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ...lessonMaterials.map((material) {
                    final fullUrl = MaterialService.getFullMaterialUrl(material.url);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                        ),
                        title: Text(
                          material.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                          ),
                        ),
                        subtitle: material.sizeLabel != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.file_present, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      material.sizeLabel!,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF582DB0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.visibility_outlined, color: Color(0xFF582DB0), size: 20),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(
                                pdfUrl: fullUrl,
                                pdfTitle: material.name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
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
          // Video Material Section (for currently selected video) - moved to bottom
          if (currentVideoMaterial != null && currentVideoMaterial.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'VIDEO MATERIAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                  ),
                  title: Text(
                    currentVideoMaterialName ?? 'Video Material',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.video_library, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Material for: ${useApiVideos ? (currentCourseVideo?.name ?? 'Current Video') : 'Current Video'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF582DB0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility_outlined, color: Color(0xFF582DB0), size: 20),
                  ),
                  onTap: () {
                    final fullUrl = MaterialService.getFullMaterialUrl(currentVideoMaterial);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PdfViewerScreen(
                          pdfUrl: fullUrl,
                          pdfTitle: currentVideoMaterialName ?? 'Video Material',
                          allowDownload: false, // View-only for video materials
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // MCQs Section - moved to bottom
          if (hasMcqs) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.quiz, color: Color(0xFF4ECDC4), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'MCQ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lessonMcqs.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${lessonMcqs.length} MCQs available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ...lessonMcqs.map((mcq) {
                    final fullUrl = MaterialService.getFullMaterialUrl(mcq.url);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.quiz, color: Color(0xFF4ECDC4), size: 24),
                        ),
                        title: Text(
                          mcq.videoName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.video_library, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'MCQ for: ${mcq.videoName}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF582DB0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.visibility_outlined, color: Color(0xFF582DB0), size: 20),
                        ),
                        onTap: () {
                          if (fullUrl.isNotEmpty) {
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
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  List<String> _currentVideoList() {
    if (useApiVideos) {
      if (apiVideos.isEmpty) return const ['Video not available'];
      return apiVideos.map((v) => v.name).toList();
    }
    return const ['Video not available'];
  }
}

class _McqItem {
  const _McqItem({
    required this.title,
    required this.url,
    required this.videoName,
  });

  final String title;
  final String url;
  final String videoName;
}

