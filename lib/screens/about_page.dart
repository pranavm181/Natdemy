import 'package:flutter/material.dart';
import '../api/contact_service.dart';
import 'package:flutter/cupertino.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black,
        ),
        title: const Text(
          'ABOUT NATDEMY',
          style: TextStyle(
            color: Color(0xFF582DB0),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Logo Section
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/natdemy_logo2.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        size: 80,
                        color: Color(0xFF582DB0),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NATDEMY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF582DB0),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Any Time Any Where',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // About Section
            _buildSectionTitle('ABOUT US'),
            const SizedBox(height: 16),
            _buildSectionContent(
              'NATDEMY is a comprehensive online learning platform designed to make education accessible to everyone, anytime and anywhere. We provide high-quality courses across various subjects, from technology and programming to science and mathematics.',
            ),

            const SizedBox(height: 40),

            // Mission Section
            _buildSectionTitle('OUR MISSION'),
            const SizedBox(height: 16),
            _buildSectionContent(
              'To democratize education by providing accessible, affordable, and high-quality learning experiences that empower students to achieve their academic and professional goals.',
            ),

            const SizedBox(height: 40),

            // Vision Section
            _buildSectionTitle('OUR VISION'),
            const SizedBox(height: 16),
            _buildSectionContent(
              'To become the leading online learning platform that transforms how people learn, making education accessible to millions of learners worldwide.',
            ),

            const SizedBox(height: 40),

            // Features Section
            _buildSectionTitle('KEY FEATURES'),
            const SizedBox(height: 20),
            _buildFeaturesSection(),

            const SizedBox(height: 40),

            // Contact Section
            _buildSectionTitle('CONTACT US'),
            const SizedBox(height: 20),
            _buildContactSection(),

            const SizedBox(height: 32),

            // Version Info
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF000000),
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
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16,
        height: 1.8,
        color: Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'icon': Icons.access_time, 'title': 'Learn Anytime', 'desc': 'Access courses 24/7'},
      {'icon': Icons.location_on, 'title': 'Learn Anywhere', 'desc': 'Study from any location'},
      {'icon': Icons.video_library, 'title': 'Expert Instructors', 'desc': 'Learn from industry experts'},
      {'icon': Icons.assignment, 'title': 'Course Materials', 'desc': 'Comprehensive resources'},
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < features.length - 1 ? 20 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  feature['icon'] as IconData,
                  color: const Color(0xFFA1C95C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactSection() {
    return FutureBuilder(
      future: ContactService.getContactInfo(),
      builder: (context, snapshot) {
        final contactInfo = snapshot.data ?? ContactInfo.getDefault();
        
        return Column(
          children: [
            if (contactInfo.email != null)
              _buildContactItem(Icons.email, 'Email', contactInfo.email!),
            if (contactInfo.email != null) const SizedBox(height: 20),
            if (contactInfo.phone != null)
              _buildContactItem(Icons.phone, 'Phone', contactInfo.phone!),
            if (contactInfo.phone != null) const SizedBox(height: 20),
            if (contactInfo.website != null)
              _buildContactItem(Icons.language, 'Website', contactInfo.website!),
          ],
        );
      },
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            color: const Color(0xFFA1C95C),
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

