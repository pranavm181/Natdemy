import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../api/contact_service.dart';
import 'package:flutter/cupertino.dart';
import '../utils/animations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'ABOUT NATDEMY',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: AppAnimations.fadeSlideIn(
        delay: 100,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // Logo Section
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/natdemy_logo2.png',
                      width: 100.r,
                      height: 100.r,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.school,
                          size: 80.r,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'NATDEMY',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 32.sp,
                        color: AppColors.primary,
                        letterSpacing: 1.2.w,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Any Time Any Where',
                      style: AppTextStyles.body1.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5.w,
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headline2.copyWith(
            fontSize: 24.sp,
            color: AppColors.textPrimary,
            letterSpacing: 0.5.w,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 3.h,
          width: 120.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: AppTextStyles.body1.copyWith(
        fontSize: 16.sp,
        height: 1.8,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3.w,
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
          padding: EdgeInsets.only(bottom: index < features.length - 1 ? 20.h : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.accent,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: AppTextStyles.body1.copyWith(
                        fontSize: 16.sp,
                        height: 1.7,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2.w,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      feature['desc'] as String,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: 22.r,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body1.copyWith(
                  fontSize: 16.sp,
                  height: 1.7,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2.w,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

