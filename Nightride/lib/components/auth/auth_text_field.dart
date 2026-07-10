import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

/// Reusable rounded text field for auth forms.
/// Sizing/typography come from AuthDimensions so it adapts to form factor.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final radius = AuthDimensions.inputBorderRadius(context);
    final fontSize = AuthDimensions.inputFontSize(context);

    return Container(
      height: AuthDimensions.inputHeight(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF151515),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofillHints: autofillHints,
        style: TextStyle(
          color: const Color(0xFFFAFAFA),
          fontSize: fontSize,
        ),
        cursorColor: const Color(0xFFDFFF2F),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(
              icon,
              color: const Color(0xFFDFFF2F),
              size: fontSize + 7,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(
              color: Color(0xFF333333),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(
              color: Color(0xFFDFFF2F),
              width: 1.5,
            ),
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
