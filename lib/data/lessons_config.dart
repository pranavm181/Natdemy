Map<String, List<String>> chapterLessons = {
  'Intro to Flutter': const [
    'Introduction to Flutter',
    'Setting up Development Environment',
    'Your First Flutter App',
    'Understanding Widgets',
  ],
  'Layouts & Widgets': const [
    'Layout Basics',
    'Row and Column Widgets',
    'Container and Padding',
    'Flexible Layouts',
  ],
  'State Management Basics': const [
    'Understanding State',
    'setState() Method',
    'StatefulWidget Deep Dive',
    'State Best Practices',
  ],
  'Navigation': const [
    'Navigator Basics',
    'Routes and Named Routes',
    'Passing Data Between Screens',
    'Bottom Navigation',
  ],
  'Arrays & Lists': const [
    'Array Fundamentals',
    'List Operations',
    'Searching and Sorting',
    'Array Algorithms',
  ],
  'Stacks & Queues': const [
    'Stack Data Structure',
    'Queue Data Structure',
    'Implementations',
    'Real-world Applications',
  ],
  'Trees': const [
    'Tree Basics',
    'Binary Trees',
    'Tree Traversal',
    'BST Operations',
  ],
  'Graphs': const [
    'Graph Fundamentals',
    'Graph Representations',
    'DFS and BFS',
    'Shortest Path Algorithms',
  ],
  'Linear Equations': const [
    'Solving Linear Equations',
    'Systems of Equations',
    'Graphical Methods',
    'Word Problems',
  ],
  'Functions': const [
    'Function Basics',
    'Domain and Range',
    'Graphing Functions',
    'Function Operations',
  ],
  'Quadratics': const [
    'Quadratic Equations',
    'Factoring Methods',
    'Quadratic Formula',
    'Graphing Parabolas',
  ],
  'Inequalities': const [
    'Solving Inequalities',
    'Linear Inequalities',
    'Quadratic Inequalities',
    'Systems of Inequalities',
  ],
  'Cell Structure': const [
    'Cell Organelles',
    'Cell Membrane',
    'Cell Division',
    'Cellular Processes',
  ],
  'Genetics': const [
    'DNA Structure',
    'Genes and Chromosomes',
    'Mendelian Genetics',
    'Genetic Inheritance',
  ],
  'Evolution': const [
    'Natural Selection',
    'Speciation',
    'Evidence of Evolution',
    'Evolutionary Mechanisms',
  ],
  'Ecosystems': const [
    'Ecosystem Components',
    'Food Chains and Webs',
    'Energy Flow',
    'Ecological Relationships',
  ],
};

List<String> getLessonsForChapter(String chapter) {
  return chapterLessons[chapter] ?? [
    '$chapter - Lesson 1',
    '$chapter - Lesson 2',
    '$chapter - Lesson 3',
    '$chapter - Lesson 4',
  ];
}


