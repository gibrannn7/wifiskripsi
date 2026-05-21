import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';

class CustomDialog {
  static void showSuccess(
    BuildContext context, 
    String title, 
    String message, {
    VoidCallback? onConfirm, 
    String buttonText = 'Tutup',
    bool autoDismiss = false,
  }) {
    _show(
      context,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.statusActive,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
      autoDismiss: autoDismiss,
    );
  }

  static void showError(
    BuildContext context, 
    String title, 
    String message, {
    VoidCallback? onConfirm, 
    String buttonText = 'Tutup',
    bool autoDismiss = false,
  }) {
    _show(
      context,
      icon: Icons.cancel_rounded,
      iconColor: AppColors.statusInactive,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
      autoDismiss: autoDismiss,
    );
  }

  static void showConfirmation(
    BuildContext context, 
    String title, 
    String message, {
    required VoidCallback onConfirm, 
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: AppColors.textWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          cancelText,
                          style: AppTextStyles.bold.copyWith(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: Text(
                          confirmText,
                          style: AppTextStyles.bold.copyWith(color: AppColors.textWhite, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
    VoidCallback? onConfirm,
    required bool autoDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !autoDismiss,
      builder: (context) {
        if (autoDismiss) {
          Timer(const Duration(milliseconds: 1500), () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
              if (onConfirm != null) {
                onConfirm();
              }
            }
          });
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: AppColors.textWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                ),
                if (!autoDismiss) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        if (onConfirm != null) {
                          onConfirm();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
