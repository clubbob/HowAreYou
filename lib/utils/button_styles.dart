import 'package:flutter/material.dart';

/// 확인/추가 등 주요 액션 버튼 UI 통일
class AppButtonStyles {
  AppButtonStyles._();

  static const double primaryRadius = 12;
  static const double primaryMinHeight = 56;
  static const EdgeInsets primaryPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static const TextStyle primaryTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static ButtonStyle get primaryElevated => ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 3,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: primaryPadding,
        minimumSize: const Size(double.infinity, primaryMinHeight),
        textStyle: primaryTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(primaryRadius),
        ),
      );

  static ButtonStyle get primaryFilled => FilledButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: primaryPadding,
        minimumSize: const Size(0, primaryMinHeight),
        textStyle: primaryTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(primaryRadius),
        ),
      );
}
