import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final bool isLoading;
  final bool isSuccess;
  final String? loadingText;
  final TextStyle? loadingTextStyle;
  final BoxDecoration? submitButtonDecoration;
  final TextStyle? submitButtonTextStyle;
  final String submitButtonText;
  final VoidCallback onVerify;

  const CustomButton({
    super.key,
    required this.isLoading,
    required this.isSuccess,
    this.loadingText,
    this.loadingTextStyle,
    this.submitButtonDecoration,
    this.submitButtonTextStyle,
    required this.submitButtonText,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onVerify,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: submitButtonDecoration ??
            BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(8),
            ),
        margin: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: isSuccess
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loadingText ?? 'Signing you in...',
                    style: loadingTextStyle ??
                        const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              )
            : isLoading
                ? const SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    submitButtonText,
                    style: submitButtonTextStyle ??
                        const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
      ),
    );
  }
}
