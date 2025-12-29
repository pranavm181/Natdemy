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

  void _showMoreOptionsLockedMessage() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('More options are disabled for this video'),
        duration: Duration(seconds: 2),
      ),
    );
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

    // Get lesson materials from the lesson object
    final lessonMaterials = widget.lesson?.materials ?? const [];
    final hasMaterials = lessonMaterials.isNotEmpty;
    
    // Debug: Log materials count
    debugPrint('🔍 Lesson Detail Debug:');
    debugPrint('   Lesson: ${widget.lessonName}');
    debugPrint('   Lesson object: ${widget.lesson != null ? "present" : "null"}');
    if (widget.lesson != null) {
      debugPrint('   Lesson videos count: ${widget.lesson!.videos.length}');
      debugPrint('   Lesson materials count: ${widget.lesson!.materials.length}');
    }
    
    if (lessonMaterials.isNotEmpty) {
      debugPrint('📄 Lesson "${widget.lessonName}": Found ${lessonMaterials.length} material(s)');
      for (int i = 0; i < lessonMaterials.length; i++) {
        debugPrint('   Material ${i + 1}: ${lessonMaterials[i].name} (${lessonMaterials[i].url})');
      }
    } else {
      debugPrint('⚠️ Lesson "${widget.lessonName}": No materials found in lesson object');
    }
    
    // Get material for currently selected video
    final currentVideoMaterial = useApiVideos && currentCourseVideo != null
        ? currentCourseVideo!.materialUrl
        : null;
    final currentVideoMaterialName = useApiVideos && currentCourseVideo != null
        ? (currentCourseVideo!.materialName ?? currentCourseVideo!.name)
        : null;
    
    if (currentVideoMaterial != null && currentVideoMaterial.isNotEmpty) {
      debugPrint('📎 Current video material: $currentVideoMaterialName ($currentVideoMaterial)');
    }
    
    // Collect MCQs from all videos in the lesson
    final lessonMcqs = <_McqItem>[];
    if (useApiVideos && widget.lesson != null) {
      debugPrint('🔍 Checking ${widget.lesson!.videos.length} video(s) for MCQs...');
      for (final video in widget.lesson!.videos) {
        if (video.mcqUrl != null && video.mcqUrl!.isNotEmpty) {
          debugPrint('   ✅ Found MCQ for video "${video.name}": ${video.mcqUrl}');
          lessonMcqs.add(_McqItem(
            title: video.name,
            url: video.mcqUrl!,
            videoName: video.name,
          ));
        } else {
          debugPrint('   ⚠️ Video "${video.name}": No MCQ URL');
        }
      }
    } else {
      debugPrint('⚠️ Cannot collect MCQs: useApiVideos=$useApiVideos, lesson=${widget.lesson != null}');
    }
    final hasMcqs = lessonMcqs.isNotEmpty;
    
    if (hasMcqs) {
      debugPrint('📝 Found ${lessonMcqs.length} MCQ(s) total');
    } else {
      debugPrint('⚠️ No MCQs found for lesson "${widget.lessonName}"');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
                              
                              // Inject script immediately and multiple times for better coverage
                              // First injection - immediate
                              controller.evaluateJavascript(source: '''
                                (function() {
                                  // Function to hide sign-in prompts and blocks
                                  window.hideSignInPrompt = function() {
                                    try {
                                      // Hide sign-in related elements
                                      var signInSelectors = [
                                        '[class*="sign"][class*="in" i]',
                                        '[class*="login" i]',
                                        '[aria-label*="sign" i][aria-label*="in" i]',
                                        '[aria-label*="log" i][aria-label*="in" i]',
                                        '[title*="sign" i][title*="in" i]',
                                        '[title*="log" i][title*="in" i]',
                                        'button:contains("Sign in")',
                                        'button:contains("Log in")',
                                        'a:contains("Sign in")',
                                        'a:contains("Log in")',
                                        '[data-testid*="sign" i][data-testid*="in" i]',
                                        '[data-testid*="login" i]'
                                      ];
                                      
                                      signInSelectors.forEach(function(selector) {
                                        try {
                                          var elements = document.querySelectorAll(selector);
                                          elements.forEach(function(el) {
                                            var text = (el.textContent || '').toLowerCase();
                                            var ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase();
                                            var title = (el.getAttribute('title') || '').toLowerCase();
                                            if (text.includes('sign') && text.includes('in') ||
                                                text.includes('log') && text.includes('in') ||
                                                ariaLabel.includes('sign') && ariaLabel.includes('in') ||
                                                ariaLabel.includes('log') && ariaLabel.includes('in') ||
                                                title.includes('sign') && title.includes('in') ||
                                                title.includes('log') && title.includes('in')) {
                                              el.style.cssText = 'display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important;';
                                              try {
                                                if (el.parentNode) {
                                                  el.parentNode.removeChild(el);
                                                }
                                              } catch (e) {}
                                            }
                                          });
                                        } catch (e) {}
                                      });
                                      
                                      // Find and hide all elements containing "sign in" or "log in" text
                                      var allElements = document.querySelectorAll('*');
                                      allElements.forEach(function(el) {
                                        try {
                                          var text = (el.textContent || '').toLowerCase().trim();
                                          var ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase();
                                          var title = (el.getAttribute('title') || '').toLowerCase();
                                          
                                          var isSignIn = (text.includes('sign') && text.includes('in')) ||
                                                         (text.includes('log') && text.includes('in')) ||
                                                         (ariaLabel.includes('sign') && ariaLabel.includes('in')) ||
                                                         (ariaLabel.includes('log') && ariaLabel.includes('in')) ||
                                                         (title.includes('sign') && title.includes('in')) ||
                                                         (title.includes('log') && title.includes('in'));
                                          
                                          // Don't hide play buttons or video controls
                                          var isVideoControl = text.includes('play') || 
                                                               text.includes('pause') ||
                                                               ariaLabel.includes('play') ||
                                                               ariaLabel.includes('pause');
                                          
                                          if (isSignIn && !isVideoControl) {
                                            el.style.cssText = 'display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important;';
                                            try {
                                              if (el.parentNode) {
                                                el.parentNode.removeChild(el);
                                              }
                                            } catch (e) {}
                                          }
                                        } catch (e) {}
                                      });
                                    } catch (e) {
                                      console.log('Error hiding sign-in prompt: ' + e);
                                    }
                                  };
                                  
                                  window.hideShareOption = function() {
                                    try {
                                      // Inject CSS to hide share options and more options button
                                      if (!document.getElementById('hide-share-css')) {
                                        var style = document.createElement('style');
                                        style.id = 'hide-share-css';
                                        style.textContent = `
                                          [aria-label*="Share" i],
                                          [title*="Share" i],
                                          [aria-label*="More options" i],
                                          [title*="More options" i],
                                          button[aria-label*="More" i]:not([aria-label*="Play" i]):not([aria-label*="Pause" i]):not([aria-label*="Settings" i]):not([aria-label*="Quality" i]),
                                          button[aria-label*="menu" i]:not([aria-label*="Play" i]):not([aria-label*="Pause" i]),
                                          button[title*="More" i]:not([title*="Play" i]):not([title*="Pause" i]),
                                          button[title*="menu" i]:not([title*="Play" i]):not([title*="Pause" i]),
                                          [role="button"][aria-label*="More" i]:not([aria-label*="Play" i]):not([aria-label*="Pause" i]),
                                          [role="button"][aria-label*="menu" i]:not([aria-label*="Play" i]):not([aria-label*="Pause" i]),
                                          button:has(svg circle:nth-of-type(3)):not([aria-label*="Play" i]):not([aria-label*="Pause" i]):not([aria-label*="Settings" i]):not([aria-label*="Quality" i]),
                                          button:has(svg path[d*="M"]:nth-of-type(3)):not([aria-label*="Play" i]):not([aria-label*="Pause" i]) {
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
                                      
                                      // Add overlay div to block clicks on iframe's "More options" button area
                                      function createBlockerOverlay() {
                                        var existingBlocker = document.getElementById('vimeo-more-options-blocker');
                                        if (existingBlocker) {
                                          existingBlocker.remove();
                                        }
                                        
                                        var blocker = document.createElement('div');
                                        blocker.id = 'vimeo-more-options-blocker';
                                        blocker.style.cssText = 'position: absolute; top: 0; right: 0; width: 80px; height: 60px; z-index: 999999; pointer-events: auto; background: transparent;';
                                        
                                        // Find the iframe container and add blocker
                                        var iframe = document.querySelector('iframe[src*="vimeo"], iframe[src*="player"]');
                                        if (iframe) {
                                          // Try to add blocker to iframe's parent
                                          if (iframe.parentElement) {
                                            var parent = iframe.parentElement;
                                            if (getComputedStyle(parent).position === 'static') {
                                              parent.style.position = 'relative';
                                            }
                                            parent.appendChild(blocker);
                                          } else {
                                            // Add blocker to body positioned over iframe
                                            var rect = iframe.getBoundingClientRect();
                                            blocker.style.position = 'fixed';
                                            blocker.style.top = (rect.top + 8) + 'px';
                                            blocker.style.right = (window.innerWidth - rect.right + 8) + 'px';
                                            document.body.appendChild(blocker);
                                          }
                                        } else {
                                          // Try to find body or any container
                                          var container = document.body || document.documentElement;
                                          if (container) {
                                            container.appendChild(blocker);
                                          }
                                        }
                                        
                                        // Block all pointer events on the blocker
                                        blocker.addEventListener('click', function(e) {
                                          e.preventDefault();
                                          e.stopPropagation();
                                          e.stopImmediatePropagation();
                                          return false;
                                        }, true);
                                        
                                        blocker.addEventListener('mousedown', function(e) {
                                          e.preventDefault();
                                          e.stopPropagation();
                                          e.stopImmediatePropagation();
                                          return false;
                                        }, true);
                                        
                                        blocker.addEventListener('touchstart', function(e) {
                                          e.preventDefault();
                                          e.stopPropagation();
                                          e.stopImmediatePropagation();
                                          return false;
                                        }, true);
                                        
                                        blocker.addEventListener('contextmenu', function(e) {
                                          e.preventDefault();
                                          e.stopPropagation();
                                          e.stopImmediatePropagation();
                                          return false;
                                        }, true);
                                      }
                                      
                                      createBlockerOverlay();
                                      
                                      // Try to access iframe content if possible
                                      var videoIframe = document.querySelector('iframe[src*="vimeo"], iframe[src*="player"]');
                                      var iframeDoc = null;
                                      var iframeWindow = null;
                                      try {
                                        if (videoIframe) {
                                          if (videoIframe.contentDocument) {
                                            iframeDoc = videoIframe.contentDocument;
                                            iframeWindow = videoIframe.contentWindow;
                                          } else if (videoIframe.contentWindow) {
                                            iframeWindow = videoIframe.contentWindow;
                                            try {
                                              iframeDoc = iframeWindow.document;
                                            } catch (e) {}
                                          }
                                          
                                          // Try to inject script into iframe if accessible
                                          if (iframeWindow && iframeWindow.eval) {
                                            try {
                                              iframeWindow.eval('(' + hideShareOption.toString() + ')();');
                                            } catch (e) {}
                                          }
                                        }
                                      } catch (e) {
                                        // Cross-origin restriction - can't access iframe content
                                      }
                                      
                                      // Function to hide elements in a document
                                      function hideElementsInDoc(doc) {
                                        if (!doc) return;
                                        
                                        try {
                                      
                                          // First, try to find and hide buttons with three dots (More options icon)
                                          var allButtons = doc.querySelectorAll('button, [role="button"]');
                                          allButtons.forEach(function(btn) {
                                            try {
                                              // Check if button contains exactly 3 circles (three dots)
                                              var svg = btn.querySelector('svg');
                                              if (svg) {
                                                var circles = svg.querySelectorAll('circle');
                                                if (circles.length === 3) {
                                                  // Check if it's not a known control button
                                                  var ariaLabel = (btn.getAttribute('aria-label') || '').toLowerCase();
                                                  if (!ariaLabel.includes('play') && 
                                                      !ariaLabel.includes('pause') &&
                                                      !ariaLabel.includes('settings') &&
                                                      !ariaLabel.includes('quality') &&
                                                      !ariaLabel.includes('captions') &&
                                                      !ariaLabel.includes('subtitles') &&
                                                      !ariaLabel.includes('speed') &&
                                                      !ariaLabel.includes('volume') &&
                                                      !ariaLabel.includes('mute') &&
                                                      !ariaLabel.includes('fullscreen')) {
                                                    // This is likely the "More options" button
                                                    btn.style.cssText = 'display: none !important; visibility: hidden !important; opacity: 0 !important; width: 0 !important; height: 0 !important; padding: 0 !important; margin: 0 !important; pointer-events: none !important; position: absolute !important; left: -9999px !important;';
                                                    try {
                                                      if (btn.parentNode) {
                                                        btn.parentNode.removeChild(btn);
                                                      }
                                                    } catch (e) {}
                                                  }
                                                }
                                              }
                                            } catch (e) {}
                                          });
                                          
                                          // Target ALL elements and check for "Share" text and "More options" button
                                          var allElements = doc.querySelectorAll('*');
                                          allElements.forEach(function(el) {
                                            try {
                                              var ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase().trim();
                                              var title = (el.getAttribute('title') || '').toLowerCase().trim();
                                              var text = (el.textContent || '').trim().toLowerCase();
                                              var role = (el.getAttribute('role') || '').toLowerCase().trim();
                                              var tagName = (el.tagName || '').toLowerCase();
                                              var className = (el.className || '').toLowerCase();
                                              
                                              // Check if it's the "Share" option
                                              var isShare = false;
                                              if (ariaLabel === 'share' || title === 'share' || text === 'share') {
                                                isShare = true;
                                              }
                                              if (!isShare && text.startsWith('share') && text.length < 20) {
                                                var words = text.split(/[\s\n\r]+/);
                                                if (words.some(function(word) { return word === 'share'; })) {
                                                  isShare = true;
                                                }
                                              }
                                              
                                              // Check if it's the "More options" button - very aggressive detection
                                              var isMoreOptions = false;
                                              
                                              // Check for buttons with exactly 3 circles (three dots icon)
                                              var circles = el.querySelectorAll('circle');
                                              var hasThreeDots = circles.length === 3;
                                              
                                              // Check for three dots in SVG paths
                                              if (!hasThreeDots) {
                                                var svg = el.querySelector('svg');
                                                if (svg) {
                                                  var paths = svg.querySelectorAll('path');
                                                  paths.forEach(function(path) {
                                                    var d = path.getAttribute('d') || '';
                                                    var mCommands = d.match(/M[^M]*/g);
                                                    if (mCommands && mCommands.length >= 3) {
                                                      hasThreeDots = true;
                                                    }
                                                  });
                                                }
                                              }
                                              
                                              // If it has three dots, it's likely the "More options" button
                                              if (hasThreeDots && (tagName === 'button' || role === 'button')) {
                                                // Make sure it's not another control
                                                if (!ariaLabel.includes('settings') && 
                                                    !ariaLabel.includes('quality') && 
                                                    !ariaLabel.includes('captions') &&
                                                    !ariaLabel.includes('subtitles') &&
                                                    !ariaLabel.includes('speed') &&
                                                    !ariaLabel.includes('play') &&
                                                    !ariaLabel.includes('pause') &&
                                                    !ariaLabel.includes('volume') &&
                                                    !ariaLabel.includes('mute') &&
                                                    !ariaLabel.includes('fullscreen')) {
                                                  isMoreOptions = true;
                                                }
                                              }
                                              
                                              // Check aria-label and title
                                              if (!isMoreOptions) {
                                                if (ariaLabel.includes('more') && (ariaLabel.includes('option') || ariaLabel.includes('menu'))) {
                                                  isMoreOptions = true;
                                                }
                                                if (title.includes('more') && (title.includes('option') || title.includes('menu'))) {
                                                  isMoreOptions = true;
                                                }
                                                // Check for buttons with menu-related attributes
                                                if ((tagName === 'button' || role === 'button') && 
                                                    (ariaLabel.includes('more') || ariaLabel.includes('menu') || 
                                                     title.includes('more') || title.includes('menu'))) {
                                                  // Double check it's not another control
                                                  if (!ariaLabel.includes('settings') && 
                                                      !ariaLabel.includes('quality') && 
                                                      !ariaLabel.includes('captions') &&
                                                      !ariaLabel.includes('subtitles') &&
                                                      !ariaLabel.includes('speed') &&
                                                      !ariaLabel.includes('play') &&
                                                      !ariaLabel.includes('pause')) {
                                                    isMoreOptions = true;
                                                  }
                                                }
                                                // Check for three-dot menu buttons (common pattern)
                                                if (tagName === 'button' && 
                                                    (ariaLabel === 'more' || ariaLabel === 'menu' || 
                                                     title === 'more' || title === 'menu')) {
                                                  isMoreOptions = true;
                                                }
                                              }
                                              
                                              if (isShare || isMoreOptions) {
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
                                        } catch (e) {}
                                      }
                                      
                                      // Hide in main document
                                      hideElementsInDoc(document);
                                      
                                      // Try to hide in iframe document if accessible
                                      if (iframeDoc) {
                                        hideElementsInDoc(iframeDoc);
                                      }
                                    } catch (e) {
                                      console.log('Error hiding share option: ' + e);
                                    }
                                  };
                                  
                                  // Run immediately
                                  hideShareOption();
                                  hideSignInPrompt();
                                  
                                  // Run on DOM ready
                                  if (document.readyState === 'loading') {
                                    document.addEventListener('DOMContentLoaded', function() {
                                      hideShareOption();
                                      hideSignInPrompt();
                                    });
                                  }
                                  
                                  // Run on window load
                                  window.addEventListener('load', function() {
                                    hideShareOption();
                                    hideSignInPrompt();
                                  });
                                  
                                  // Global click interceptor to catch share, more options, and sign-in button clicks
                                  document.addEventListener('click', function(e) {
                                    var target = e.target;
                                    if (target) {
                                      var text = (target.textContent || '').toLowerCase().trim();
                                      var ariaLabel = (target.getAttribute('aria-label') || '').toLowerCase().trim();
                                      var title = (target.getAttribute('title') || '').toLowerCase().trim();
                                      
                                      // Check for Share
                                      var isShare = text === 'share' || 
                                          ariaLabel === 'share' || 
                                          title === 'share' ||
                                          (text.startsWith('share') && text.length < 15);
                                      
                                      // Check for More options
                                      var isMoreOptions = (ariaLabel.includes('more') && (ariaLabel.includes('option') || ariaLabel.includes('menu'))) ||
                                          (title.includes('more') && (title.includes('option') || title.includes('menu'))) ||
                                          ariaLabel === 'more' || ariaLabel === 'menu' ||
                                          title === 'more' || title === 'menu';
                                      
                                      // Check for Sign in / Log in
                                      var isSignIn = (text.includes('sign') && text.includes('in')) ||
                                          (text.includes('log') && text.includes('in')) ||
                                          (ariaLabel.includes('sign') && ariaLabel.includes('in')) ||
                                          (ariaLabel.includes('log') && ariaLabel.includes('in')) ||
                                          (title.includes('sign') && title.includes('in')) ||
                                          (title.includes('log') && title.includes('in'));
                                      
                                      if (isShare || isMoreOptions || isSignIn) {
                                        e.preventDefault();
                                        e.stopPropagation();
                                        e.stopImmediatePropagation();
                                        // Hide the sign-in prompt after click attempt
                                        if (isSignIn) {
                                          setTimeout(hideSignInPrompt, 100);
                                        }
                                        return false;
                                      }
                                      
                                      // Also check parent elements
                                      var parent = target.parentElement;
                                      if (parent) {
                                        var parentText = (parent.textContent || '').toLowerCase().trim();
                                        var parentAriaLabel = (parent.getAttribute('aria-label') || '').toLowerCase().trim();
                                        var parentTitle = (parent.getAttribute('title') || '').toLowerCase().trim();
                                        if (parentText === 'share' || parentAriaLabel === 'share' ||
                                            (parentAriaLabel.includes('more') && (parentAriaLabel.includes('option') || parentAriaLabel.includes('menu'))) ||
                                            (parentTitle.includes('more') && (parentTitle.includes('option') || parentTitle.includes('menu')))) {
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
                                              var ariaLabel = (node.getAttribute && node.getAttribute('aria-label') || '').toLowerCase();
                                              var title = (node.getAttribute && node.getAttribute('title') || '').toLowerCase();
                                              if (text.includes('share') || ariaLabel.includes('share') ||
                                                  (ariaLabel.includes('more') && (ariaLabel.includes('option') || ariaLabel.includes('menu'))) ||
                                                  (title.includes('more') && (title.includes('option') || title.includes('menu'))) ||
                                                  ariaLabel === 'more' || ariaLabel === 'menu') {
                                                hasMenuChanges = true;
                                              }
                                            }
                                          });
                                        }
                                      });
                                      if (hasMenuChanges) {
                                        hideShareOption();
                                        createBlockerOverlay();
                                      }
                                      
                                      // Also check if iframe was added/changed
                                      mutations.forEach(function(mutation) {
                                        if (mutation.addedNodes.length > 0) {
                                          mutation.addedNodes.forEach(function(node) {
                                            if (node.nodeType === 1) {
                                              if (node.tagName === 'IFRAME' || node.querySelector('iframe')) {
                                                setTimeout(function() {
                                                  createBlockerOverlay();
                                                }, 100);
                                              }
                                            }
                                          });
                                        }
                                      });
                                    });
                                    
                                    observer.observe(targetNode, {
                                      childList: true,
                                      subtree: true,
                                      attributes: true,
                                      attributeFilter: ['aria-label', 'title']
                                    });
                                  }
                                  
                                  // Check very frequently to catch share options and sign-in prompts immediately - more aggressive
                                  var checkCount = 0;
                                  var intervalId = setInterval(function() {
                                    checkCount++;
                                    hideShareOption();
                                    hideSignInPrompt();
                                    // Recreate blocker overlay periodically to ensure it's always there
                                    if (checkCount % 5 === 0) {
                                      createBlockerOverlay();
                                    }
                                    // Keep checking for much longer to catch all cases
                                    if (checkCount > 500) {
                                      clearInterval(intervalId);
                                    }
                                  }, 100); // Check every 100ms instead of 200ms
                                  
                                  // Also run immediately multiple times
                                  hideShareOption();
                                  hideSignInPrompt();
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 100);
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 300);
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 500);
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 1000);
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 2000);
                                  setTimeout(function() { hideShareOption(); hideSignInPrompt(); }, 3000);
                                })();
                              ''');
                              
                              // Inject multiple times with different delays for maximum coverage
                              Future.delayed(const Duration(milliseconds: 500), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 1000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 2000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 3000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 5000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 8000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                              Future.delayed(const Duration(milliseconds: 10000), () {
                                controller.evaluateJavascript(source: 'if (window.hideShareOption) window.hideShareOption(); if (window.hideSignInPrompt) window.hideSignInPrompt();');
                              });
                            },
                          ),
                          // Overlay to block "More options" button in top-right corner
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showMoreOptionsLockedMessage,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  alignment: Alignment.center,
                                  constraints: const BoxConstraints(
                                    minWidth: 64,
                                    minHeight: 48,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Locked',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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

