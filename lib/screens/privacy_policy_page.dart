import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/animations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'PRIVACY POLICY',
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
              // Header
              Text(
                'Privacy Policy',
                style: AppTextStyles.headline1.copyWith(
                  fontSize: 28.sp,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5.w,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 40.h),

              // Introduction
              _buildSectionTitle('INTRODUCTION'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'NATDEMY ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
              ),

              const SizedBox(height: 40),

              // Information We Collect
              _buildSectionTitle('INFORMATION WE COLLECT'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We collect information that you provide directly to us, including:\n\n'
                '• Personal Information: Name, email address, phone number\n'
                '• Account Information: Username, password, profile picture\n'
                '• Learning Data: Course progress, quiz results, assignments\n'
                '• Device Information: Device type, operating system, unique device identifiers\n'
                '• Usage Data: How you interact with our app, features used, time spent',
              ),

              const SizedBox(height: 40),

              // How We Use Your Information
              _buildSectionTitle('HOW WE USE YOUR INFORMATION'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We use the information we collect to:\n\n'
                '• Provide, maintain, and improve our services\n'
                '• Process your transactions and send related information\n'
                '• Send you technical notices and support messages\n'
                '• Respond to your comments and questions\n'
                '• Monitor and analyze trends and usage\n'
                '• Personalize your learning experience\n'
                '• Detect, prevent, and address technical issues',
              ),

              const SizedBox(height: 40),

              // Information Sharing
              _buildSectionTitle('INFORMATION SHARING AND DISCLOSURE'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
                '• With your consent\n'
                '• To comply with legal obligations\n'
                '• To protect our rights and safety\n'
                '• With service providers who assist us in operating our app\n'
                '• In connection with a business transfer',
              ),

              const SizedBox(height: 40),

              // Data Security
              _buildSectionTitle('DATA SECURITY'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
              ),

              const SizedBox(height: 40),

              // Your Rights
              _buildSectionTitle('YOUR RIGHTS'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'You have the right to:\n\n'
                '• Access and receive a copy of your personal data\n'
                '• Rectify inaccurate or incomplete information\n'
                '• Request deletion of your personal data\n'
                '• Object to processing of your personal data\n'
                '• Request restriction of processing\n'
                '• Data portability\n'
                '• Withdraw consent at any time',
              ),

              const SizedBox(height: 40),

              // Cookies and Tracking
              _buildSectionTitle('COOKIES AND TRACKING TECHNOLOGIES'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We use cookies and similar tracking technologies to track activity on our app and hold certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
              ),

              const SizedBox(height: 40),

              // Children's Privacy
              _buildSectionTitle("CHILDREN'S PRIVACY"),
              const SizedBox(height: 16),
              _buildSectionContent(
                'Our services are not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
              ),

              const SizedBox(height: 40),

              // Changes to Policy
              _buildSectionTitle('CHANGES TO THIS PRIVACY POLICY'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
              ),

              const SizedBox(height: 40),

              // Contact Us
              _buildSectionTitle('CONTACT US'),
              const SizedBox(height: 16),
              _buildSectionContent(
                'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                'Email: privacy@natdemy.com\n'
                'Phone: +1 (555) 123-4567\n'
                'Address: 123 Education Street, Learning City, LC 12345',
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
}

