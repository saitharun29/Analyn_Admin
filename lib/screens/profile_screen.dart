// lib/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
// --- NEW IMPORTS for UI ---
import '../main.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
// -------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Validation Key ---
  final _formKey = GlobalKey<FormState>();
  
  // --- Personal Info ---
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // --- Service Info ---
  final List<String> _allServices = [
    'Individual Counseling',
    'Couples Therapy',
    'Child Psychology',
    'Group Therapy',
    'Addiction Counseling',
  ];
  Map<String, bool> _servicesMap = {};

  // --- Availability Info ---
  String _selectedHours = '9:00 AM - 5:00 PM';
  double _maxDistance = 10.0;
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> _selectedDays = [];

  // --- Payout Info ---
  String _stripeAccountId = '';
  bool _payoutsEnabled = false;

  // --- Notification Info ---
  String _fcmTokenStatus = "Disabled";

  // --- Document Info ---
  PlatformFile? _newKycFile;
  String _currentKycDocInfo = "Loading...";

  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTogglingNotifications = false;
  bool _isConnectingStripe = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field
    final cleanedValue = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    const pattern = r'^(?:\+91)?[0-9]{10}$'; 
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(cleanedValue)) return 'Enter a valid 10-digit Indian phone number';
    return null;
  }
  // ----------------------------

  Future<void> _connectStripe() async {
    setState(() => _isConnectingStripe = true);
    try {
      // 1. SIMULATE NETWORK DELAY (Fake loading)
      await Future.delayed(const Duration(seconds: 2));

      // 2. REAL FIREBASE UPDATE
      await FirebaseFirestore.instance
          .collection('therapists')
          .doc(_uid)
          .update({
            'stripeAccountId': 'acct_demo_123456789', // Fake Stripe ID
            'payoutsEnabled': true, // This turns the text GREEN
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stripe account connected successfully! (Demo)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingStripe = false);
    }
  }

  Future<void> _getAndSaveToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('therapists')
          .doc(_uid)
          .update({'fcmToken': token});

      if (mounted) {
        setState(() => _fcmTokenStatus = "Enabled");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications enabled successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get FCM token.')),
        );
      }
    }
  }

  Future<void> _toggleNotifications() async {
    setState(() => _isTogglingNotifications = true);
    try {
      if (_fcmTokenStatus == "Enabled") {
        await FirebaseFirestore.instance.collection('therapists').doc(_uid).update({'fcmToken': FieldValue.delete()});
        await FirebaseMessaging.instance.deleteToken();
        if (mounted) setState(() => _fcmTokenStatus = "Disabled");
      } else {
        await _getAndSaveToken();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isTogglingNotifications = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('therapists').doc(_uid).get();
      final data = doc.data();

      if (data != null) {
        _fullNameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        final servicesFromDb = Map<String, dynamic>.from(data['services'] ?? {});
        _servicesMap = {};
        for (final serviceName in _allServices) {
          _servicesMap[serviceName] = servicesFromDb[serviceName] ?? false;
        }
        _selectedHours = data['workingHours'] ?? _selectedHours;
        _maxDistance = (data['maxDistance'] as num?)?.toDouble() ?? 10.0;
        if (data['availableDays'] != null) {
          _selectedDays = List<String>.from(data['availableDays']);
        }
        
        // Load Payout Info
        _stripeAccountId = data['stripeAccountId'] ?? '';
        _payoutsEnabled = data['payoutsEnabled'] ?? false;

        final fcmToken = data['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          _fcmTokenStatus = "Enabled";
        } else {
          _fcmTokenStatus = "Disabled";
        }
        
        final kycUrl = data['kycDocumentUrl'];
        if (kycUrl != null && (kycUrl as String).isNotEmpty) {
          _currentKycDocInfo = "A document is on file.";
        } else {
          _currentKycDocInfo = "No document submitted.";
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _newKycFile = result.files.first;
        _currentKycDocInfo = "";
      });
    }
  }

  Future<void> _saveChanges() async {
    // RUN VALIDATION
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isSaving = true; });
    try {
      String? newKycFileUrl; 
      if (_newKycFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('kyc_documents/$_uid/${_newKycFile!.name}');
        final fileToUpload = File(_newKycFile!.path!);
        await storageRef.putFile(fileToUpload);
        newKycFileUrl = await storageRef.getDownloadURL();
      }

      final Map<String, dynamic> dataToUpdate = {
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'services': _servicesMap,
        'workingHours': _selectedHours, 
        'availableDays': _selectedDays, 
        'maxDistance': _maxDistance,  // FIX: Removed illegal non-ASCII space character here
      };

      if (newKycFileUrl != null) dataToUpdate['kycDocumentUrl'] = newKycFileUrl;

      await FirebaseFirestore.instance.collection('therapists').doc(_uid).update(dataToUpdate);

      if (newKycFileUrl != null) {
        setState(() {
          _newKycFile = null;
          _currentKycDocInfo = "A new document has been saved.";
        });
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ----------------------------------------
  // UI HELPER FUNCTIONS for Floating Cards
  // ----------------------------------------
  
  // Helper to create the floating card container
  Widget _buildInfoCard({required String title, required List<Widget> children, required ColorScheme theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.onSurface,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Helper for displaying simple info rows (used for hours/distance status)
  Widget _buildInfoRow(String label, Widget child, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500)),
          child,
        ],
      ),
    );
  }

  // ----------------------------------------
  //              BUILD METHOD
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: softBackgroundBlue,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. PERSONAL INFO CARD (Uses AppTextField.validated)
                    _buildInfoCard(
                      theme: theme,
                      title: 'Personal Info',
                      children: [
                        AppTextField.validated(
                          controller: _fullNameController,
                          hint: 'Full Name',
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: 16),
                        AppTextField.validated(
                          controller: _phoneController,
                          hint: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                      ],
                    ),

                    // 2. AVAILABILITY & RADIUS CARD
                    _buildInfoCard(
                      theme: theme,
                      title: 'Availability & Radius',
                      children: [
                        // Working Hours Dropdown
                        _buildInfoRow(
                          'Working Hours:',
                          DropdownButton<String>(
                            value: _selectedHours,
                            items: const [
                              DropdownMenuItem(value: '9:00 AM - 5:00 PM', child: Text('9:00 AM - 5:00 PM')),
                              DropdownMenuItem(value: '10:00 AM - 7:00 PM', child: Text('10:00 AM - 7:00 PM')),
                              DropdownMenuItem(value: '1:00 PM - 9:00 PM', child: Text('1:00 PM - 9:00 PM')),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() { _selectedHours = newValue; });
                            },
                            style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                            icon: Icon(Icons.arrow_drop_down, color: theme.primary),
                          ),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        
                        // Available Days Chips
                        const Text('Available Days:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: _daysOfWeek.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDays.add(day);
                                  } else {
                                    _selectedDays.remove(day);
                                  }
                                });
                              },
                              backgroundColor: theme.outlineVariant.withOpacity(0.5),
                              selectedColor: theme.primary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? theme.primary : theme.onSurface.withOpacity(0.7),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              checkmarkColor: theme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Max Distance Slider
                        Text('Max Travel Distance: ${_maxDistance.round()} km', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.onSurface)),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: theme.primary,
                            inactiveTrackColor: theme.outlineVariant,
                            thumbColor: theme.primary,
                            overlayColor: theme.primary.withOpacity(0.2),
                            valueIndicatorColor: theme.primary,
                            valueIndicatorTextStyle: TextStyle(color: theme.onPrimary),
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          ),
                          child: Slider(
                            value: _maxDistance, 
                            min: 5, 
                            max: 100, 
                            divisions: 19, 
                            label: _maxDistance.round().toString(),
                            onChanged: (double value) { setState(() { _maxDistance = value; }); },
                          ),
                        ),
                      ],
                    ),
                    
                    // 3. MY SERVICES CARD
                    _buildInfoCard(
                      theme: theme,
                      title: 'My Services',
                      children: [
                        ListView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _allServices.length,
                          itemBuilder: (context, index) {
                            final serviceName = _allServices[index];
                            return CheckboxListTile(
                              title: Text(serviceName, style: TextStyle(color: theme.onSurface)),
                              value: _servicesMap[serviceName] ?? false,
                              onChanged: (bool? newValue) { setState(() { _servicesMap[serviceName] = newValue ?? false; }); },
                              activeColor: secondaryGreenGradientEnd,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ],
                    ),

                    // 4. KYC DOCUMENTS CARD
                    _buildInfoCard(
                      theme: theme,
                      title: 'KYC Documents',
                      children: [
                        Text(_currentKycDocInfo, style: TextStyle(fontStyle: FontStyle.italic, color: theme.outline)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: Icon(_newKycFile == null ? Icons.upload_file : Icons.check_circle_outline, color: theme.primary),
                          label: Text(_newKycFile != null ? 'File Selected: ${_newKycFile!.name}' : 'Upload New Document'), 
                          onPressed: _pickFile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    
                    // 5. NOTIFICATIONS CARD
                    _buildInfoCard(
                      theme: theme,
                      title: 'Notifications',
                      children: [
                        _buildInfoRow(
                          'FCM Status:',
                          Text(_fcmTokenStatus, style: TextStyle(color: _fcmTokenStatus == 'Enabled' ? secondaryGreenGradientEnd : theme.error, fontWeight: FontWeight.bold)),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: Icon(_fcmTokenStatus == 'Enabled' ? Icons.notifications_off : Icons.notifications_active),
                          onPressed: _isTogglingNotifications ? null : _toggleNotifications,
                          label: _isTogglingNotifications 
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cardSurfaceColor))
                              : Text(_fcmTokenStatus == 'Enabled' ? 'Disable Notifications' : 'Enable Notifications'),
                          style: ElevatedButton.styleFrom(
                            // FIX: Using red.shade400 instead of theme.error.shade400
                            backgroundColor: _fcmTokenStatus == 'Enabled' ? Colors.red.shade400 : theme.primary,
                            foregroundColor: cardSurfaceColor,
                          ),
                        ),
                      ],
                    ),

                    // 6. PAYOUT SETTINGS CARD
                    _buildInfoCard(
                      theme: theme,
                      title: 'Payout Settings (Stripe Connect)',
                      children: [
                        _buildInfoRow(
                          'Connection Status:',
                          Text(
                            _stripeAccountId.isEmpty 
                                ? 'Not Connected' 
                                : _payoutsEnabled 
                                    ? 'Ready for Payouts' 
                                    : 'Verification Pending',
                            style: TextStyle(
                              color: _payoutsEnabled ? secondaryGreenGradientEnd : theme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          theme,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isConnectingStripe ? null : _connectStripe,
                          child: _isConnectingStripe
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cardSurfaceColor))
                              : Text(_stripeAccountId.isEmpty ? 'Connect Bank Account' : 'Manage Account'),
                        ),
                      ],
                    ),

                    // --- FINAL SAVE BUTTON ---
                    const SizedBox(height: 10),
                    AppButton(
                      label: _isSaving ? 'Saving Changes…' : 'Save All Changes',
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}