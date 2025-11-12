class LessonVideo {
  const LessonVideo({required this.name, required this.vimeoId});
  final String name;
  final String vimeoId; // Vimeo video ID (the number in the URL, e.g., vimeo.com/123456789 -> 123456789)
}

Map<String, List<LessonVideo>> lessonVideosMap = {
  'Introduction to Flutter': const [
    LessonVideo(name: 'Video 1: What is Flutter?', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Flutter Architecture', vimeoId: '357274789'),
    LessonVideo(name: 'Video 3: Your First App', vimeoId: '357274789'),
  ],
  'Setting up Development Environment': const [
    LessonVideo(name: 'Video 1: Installation Guide', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: IDE Setup', vimeoId: '357274789'),
    LessonVideo(name: 'Video 3: First Run', vimeoId: '357274789'),
  ],
  'Your First Flutter App': const [
    LessonVideo(name: 'Video 1: Creating a Project', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Running the App', vimeoId: '357274789'),
  ],
  'Understanding Widgets': const [
    LessonVideo(name: 'Video 1: Widget Basics', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Stateless vs Stateful', vimeoId: '357274789'),
  ],
  'Layout Basics': const [
    LessonVideo(name: 'Video 1: Layout Introduction', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Common Layouts', vimeoId: '357274789'),
  ],
  'Row and Column Widgets': const [
    LessonVideo(name: 'Video 1: Row Widget', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Column Widget', vimeoId: '357274789'),
  ],
  'Container and Padding': const [
    LessonVideo(name: 'Video 1: Container Widget', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Padding and Margin', vimeoId: '357274789'),
  ],
  'Flexible Layouts': const [
    LessonVideo(name: 'Video 1: Flexible Widgets', vimeoId: '357274789'),
  ],
  'Understanding State': const [
    LessonVideo(name: 'Video 1: State Concepts', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: State Management', vimeoId: '357274789'),
  ],
  'setState() Method': const [
    LessonVideo(name: 'Video 1: Using setState', vimeoId: '357274789'),
  ],
  'StatefulWidget Deep Dive': const [
    LessonVideo(name: 'Video 1: StatefulWidget Basics', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Lifecycle Methods', vimeoId: '357274789'),
  ],
  'State Best Practices': const [
    LessonVideo(name: 'Video 1: Best Practices', vimeoId: '357274789'),
  ],
  'Navigator Basics': const [
    LessonVideo(name: 'Video 1: Navigation Introduction', vimeoId: '357274789'),
    LessonVideo(name: 'Video 2: Basic Navigation', vimeoId: '357274789'),
  ],
  'Routes and Named Routes': const [
    LessonVideo(name: 'Video 1: Named Routes', vimeoId: '357274789'),
  ],
  'Passing Data Between Screens': const [
    LessonVideo(name: 'Video 1: Passing Arguments', vimeoId: '357274789'),
  ],
  'Bottom Navigation': const [
    LessonVideo(name: 'Video 1: Bottom Nav Bar', vimeoId: '357274789'),
  ],
};

List<LessonVideo> getVideosForLesson(String lessonName) {
  return lessonVideosMap[lessonName] ?? const [
    LessonVideo(name: 'Video 1', vimeoId: '357274789'),
  ];
}

Map<String, String> lessonMaterialsMap = {
  'Introduction to Flutter': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  'Setting up Development Environment': 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
  'Your First Flutter App': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  'Understanding Widgets': 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
};

String? getMaterialForLesson(String lessonName) {
  return lessonMaterialsMap[lessonName];
}

