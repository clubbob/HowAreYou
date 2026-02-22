import 'package:flutter/material.dart';

/// 앱 로고 위젯 (로고 파일이 있으면 표시, 없으면 텍스트)
class AppLogo extends StatelessWidget {
  final double? height;
  final double fontSize;
  final FontWeight fontWeight;

  const AppLogo({
    super.key,
    this.height,
    this.fontSize = 32,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Image.asset(
        'assets/images/logo.png',
        height: height ?? 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 로고 파일이 없으면 텍스트 표시
          return Text(
            '오늘 어때?',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: -0.5,
            ),
          );
        },
      );
    } catch (_) {
      // 로고 파일이 없으면 텍스트 표시
      return Text(
        '오늘 어때?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.5,
        ),
      );
    }
  }
}
