import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/auth_helper.dart';
import '../data/joined_courses.dart';
import '../data/student.dart';
import '../data/course_catalog.dart';
import '../data/course_stream.dart';
import '../api/auth_service.dart';
import '../api/course_service.dart';
import '../api/student_service.dart';
import '../api/api_client.dart';
import '../widgets/theme_loading_indicator.dart';
import '../utils/animations.dart';
import 'home.dart';
import 'loginscreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingCourses = true;
  
  // Course and Stream Selection
  List<Course> _courses = [];
  List<CourseStream> _streams = [];
  Course? _selectedCourse;
  CourseStream? _selectedStream;

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (phone.isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    if (phone.length < 7) {
      _showError('Phone number must be at least 7 digits.');
      return;
    }
    if (studentId.isEmpty) {
      _showError('Please enter your student ID.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter a password.');
      return;
    }
    if (confirm.isEmpty) {
      _showError('Please confirm your password.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    if (_selectedCourse == null) {
      _showError('Please select a course.');
      return;
    }
    if (_selectedStream == null) {
      _showError('Please select a stream.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Ensure course and stream are selected
      if (_selectedCourse == null || _selectedStream == null) {
        _showError('Please select both course and stream.');
        setState(() => _isLoading = false);
        return;
      }
      
      debugPrint('🚀 Starting registration process...');
      debugPrint('   Name: $name');
      debugPrint('   Email: $email');
      debugPrint('   Phone: $phone');
      debugPrint('   Course ID: ${_selectedCourse!.id}');
      debugPrint('   Stream ID: ${_selectedStream!.id}');
      
      final authResult = await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        studentId: studentId,
        photo: '',
        courseId: _selectedCourse!.id,
        streamId: _selectedStream!.id,
      );
      
      debugPrint('✅ Registration successful! Student data saved to database.');

      final student = authResult.student.studentId != null && authResult.student.studentId!.isNotEmpty
          ? authResult.student
          : Student(
              id: authResult.student.id,
              studentId: studentId,
              name: authResult.student.name,
              email: authResult.student.email,
              phone: authResult.student.phone,
              profileImagePath: authResult.student.profileImagePath,
            );

      // If registration didn't return a token, automatically login to get one
      String token = authResult.token;
      if (token.isEmpty) {
        debugPrint('🔄 Registration successful but no token returned, logging in...');
        try {
          final loginResult = await AuthService.login(email: email, password: password);
          token = loginResult.token;
          debugPrint('✅ Login successful, token obtained');
        } catch (e) {
          debugPrint('⚠️ Auto-login failed after registration: $e');
          // Continue without token - user can login manually later
        }
      }

      await AuthHelper.saveLoginData(student, token: token);

      // Check if student is verified and create enrollment if needed
      try {
        final studentData = await StudentService.fetchStudentDataWithCourseStream(email);
        if (studentData != null) {
          // API uses 'verification' field, but we also check 'verified' for compatibility
          final rawVerified = studentData['verification'] ?? studentData['verified'];
          bool? isVerified;
          if (rawVerified != null) {
            if (rawVerified is bool) {
              isVerified = rawVerified;
            } else if (rawVerified is String) {
              isVerified = rawVerified.toLowerCase() == 'true';
            } else if (rawVerified is int) {
              isVerified = rawVerified == 1;
            }
          }
          
          if (isVerified == true && _selectedCourse != null && _selectedStream != null && student.id != null) {
            debugPrint('🔄 Student is verified, creating enrollment...');
            try {
              await _createEnrollmentForStudent(
                studentId: student.id!,
                courseId: _selectedCourse!.id!,
                streamId: _selectedStream!.id,
                token: token,
              );
              debugPrint('✅ Enrollment created successfully for verified student');
            } catch (e) {
              debugPrint('⚠️ Failed to create enrollment: $e');
              // Continue even if enrollment creation fails
            }
          } else {
            debugPrint('ℹ️ Student not verified yet, enrollment will be created when verified');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error checking verified status: $e');
        // Continue even if check fails
      }

      await JoinedCourses.instance.initialize(student.email, forceRefresh: true);

      if (!mounted) return;

      setState(() => _isLoading = false);
      
      // Show success message confirming data was saved to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to Natdemy.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeShell(student: student),
        ),
      );
    } on AuthException catch (e) {
      debugPrint('AuthException during sign up: ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = 'Unable to sign up. Please try again.';
        
        // Check if it's a CORS/network error
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('failed to fetch') || 
            errorString.contains('cors') ||
            errorString.contains('network') ||
            errorString.contains('clientexception')) {
          errorMessage = 'Network error: Please check your connection or try again later. If using a web browser, the server may need to enable CORS.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _createEnrollmentForStudent({
    required int studentId,
    required int courseId,
    required int streamId,
    required String token,
  }) async {
    try {
      debugPrint('🔄 Creating enrollment for student $studentId, course $courseId, stream $streamId');
      
      final enrollmentData = {
        'student_id': studentId,
        'course_id': courseId,
        'stream_id': streamId,
        'verified': true,
      };
      
      // Try admin endpoint first
      try {
        final adminUri = Uri.parse('${ApiClient.baseUrl}/api/admin/enrollments');
        final adminResponse = await http.post(
          adminUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: json.encode(enrollmentData),
        );
        
        if (adminResponse.statusCode >= 200 && adminResponse.statusCode < 300) {
          debugPrint('✅ Enrollment created via admin endpoint');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Admin enrollment endpoint failed, trying regular endpoint: $e');
      }
      
      // Fallback to regular enrollment endpoint
      final uri = Uri.parse('${ApiClient.baseUrl}/api/enrollments/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode(enrollmentData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Enrollment created successfully');
      } else {
        debugPrint('❌ Failed to create enrollment: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        throw Exception('Failed to create enrollment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error creating enrollment: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCoursesAndStreams();
  }

  Future<void> _loadCoursesAndStreams() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      debugPrint('🔄 Loading courses and streams for signup...');
      final courses = await CourseService.fetchCourses();
      final streams = CourseService.cachedStreams;
      
      debugPrint('✅ Loaded ${courses.length} course(s) and ${streams.length} stream(s)');
      
      setState(() {
        _courses = courses;
        _streams = streams;
        _isLoadingCourses = false;
      });
      
      if (courses.isEmpty) {
        debugPrint('⚠️ No courses available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No courses available. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading courses: $e');
      setState(() {
        _isLoadingCourses = false;
        _courses = [];
        _streams = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load courses: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onCourseSelected(Course? course) {
    setState(() {
      _selectedCourse = course;
      // Filter streams for selected course
      if (course != null && course.id != null) {
        _selectedStream = null; // Reset stream selection
        
        // Filter streams - check multiple ways course_id might be stored
        _streams = CourseService.cachedStreams.where((stream) {
          // Check resolvedCourseId (handles both course?.id and courseId)
          if (stream.resolvedCourseId == course.id) {
            return true;
          }
          
          // Also check direct courseId field
          if (stream.courseId == course.id) {
            return true;
          }
          
          // Also check nested course object ID
          if (stream.course?.id == course.id) {
            return true;
          }
          
          return false;
        }).toList();
      } else {
        _streams = CourseService.cachedStreams;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
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
                      children: [
                        Image.asset(
                          'assets/images/natdemy_logo2.png',
                          height: 80.h,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person_add_outlined,
                              size: 56.r,
                              color: AppColors.primary,
                            );
                          },
                        ),
                        SizedBox(height: AppSpacing.lg.h),
                        Text(
                          'CREATE ACCOUNT',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline2,
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                        Text(
                          'Join us and start learning today',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl.h),
                        TextField(
                          controller: _studentIdController,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.body1,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                            helperText: 'Enter the student ID provided to you',
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.body1,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
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
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.body1,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.body1,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.body1,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg.h),
                        // Course Selection
                        if (_isLoadingCourses)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md.r),
                              child: const ThemePulsingDotsIndicator(size: 10.0, spacing: 12.0),
                            ),
                          )
                        else if (_courses.isEmpty)
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md.r),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                SizedBox(width: AppSpacing.sm.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No courses available',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      TextButton.icon(
                                        onPressed: _loadCoursesAndStreams,
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: const Text('Retry'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<Course>(
                            value: _selectedCourse,
                            style: AppTextStyles.body1,
                            decoration: const InputDecoration(
                              labelText: 'Select Course *',
                              prefixIcon: Icon(Icons.menu_book_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _courses.map((course) {
                              return DropdownMenuItem<Course>(
                                value: course,
                                child: Text(
                                  course.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body1,
                                ),
                              );
                            }).toList(),
                            onChanged: (Course? course) {
                              debugPrint('Course selected: ${course?.title} (ID: ${course?.id})');
                              _onCourseSelected(course);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a course';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          // Stream Selection
                          DropdownButtonFormField<CourseStream>(
                            value: _selectedStream,
                            style: AppTextStyles.body1,
                            decoration: InputDecoration(
                              labelText: 'Select Stream *',
                              prefixIcon: const Icon(Icons.stream),
                              border: const OutlineInputBorder(),
                              enabled: _selectedCourse != null,
                              hintText: _selectedCourse == null 
                                  ? 'Select a course first' 
                                  : _streams.isEmpty 
                                      ? 'No streams available' 
                                      : null,
                            ),
                            items: _streams.isEmpty
                                ? null
                                : _streams.map((stream) {
                                    return DropdownMenuItem<CourseStream>(
                                      value: stream,
                                      child: Text(
                                        stream.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.body1,
                                      ),
                                    );
                                  }).toList(),
                            onChanged: _selectedCourse != null && _streams.isNotEmpty
                                ? (CourseStream? stream) {
                                    debugPrint('Stream selected: ${stream?.name} (ID: ${stream?.id})');
                                    setState(() {
                                      _selectedStream = stream;
                                    });
                                  }
                                : null,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a stream';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.lg.h),
                        ],
                        SizedBox(
                          height: 52.h,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _signUp,
                            icon: _isLoading
                                ? Padding(
                                    padding: EdgeInsets.all(8.0.r),
                                    child: const ThemePulsingDotsIndicator(size: 8.0, spacing: 6.0, color: Colors.white),
                                  )
                                : Icon(Icons.person_add_alt_1, size: 20.r),
                            label: Text(
                              'Sign up',
                              style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              ),
                              child: Text(
                                'Sign in',
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
    );
  }
}


