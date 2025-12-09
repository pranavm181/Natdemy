import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/student.dart';
import 'loginscreen.dart';
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key, required this.student});

  final Student student;

  List<ClassItem> _mockAssignedClasses(Student student) {
    return [
      ClassItem(
        title: 'Algebra I - Quadratic Functions',
        teacher: 'Ms. Rivera',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        videoUrl: 'https://www.youtube.com/watch?v=ZK3O402wf1c',
        thumbnailUrl: 'https://img.youtube.com/vi/ZK3O402wf1c/hqdefault.jpg',
      ),
      ClassItem(
        title: 'Biology - Cell Structure',
        teacher: 'Dr. Chen',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        videoUrl: 'https://www.youtube.com/watch?v=URUJD5NEXC8',
        thumbnailUrl: 'https://img.youtube.com/vi/URUJD5NEXC8/hqdefault.jpg',
      ),
      ClassItem(
        title: 'History - World War II Overview',
        teacher: 'Mr. Patel',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        videoUrl: 'https://www.youtube.com/watch?v=HUqy-OQvVtI',
        thumbnailUrl: 'https://img.youtube.com/vi/HUqy-OQvVtI/hqdefault.jpg',
      ),
    ];
  }

  Future<void> _watch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _mockAssignedClasses(student);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY CLASSES'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () => _watch(context, item.videoUrl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 360 ? 100 : 140,
                    height: 90,
                    child: Ink.image(
                      image: NetworkImage(item.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.teacher,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(item.startTime),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              FilledButton(
                                onPressed: () => _watch(context, item.videoUrl),
                                child: const Text('Watch'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}