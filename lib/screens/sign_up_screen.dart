// lib/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../main.dart'; // Import main.dart for gradient and colors

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your KYC document')));
      return; 
    }

    setState(() => _loading = true);
    try {
      final userCredential = await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
      );

      String? kycFileUrl;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('kyc_documents/${userCredential.user!.uid}/${_pickedFile!.name}');
      final fileToUpload = File(_pickedFile!.path!);
      await storageRef.putFile(fileToUpload);
      kycFileUrl = await storageRef.getDownloadURL();

      await _auth.updateTherapistKycUrl(
        uid: userCredential.user!.uid,
        kycUrl: kycFileUrl,
      );
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/await-approval', (_) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent. Please verify.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- VALIDATION FUNCTIONS ---
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full Name is required';
    final cleanedValue = value.trim();
    if (cleanedValue.length < 3) return 'Name must be at least 3 characters';
    const pattern = r"^[a-zA-Z\s'-]+$";
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(cleanedValue)) return 'Name can only contain letters, spaces, hyphens, or apostrophes.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; 
    final cleanedValue = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    const pattern = r'^(?:\+91)?[0-9]{10}$'; 
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(cleanedValue)) return 'Enter a valid 10-digit Indian phone number (e.g., 9876543210 or +919876543210)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: softBackgroundBlue,
      body: Stack(
        children: [
          // --- Gradient Header Background ---
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              gradient: mainAppGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          // --- Custom AppBar (for Gradient Header) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              // FIX: Explicitly set leading widget for tappability
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context), 
                color: theme.surface,
              ),
              title: Text(
                'Create Therapist Account', 
                style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                      color: theme.surface,
                    ),
              ),
            ),
          ),

          // --- Content Overlaid ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80), // Space to clear the AppBar
                  Text(
                    'Professional Registration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.surface, 
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please provide your details and upload your KYC documents for approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.surface.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 60), 
                  
                  // --- Sign Up Card (Floating Container) ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 3,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField.validated(controller: _fullName, hint: 'Full Name', validator: _validateFullName),
                          const SizedBox(height: 16),
                          AppTextField.validated(controller: _email, hint: 'Email', validator: _validateEmail, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          AppTextField.validated(controller: _phone, hint: 'Phone (optional, 10 digits)', validator: _validatePhone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          AppTextField.validated(controller: _password, hint: 'Password (min 8 chars)', obscure: true, validator: _validatePassword),
                          const SizedBox(height: 16),
                          AppTextField.validated(
                            controller: _confirm, 
                            hint: 'Confirm Password', 
                            obscure: true,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirm password is required';
                              if (val != _password.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // --- KYC Upload Section ---
                          Container(
                            decoration: BoxDecoration(
                              color: theme.surface, 
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.outlineVariant), 
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: OutlinedButton.icon(
                              icon: Icon(_pickedFile == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline, 
                                         color: _pickedFile == null ? theme.primary : secondaryGreenGradientEnd), 
                              label: Text(_pickedFile == null ? 'Upload KYC Documents' : 'File Selected: ${_pickedFile!.name}',
                                          style: TextStyle(color: _pickedFile == null ? theme.primary : secondaryGreenGradientEnd, fontWeight: FontWeight.w500)),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
                                );
                                if (result != null) {
                                  setState(() {
                                    _pickedFile = result.files.first;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('File selected: ${_pickedFile!.name}')),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                side: BorderSide.none, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // --- Sign Up Button ---
                          AppButton(
                            label: _loading ? 'Please wait…' : 'Submit for Approval', 
                            onPressed: _loading ? null : _signUp
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}