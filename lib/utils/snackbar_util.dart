import 'package:flutter/material.dart';

class SnackbarUtil {
  static void showError(BuildContext context, String message) {
    _show(context, message, color: Colors.red.shade700, icon: Icons.error_outline);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, color: Colors.green.shade700, icon: Icons.check_circle_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, color: Colors.blue.shade700, icon: Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
