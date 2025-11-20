// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import '../app_router.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../main.dart'; // Import main.dart for gradient and colors
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // --- Login Logic (Unchanged from last step) ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    UserCredential? userCredential;

    try {
      userCredential = await _auth.signIn(_email.text.trim(), _password.text);
      final user = userCredential.user;

      if (user != null && mounted) {
        final therapistDoc = await FirebaseFirestore.instance
            .collection('therapists')
            .doc(user.uid)
            .get();
        
        final status = therapistDoc.data()?['status'];

        if (status == "approved") {
          Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (_) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, Routes.awaitApproval, (_) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  // --- Validation Functions (Unchanged) ---
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
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
          // --- Gradient Header Background (UI) ---
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: mainAppGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          // --- Content Overlaid on Gradient (UI) ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Branding/Welcome Text on Gradient ---
                    const SizedBox(height: 30),
                    Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.surface, 
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.surface.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // --- Login Card (UI) ---
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
                      child: Column(
                        children: [
                          AppTextField.validated(
                            controller: _email, 
                            hint: 'Email Address', 
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          AppTextField.validated(
                            controller: _password, 
                            hint: 'Password', 
                            obscure: true,
                            validator: _validatePassword,
                          ),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                // --- FIX: Validation check before proceeding ---
                                final validationMessage = _validateEmail(_email.text);
                                
                                if (validationMessage != null) {
                                  // Show specific error message for invalid email format
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(validationMessage)),
                                  );
                                  return;
                                }
                                // ---------------------------------------------
                                
                                try {
                                  await _auth.resetPassword(_email.text.trim());
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(color: theme.primary),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          AppButton(
                            label: _loading ? 'Logging in…' : 'Log in', 
                            onPressed: _loading ? null : _login
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.outlineVariant)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: theme.outline)),
                              ),
                              Expanded(child: Divider(color: theme.outlineVariant)),
                            ],
                          ),
                          
                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, Routes.signUp),
                            child: Text(
                              'Create a new account',
                              style: TextStyle(color: theme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}