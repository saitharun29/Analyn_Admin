// lib/widgets/app_text_field.dart
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.validator, 
    this.keyboardType = TextInputType.text,
  }) : assert(validator == null);

  const AppTextField.validated({
    super.key,
    required this.controller,
    required this.hint,
    required this.validator,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Subtle shadow for the floating card effect
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(color: theme.onSurface),
        // Decoration is now largely handled by InputDecorationTheme in main.dart
        // We can override specific properties if needed, but let's rely on the theme for now.
        decoration: InputDecoration(
          hintText: hint,
          // Removed specific border/fillColor here, relying on theme.
        ),
      ),
    );
  }
}