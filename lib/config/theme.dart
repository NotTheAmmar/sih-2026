import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary palette — WCAG AAA sunlight contrast
  static const Color actionGreen = Color(0xFF16A34A);
  static const Color actionGreenLight = Color(0xFFDCFCE7);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertRedLight = Color(0xFFFEE2E2);

  // Canvas
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF111827);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFF9FAFB);

  // UI
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color overlay = Color(0x80000000);

  // Price tiers
  static const Color priceFloor = Color(0xFF6B7280);
  static const Color priceFair = Color(0xFF16A34A);
  static const Color pricePremium = Color(0xFF7C3AED);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Touch targets
  static const double touchTargetMin = 64.0;
  static const double touchTargetPrimary = 72.0;

  // Border radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusFull = 999.0;

  // Screen padding
  static const double screenH = 16.0;
  static const double screenV = 24.0;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle get headline => _base(fontSize: 24, fontWeight: FontWeight.w700);
  static TextStyle get headlineLarge => _base(fontSize: 28, fontWeight: FontWeight.w700);
  static TextStyle get subhead => _base(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get body => _base(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => _base(fontSize: 16, fontWeight: FontWeight.w500);
  static TextStyle get caption => _base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get label => _base(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get priceLarge => _base(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.priceFair);
  static TextStyle get priceSmall => _base(fontSize: 18, fontWeight: FontWeight.w500);
  static TextStyle get chipText => _base(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle get onDark => _base(color: AppColors.textOnDark);
  static TextStyle get buttonLabel => _base(fontSize: 16, fontWeight: FontWeight.w600);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.actionGreen,
        brightness: Brightness.light,
        primary: AppColors.actionGreen,
        surface: AppColors.surfaceLight,
        error: AppColors.alertRed,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      textTheme: GoogleFonts.notoSansTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
          backgroundColor: AppColors.actionGreen,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}
