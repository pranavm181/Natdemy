import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../data/auth_helper.dart';
import '../api/auth_service.dart';
import '../widgets/theme_loading_indicator.dart';
import '../utils/animations.dart';
import 'home.dart';
import 'signupscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    
    try {
      final authResult = await AuthService.login(email: email, password: password);

      await AuthHelper.saveLoginData(authResult.student, token: authResult.token);

      // Courses will be loaded only when My Courses page is opened
      // This speeds up login significantly

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeShell(student: authResult.student),
        ),
      );
    } on AuthException catch (e) {
      debugPrint('AuthException during login: ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign in. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: AppAnimations.scaleIn(
                  delay: 100,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      side: const BorderSide(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAnimations.fadeIn(
                            delay: 150,
                            child: Image.asset(
                              'assets/images/natdemy_logo2.png',
                              height: 80.h,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.school_outlined,
                                  size: 56.r,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg.h),
                          Text(
                            'WELCOME BACK',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headline2,
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          Text(
                            'Sign in to continue your learning journey',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xl.h),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.body1,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: AppTextStyles.body1,
                            onSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg.h),
                          SizedBox(
                            height: 52.h,
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _signIn,
                              icon: _isLoading
                                  ? Padding(
                                      padding: EdgeInsets.all(8.0.r),
                                      child: const ThemePulsingDotsIndicator(size: 8.0, spacing: 6.0, color: Colors.white),
                                    )
                                  : Icon(Icons.login, size: 20.r),
                              label: Text(
                                'Sign in',
                                style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "Don't have an account? ",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body1.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                ),
                                child: Text(
                                  'Sign up',
                                  style: AppTextStyles.body1.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
