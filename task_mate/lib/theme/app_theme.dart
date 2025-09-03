import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF3B5BA8);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  
  // Text colors
  static final Color textPrimary = Colors.grey[800]!;
  static final Color textSecondary = Colors.grey[600]!;
  static final Color textHint = Colors.grey[500]!;
  
  // Shadow colors
  static final Color shadow = Colors.grey.withOpacity(0.2);
  static final Color shadowLight = Colors.grey.withOpacity(0.1);
}

class AppDimensions {
  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 15.0;
  static const double borderRadiusXLarge = 20.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

class AppTextStyles {
  static TextStyle get heading1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get heading2 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get heading3 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );
  
  static TextStyle get button => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class AppDecorations {
  // Input field decoration
  static BoxDecoration get inputFieldDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 15,
        offset: Offset(0, 5),
      ),
    ],
  );
  
  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
  );
  
  // Button decoration
  static BoxDecoration get buttonDecoration => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 15,
        offset: Offset(0, 8),
      ),
    ],
  );
  
  // Icon container decoration
  static BoxDecoration get iconContainerDecoration => BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );
}
