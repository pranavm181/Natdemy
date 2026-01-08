import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/course_catalog.dart';
import '../utils/course_utils.dart';
import '../api/contact_service.dart';
import '../api/course_service.dart';
import '../widgets/rating_stars.dart';
import '../data/course_stream.dart';
import '../utils/animations.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key, required this.course});

  final Course course;

  // Get icon for stream based on stream name or index
  IconData _getStreamIcon(String streamName, int index) {
    final nameLower = streamName.toLowerCase();
    
    // Check stream name for keywords
    if (nameLower.contains('science') || nameLower.contains('physics') || nameLower.contains('chemistry') || nameLower.contains('biology')) {
      return Icons.science;
    } else if (nameLower.contains('math') || nameLower.contains('mathematics')) {
      return Icons.calculate;
    } else if (nameLower.contains('english') || nameLower.contains('language')) {
      return Icons.menu_book;
    } else if (nameLower.contains('computer') || nameLower.contains('programming') || nameLower.contains('coding')) {
      return Icons.computer;
    } else if (nameLower.contains('commerce') || nameLower.contains('business') || nameLower.contains('accounting')) {
      return Icons.account_balance;
    } else if (nameLower.contains('arts') || nameLower.contains('history') || nameLower.contains('geography')) {
      return Icons.palette;
    } else if (nameLower.contains('medical') || nameLower.contains('health')) {
      return Icons.medical_services;
    } else if (nameLower.contains('engineering') || nameLower.contains('tech')) {
      return Icons.engineering;
    } else if (nameLower.contains('law') || nameLower.contains('legal')) {
      return Icons.gavel;
    } else if (nameLower.contains('management') || nameLower.contains('mba')) {
      return Icons.business_center;
    }
    
    // Default icons based on index if no keyword matches
    final defaultIcons = [
      Icons.stream,
      Icons.school,
      Icons.library_books,
      Icons.auto_stories,
      Icons.workspace_premium,
      Icons.rocket_launch,
      Icons.lightbulb,
      Icons.trending_up,
    ];
    
    return defaultIcons[index % defaultIcons.length];
  }


  @override
  Widget build(BuildContext context) {
    final relatedStreams = CourseService.cachedStreams
        .where((stream) {
          // Check multiple ways course_id might be stored
          if (stream.resolvedCourseId == course.id) {
            return true;
          }
          if (stream.courseId == course.id) {
            return true;
          }
          if (stream.course?.id == course.id) {
            return true;
          }
          return false;
        })
        .toList();

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
          'COURSE DETAILS',
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
        child: Column(
          children: [
            AppAnimations.scaleIn(
              delay: 150,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF582DB0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: CourseService.getFullImageUrl(course.thumbnailUrl),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) {
                                    return Icon(
                                      CourseUtils.getCourseIcon(course.title),
                                      color: const Color(0xFF000000),
                                      size: 48,
                                    );
                                  },
                                  memCacheWidth: 128,
                                  memCacheHeight: 128,
                                ),
                              )
                            : Icon(
                                CourseUtils.getCourseIcon(course.title),
                                color: const Color(0xFF000000),
                                size: 48,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          course.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        RatingStars(
                          rating: course.rating,
                          textStyle: const TextStyle(
                            color: Color(0xFF582DB0),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ABOUT THIS COURSE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF000000),
                              fontSize: 24,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF582DB0), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    course.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF1E293B),
                          height: 1.8,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 40),
                  if (relatedStreams.isNotEmpty) ...[
                    Text(
                      'COURSE STREAMS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF000000),
                            fontSize: 24,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedStreams.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final stream = relatedStreams[index];
                          final streamCourse = stream.course ?? course;
                          final streamIcon = _getStreamIcon(stream.name, index);

                          return AnimatedListItem(
                            index: index,
                            child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF582DB0), width: 2),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF582DB0).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          streamIcon,
                                          color: const Color(0xFF582DB0),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          streamCourse?.title ?? course.title,
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                        Text(
                                          stream.name,
                                          style: const TextStyle(
                                            color: Color(0xFF582DB0),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                    maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.people,
                            course.studentCount != null
                                ? course.studentCount! >= 1000
                                    ? '${(course.studentCount! / 1000).toStringAsFixed(1)}K+'
                                    : '${course.studentCount}+'
                                : '0',
                            'Students',
                          ),
                          _buildStatItem(
                            Icons.access_time,
                            course.durationHours != null
                                ? '${(course.durationHours! / 160).round()} months'
                                : course.duration != null
                                    ? '${(course.duration! / 160).round()} months'
                                    : '0 months',
                            'Duration',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: FutureBuilder(
                future: ContactService.getContactInfo(),
                builder: (context, snapshot) {
                  final contactInfo = snapshot.data ?? ContactInfo.getDefault();
                  final whatsappNum = _resolveCourseWhatsAppNumber(course, contactInfo);
                  final displayNumber = _formatWhatsAppDisplay(whatsappNum);
                  final supportLabel = _resolveCourseSupportLabel(course);

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!context.mounted) return;
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetContext) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFF582DB0),
                                      width: 2,
                                    ),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF5F0FF),
                                        Color(0xFFFFFFFF),
                                      ],
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33582DB0),
                                        blurRadius: 24,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 48,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFBFA5ED),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF4D23AA),
                                                    Color(0xFF6435C8),
                                                  ],
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x40582DB0),
                                                    blurRadius: 20,
                                                    offset: Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.headset_mic,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Need help with this course?',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF582DB0),
                                                    ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Text(
                                                    'Our team is ready on WhatsApp or call to answer any questions.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      height: 1.5,
                                                      color: Color(0xFF4C3B82),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, color: Color(0xFF582DB0)),
                                              tooltip: 'Close',
                                              onPressed: () => Navigator.of(sheetContext).pop(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0E8FF),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: const Color(0xFFD4C6FF),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.school_rounded,
                                                color: Color(0xFF582DB0),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Course: ${course.title}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF452D8A),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F9ED),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: const Color(0xFFBFEFCF),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.phone_android,
                                                color: Color(0xFF25D366),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    supportLabel,
                                                    style: const TextStyle(
                                                      color: Color(0xFF452D8A),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    displayNumber,
                                                    style: const TextStyle(
                                                      color: Color(0xFF111827),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF25D366),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 4,
                                            ),
                                            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                                            label: Text(
                                              'WhatsApp ($displayNumber)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final uri = Uri.parse(
                                                'https://wa.me/$whatsappNum?text=${Uri.encodeComponent('I have a question about ${course.title}')}',
                                              );
                                              Navigator.of(sheetContext).pop();
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFFE0D2FF),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEE4FF),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.info_outline,
                                                  color: Color(0xFF582DB0),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: const [
                                                    Text(
                                                      'Service Hours',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF452D8A),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Mon - Sat · 9:00 AM to 6:00 PM',
                                                      style: TextStyle(
                                                        color: Color(0xFF5B4A9B),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.headset_mic, size: 20),
                      label: const Text(
                        'Contact',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Color(0xFF582DB0), width: 2),
                        foregroundColor: const Color(0xFF582DB0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF582DB0), size: 32),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  String _resolveCourseWhatsAppNumber(Course course, ContactInfo contactInfo) {
    final title = course.title.toLowerCase();
    if (title.contains('nios')) {
      return '919207666621';
    }
    if (title.contains('bosse')) {
      return '919207666623';
    }
    if (title.contains('gmvss') || title.contains('gmv')) {
      return '919207666628';
    }
    final fallback = contactInfo.whatsappNumber ??
        contactInfo.phone ??
        '+91 92076 666621';
    return _sanitizeWhatsappDigits(fallback);
  }

  String _sanitizeWhatsappDigits(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '919207666621';
    if (digits.startsWith('91')) return digits;
    return '91$digits';
  }

  String _formatWhatsAppDisplay(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('91') && cleaned.length > 2) {
      final local = cleaned.substring(2);
      if (local.length > 5) {
        final first = local.substring(0, 5);
        final second = local.substring(5);
        return '+91 $first $second';
      }
      return '+91 $local';
    }
    if (cleaned.isNotEmpty) {
      return '+$cleaned';
    }
    return '+91 92076 66621';
  }

  String _resolveCourseSupportLabel(Course course) {
    final title = course.title.toLowerCase();
    if (title.contains('nios')) {
      return 'NIOS Support';
    }
    if (title.contains('bosse')) {
      return 'BOSSE Support';
    }
    if (title.contains('gmvss') || title.contains('gmv')) {
      return 'GMVSS Support';
    }
    return 'Course Support';
  }
}

