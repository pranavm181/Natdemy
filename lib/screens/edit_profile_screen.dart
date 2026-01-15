import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../data/student.dart';
import '../data/auth_helper.dart';
import '../utils/image_utils.dart';
import '../utils/file_operations.dart';
import '../utils/animations.dart';
import 'loginscreen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.student, required this.onProfileUpdated});

  final Student student;
  final Function(Student) onProfileUpdated;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _studentIdController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _showChangePasswordSection = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _profileImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController(text: widget.student.studentId ?? '');
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.student.phone);
    _profileImagePath = widget.student.profileImagePath;
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Save to SharedPreferences
    final updatedStudent = Student(
      id: widget.student.id,
      studentId: widget.student.studentId,
      name: name,
      email: email,
      phone: phone,
      profileImagePath: _profileImagePath,
    );
    await AuthHelper.saveLoginData(updatedStudent);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Update parent widget
    widget.onProfileUpdated(updatedStudent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // On web, read as bytes and convert to data URL
          final Uint8List bytes = await pickedFile.readAsBytes();
          final String base64String = base64Encode(bytes);
          final String dataUrl = 'data:image/${pickedFile.name.split('.').last};base64,$base64String';
          
          setState(() {
            _profileImagePath = dataUrl;
          });
        } else {
          // On mobile, save to file system
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = pickedFile.path.contains('.') 
              ? '.${pickedFile.path.split('.').last}' 
              : '.jpg';
          
          // Delete old profile image if exists
          if (_profileImagePath != null && ImageUtils.fileExists(_profileImagePath)) {
            await deleteProfileImage(_profileImagePath);
          }
          
          // Save new image
          final savedPath = await saveProfileImage(
            pickedFile.path,
            widget.student.email,
            timestamp,
            extension,
          );
          
          setState(() {
            _profileImagePath = savedPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    // Simulate password change (in real app, this would call an API)
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isChangingPassword = false);

    if (!mounted) return;

    // Clear password fields
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password changed successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

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
          'EDIT PROFILE',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primary,
            fontSize: 20.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 10.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.primary,
                        backgroundImage: ImageUtils.getProfileImageProvider(_profileImagePath),
                        child: ImageUtils.hasProfileImage(_profileImagePath)
                            ? null
                            : Icon(
                                Icons.person,
                                size: 60.r,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Student ID (read-only)
              TextFormField(
                controller: _studentIdController,
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  hintText: 'Student ID',
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              const SizedBox(height: 20),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Enter your name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'Enter your phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                height: 52.h,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.save, size: 20.r),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Changes',
                    style: AppTextStyles.button.copyWith(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Divider
              const Divider(thickness: 1),
              const SizedBox(height: 24),
              // Change Password Section (collapsible)
              if (!_showChangePasswordSection) ...[
                SizedBox(
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showChangePasswordSection = true;
                      });
                    },
                    icon: Icon(Icons.lock_reset, size: 20.r),
                    label: Text('Change Password', style: AppTextStyles.button.copyWith(fontSize: 16.sp)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary, width: 2.r),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'CHANGE PASSWORD',
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Current Password Field
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Enter your current password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your current password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // New Password Field
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Enter your new password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          hintText: 'Confirm your new password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // Change Password Button
                      SizedBox(
                        height: 52.h,
                        child: OutlinedButton.icon(
                          onPressed: _isChangingPassword ? null : _changePassword,
                          icon: _isChangingPassword
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                )
                              : Icon(Icons.lock_reset, size: 20.r),
                          label: Text(
                            _isChangingPassword ? 'Changing...' : 'Change Password',
                            style: AppTextStyles.button.copyWith(fontSize: 16.sp, color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary, width: 2.r),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showChangePasswordSection = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Delete Account Section
                Center(
                  child: TextButton.icon(
                    onPressed: _showDeleteAccountDialog,
                    icon: Icon(Icons.delete_forever, color: AppColors.error, size: 20.r),
                    label: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            const SizedBox(height: 12),
            Text(
              'All your course progress, certificates, and personal data will be permanently removed.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestAccountDeletion();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _requestAccountDeletion() {
    // Show a message about the process
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletion Request Sent'),
        content: const Text(
          'Your account deletion request has been received. Our team will process it within 48 hours and send a confirmation email to your registered address.',
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Log out the user
              await AuthHelper.clearLoginData();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


