import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.textPrimary,
          ),
          automaticallyImplyLeading: true,
          title: Text(
            widget.lessonName.toUpperCase(),
            style: AppTextStyles.headline1.copyWith(
              color: AppColors.primary,
              fontSize: 20.sp,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        automaticallyImplyLeading: true,
        title: Text(
          widget.lessonName.toUpperCase(),
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        children: [
          Card(
            margin: EdgeInsets.all(16.r),
            elevation: 8,
            shadowColor: AppColors.shadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(color: AppColors.primary, width: 2.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
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
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            useApiVideos
                                ? (currentCourseVideo?.name ?? 'Lesson Video')
                                : 'Lesson Video',
                            style: AppTextStyles.body1.copyWith(
                              color: Colors.white,
                              fontSize: 16.sp,
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: FilledButton.icon(
                onPressed: () {
                  // Scroll to materials section or show materials dialog
                  if (lessonMaterials.isNotEmpty) {
                    // If multiple materials, show them in a dialog or scroll to section
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        title: Text(
                          'Lesson Materials',
                          style: AppTextStyles.headline1.copyWith(
                            color: AppColors.primary,
                            fontSize: 22.sp,
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
                                margin: EdgeInsets.only(bottom: 8.h),
                                elevation: 4,
                                shadowColor: AppColors.shadow,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                child: ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20.r),
                                  ),
                                  title: Text(
                                    material.name,
                                    style: AppTextStyles.body1.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  subtitle: material.sizeLabel != null
                                      ? Text(
                                          material.sizeLabel!,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                        )
                                      : null,
                                  trailing: Icon(Icons.arrow_forward_ios, size: 14.r, color: AppColors.primary),
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
                            child: Text(
                              'CLOSE',
                              style: AppTextStyles.button.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('No material available'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.picture_as_pdf, size: 22.r),
                label: Text(
                  lessonMaterials.isNotEmpty
                      ? 'View Lesson Materials (${lessonMaterials.length})'
                      : 'View Lesson Material',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
          // Lesson Materials Section
          if (hasMaterials) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24.r),
                  SizedBox(width: 8.w),
                  Text(
                    'MATERIALS',
                    style: AppTextStyles.headline2.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (lessonMaterials.isNotEmpty)
              // Show all materials from API
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lessonMaterials.length > 1)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          '${lessonMaterials.length} materials available',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ...lessonMaterials.map((material) {
                    final fullUrl = MaterialService.getFullMaterialUrl(material.url);
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      elevation: 2,
                      shadowColor: AppColors.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: AppColors.divider, width: 1.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        leading: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24.r),
                        ),
                        title: Text(
                          material.name,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                          ),
                        ),
                        subtitle: material.sizeLabel != null
                            ? Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Row(
                                  children: [
                                    Icon(Icons.file_present, size: 14.r, color: AppColors.textSecondary),
                                    SizedBox(width: 4.w),
                                    Text(
                                      material.sizeLabel!,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        trailing: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20.r),
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
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 20.h),
          Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              elevation: 8,
              shadowColor: AppColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(color: AppColors.primary, width: 2.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDEOS IN THIS LESSON',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ..._currentVideoList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final videoTitle = entry.value;
                      final isSelected = index == selectedVideoIndex;
                      return Card(
                        elevation: isSelected ? 8 : 2,
                        shadowColor: isSelected ? AppColors.primary.withOpacity(0.3) : AppColors.shadow,
                        margin: EdgeInsets.only(bottom: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 3.r : 1.r,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          leading: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              isSelected ? Icons.play_circle_filled : Icons.play_circle_outline,
                              color: AppColors.primary,
                              size: 28.r,
                            ),
                          ),
                          title: Text(
                            videoTitle,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                            ),
                          ),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.chevron_right,
                            color: AppColors.primary,
                            size: 28.r,
                          ),
                          onTap: () => _selectVideo(index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          SizedBox(height: 24.h),
          // Video Material Section (for currently selected video) - moved to bottom
          if (currentVideoMaterial != null && currentVideoMaterial.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24.r),
                  SizedBox(width: 8.w),
                  Text(
                    'VIDEO MATERIAL',
                    style: AppTextStyles.headline2.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                elevation: 2,
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: AppColors.divider, width: 1.r),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  leading: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24.r),
                  ),
                  title: Text(
                    currentVideoMaterialName ?? 'Video Material',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Row(
                      children: [
                        Icon(Icons.video_library, size: 14.r, color: AppColors.textSecondary),
                        SizedBox(width: 4.w),
                        Expanded(
                                child: Text(
                                  'Material for: ${useApiVideos ? (currentCourseVideo?.name ?? 'Current Video') : 'Current Video'}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20.r),
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
            SizedBox(height: 8.h),
          ],
          // MCQs Section - moved to bottom
          if (hasMcqs) ...[
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: AppColors.accent, size: 24.r),
                  SizedBox(width: 8.w),
                  Text(
                    'MCQ',
                    style: AppTextStyles.headline2.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lessonMcqs.length > 1)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        '${lessonMcqs.length} MCQs available',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ...lessonMcqs.map((mcq) {
                    final fullUrl = MaterialService.getFullMaterialUrl(mcq.url);
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      elevation: 2,
                      shadowColor: AppColors.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: AppColors.divider, width: 1.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        leading: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.quiz, color: AppColors.accent, size: 24.r),
                        ),
                        title: Text(
                          mcq.videoName,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              Icon(Icons.video_library, size: 14.r, color: AppColors.textSecondary),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  'MCQ for: ${mcq.videoName}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20.r),
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
                              SnackBar(
                                content: const Text('MCQ URL is not available'),
                                backgroundColor: AppColors.error,
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
            SizedBox(height: 8.h),
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

