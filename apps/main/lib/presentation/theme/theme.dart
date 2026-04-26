import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screen_theme.dart';
import 'theme_color.dart';

class MainAppTheme {
  final AppTheme light;
  final AppTheme dark;

  const MainAppTheme({required this.light, required this.dark});

  factory MainAppTheme.normal() {
    return MainAppTheme(light: _buildLightTheme(), dark: _buildDarkTheme());
  }

  static AppTheme _buildLightTheme() {
    final themeColor = AppThemeColor();
    final textTheme = _createTextTheme(themeColor);

    return AppTheme.factory(
      screenTheme: _createScreenTheme(
        screenFormTheme: AppScreenFormTheme(textTheme),
        mainPageFormTheme: AppMainPageFormTheme(textTheme),
      ),
      appTextTheme: textTheme,
      themeColor: themeColor,
      targetPlatform: _getTargetPlatform(),
    );
  }

  static AppTheme _buildDarkTheme() {
    final themeColor = AppDarkThemeColor();
    final textTheme = _createTextTheme(themeColor);

    return AppTheme.factory(
      screenTheme: _createScreenTheme(
        screenFormTheme: AppScreenFormDarkTheme(textTheme),
        mainPageFormTheme: AppMainPageFormDarkTheme(textTheme),
      ),
      appTextTheme: textTheme,
      themeColor: themeColor,
      targetPlatform: _getTargetPlatform(),
    );
  }

  static AppTextTheme _createTextTheme(ThemeColor themeColor) {
    return AppTextTheme.create(
      themeColor,
      wrapper: (style) {
        /// You can use Google Fonts to apply font family
        /// e.g., return GoogleFonts.poppins(textStyle: style);
        return style;
      },
    ).let(
      (textTheme) => textTheme.copyWithTypography(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.45),
        inputTitle: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        inputHint: textTheme.bodyMedium?.copyWith(color: themeColor.labelText),
        inputError: textTheme.labelMedium?.copyWith(
          color: themeColor.error,
          fontWeight: FontWeight.w600,
        ),
        buttonText: textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ScreenTheme _createScreenTheme({
    required dynamic screenFormTheme,
    required dynamic mainPageFormTheme,
  }) {
    return ScreenTheme(
      screenFormTheme: screenFormTheme,
      mainPageFormTheme: mainPageFormTheme,
    );
  }

  static TargetPlatform? _getTargetPlatform() {
    return kIsWeb ? null : TargetPlatform.iOS;
  }
}
