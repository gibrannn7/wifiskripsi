import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/constants/app_assets.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle bold = TextStyle(
    fontFamily: AppAssets.fontInter,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle semiBold = TextStyle(
    fontFamily: AppAssets.fontInter,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: AppAssets.fontInter,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle regular = TextStyle(
    fontFamily: AppAssets.fontInter,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Gaya teks khusus untuk harga coret (diskon)
  static const TextStyle strikethrough = TextStyle(
    fontFamily: AppAssets.fontInter,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
  );
}
