import 'material.dart';

// Legacy PdfMaterial class - kept for backward compatibility
// Use CourseMaterial from material.dart for API data
class PdfMaterial {
  const PdfMaterial({required this.name, required this.url, required this.sizeLabel});
  final String name;
  final String url;
  final String sizeLabel;
  
  // Convert from API CourseMaterial
  factory PdfMaterial.fromMaterial(CourseMaterial material) {
    return PdfMaterial(
      name: material.name,
      url: material.url,
      sizeLabel: material.sizeLabel ?? 'Unknown size',
    );
  }
}

Map<String, List<PdfMaterial>> courseMaterials = {
  'Flutter Basics': const [
    PdfMaterial(name: 'Flutter Widgets Guide', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '1.2 MB'),
    PdfMaterial(name: 'Layouts Handbook', url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', sizeLabel: '900 KB'),
    PdfMaterial(name: 'State Management Basics', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '800 KB'),
  ],
  'Data Structures': const [
    PdfMaterial(name: 'Trees & Graphs', url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', sizeLabel: '2.1 MB'),
    PdfMaterial(name: 'Complexities Cheatsheet', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '450 KB'),
    PdfMaterial(name: 'Algorithms Overview', url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', sizeLabel: '1.5 MB'),
  ],
  'Algebra Refresher': const [
    PdfMaterial(name: 'Equations Workbook', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '700 KB'),
    PdfMaterial(name: 'Functions Guide', url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', sizeLabel: '600 KB'),
  ],
  'Biology Insights': const [
    PdfMaterial(name: 'Cell Biology Notes', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '1.1 MB'),
    PdfMaterial(name: 'Genetics Handbook', url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', sizeLabel: '950 KB'),
  ],
};

List<PdfMaterial> getMaterialsForCourse(String courseTitle) {
  return courseMaterials[courseTitle] ?? const [
    PdfMaterial(name: 'Course Notes', url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', sizeLabel: '700 KB'),
  ];
}


