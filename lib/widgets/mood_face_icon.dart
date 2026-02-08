import 'package:flutter/material.dart';
import '../models/mood_response_model.dart';

/// 보내주신 디자인: 그라데이션 원 + 단순 얼굴(눈 두 점, 입 선/곡선)
class MoodFaceIcon extends StatelessWidget {
  final Mood mood;
  final double size;
  final bool withShadow;

  const MoodFaceIcon({
    super.key,
    required this.mood,
    this.size = 48,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOkay = mood == Mood.okay;
    final isNormal = mood == Mood.normal;
    final isNotGood = mood == Mood.notGood;

    Color baseColor;
    Color endColor;
    if (isOkay) {
      baseColor = const Color(0xFFB8E0C8);
      endColor = const Color(0xFF7BC89C);
    } else if (isNormal) {
      baseColor = const Color(0xFFF5F0E8);
      endColor = const Color(0xFFD4C4B0);
    } else {
      baseColor = const Color(0xFFF5C4A8);
      endColor = const Color(0xFFE8956A);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, endColor],
        ),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: endColor.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _FacePainter(
          smile: isOkay,
          neutral: isNormal,
          frown: isNotGood,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final bool smile;
  final bool neutral;
  final bool frown;

  _FacePainter({
    required this.smile,
    required this.neutral,
    required this.frown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final eyeY = s * 0.38;
    final eyeRadius = s * 0.06;
    final leftEyeX = s * 0.35;
    final rightEyeX = s * 0.65;
    final mouthY = s * 0.68;
    final mouthW = s * 0.4;
    final mouthCenterX = s * 0.5;

    final paint = Paint()
      ..color = const Color(0xFF3D3D3D)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, paint);
    canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, paint);

    if (smile) {
      // 웃는 입: 반대로 — 제어점 아래(mouthY +)
      final path = Path();
      path.moveTo(mouthCenterX - mouthW / 2, mouthY);
      path.quadraticBezierTo(
        mouthCenterX,
        mouthY + s * 0.16,
        mouthCenterX + mouthW / 2,
        mouthY,
      );
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = s * 0.04;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    } else if (neutral) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = s * 0.035;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(mouthCenterX - mouthW / 2, mouthY),
        Offset(mouthCenterX + mouthW / 2, mouthY),
        paint,
      );
    } else if (frown) {
      // 찌그러진 입: 반대로 — 제어점 위(mouthY -)
      final path = Path();
      path.moveTo(mouthCenterX - mouthW / 2, mouthY);
      path.quadraticBezierTo(
        mouthCenterX,
        mouthY - s * 0.16,
        mouthCenterX + mouthW / 2,
        mouthY,
      );
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = s * 0.04;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
