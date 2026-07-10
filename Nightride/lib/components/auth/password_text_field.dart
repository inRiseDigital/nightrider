import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

import 'auth_text_field.dart';

/// Password input — wraps AuthTextField with an obscure-toggle eye icon.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.hint = 'Password',
    this.icon = Icons.lock_outline_rounded,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final fontSize = AuthDimensions.inputFontSize(context);

    return AuthTextField(
      controller: widget.controller,
      hint: widget.hint,
      icon: widget.icon,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscure,
      autofillHints: widget.autofillHints,
      suffix: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: fontSize + 5,
            color: const Color(0xFFDFFF2F),
          ),
        ),
      ),
    );
  }
}
