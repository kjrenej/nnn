import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/rento_theme.dart';

enum AlertType { success, error, warning, info }

class CustomAlert {
  /// Displays a floating style custom snackbar toast.
  static void showToast(
    BuildContext context,
    String message, {
    AlertType type = AlertType.info,
  }) {
    final theme = Theme.of(context);
    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case AlertType.success:
        bgColor = RentoTheme.successColor;
        iconColor = Colors.white;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case AlertType.error:
        bgColor = RentoTheme.errorColor;
        iconColor = Colors.white;
        iconData = Icons.error_outline_rounded;
        break;
      case AlertType.warning:
        bgColor = Colors.orange.shade600;
        iconColor = Colors.white;
        iconData = Icons.warning_amber_rounded;
        break;
      case AlertType.info:
      default:
        bgColor = theme.colorScheme.primary;
        iconColor = Colors.white;
        iconData = Icons.info_outline_rounded;
    }

    final snackBar = SnackBar(
      content:
          Row(
                children: [
                  Icon(iconData, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1, end: 0, curve: Curves.easeOut),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      elevation: 6,
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Displays a beautifully designed confirmation dialog.
  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
    required VoidCallback onConfirm,
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confirmColor = isDestructive
        ? RentoTheme.errorColor
        : RentoTheme.primaryColor;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark
              ? RentoTheme.cardDark
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: confirmColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDestructive
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline_rounded,
                    color: confirmColor,
                    size: 32,
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(cancelText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(confirmText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fade().scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.easeOutBack,
        );
      },
    );
  }
}
