import 'package:flutter/material.dart';
import 'package:watthome_app/Models/customColors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isEmailField;
  final bool isPasswordField;
  final bool isValid;
  final int? maxLength;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isEmailField = false,
    this.isPasswordField = false,
    this.isValid = true,
    this.maxLength,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPasswordField ? _obscureText : false,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        // fillColor: CustomColors.textboxColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid
                ? CustomColors.tileBorderColor
                : CustomColors.errorColor,
            width: 1.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid
                ? CustomColors.tileBorderColor
                : CustomColors.errorColor,
            width: 1.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid
                ? CustomColors.primaryColor
                : CustomColors.errorColor,
            width: 2.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        suffixIcon: widget.isPasswordField
            ? Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: CustomColors.textAccentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              )
            : null,
      ),
      keyboardType:
          widget.isEmailField ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}
