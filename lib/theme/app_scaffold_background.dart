import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appService = Get.find<AppService>();

    return Obx(() {
      final bytes = appService.backgroundImageBytes.value;
      final showUserImage =
          appService.backgroundImageEnabled.value && bytes != null;

      return Stack(
        fit: StackFit.expand,
        children: [
          if (showUserImage)
            _UserScaffoldBackground(
              image: Image.memory(bytes, fit: BoxFit.cover),
              opacity: appService.backgroundImageOpacity.value,
              gradientTop: appService.backgroundImageGradientTop.value,
              gradientBottom: appService.backgroundImageGradientBottom.value,
            )
          else
            const _DefaultScaffoldBackground(),
          Positioned.fill(child: child),
        ],
      );
    });
  }
}

class _DefaultScaffoldBackground extends StatelessWidget {
  const _DefaultScaffoldBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF08080B),
                      Color(0xFF0D0D12),
                      Color(0xFF111116),
                      Color(0xFF09090D),
                    ]
                  : const [
                      Color(0xFFFEFEFF),
                      Color(0xFFF8F8FA),
                      Color(0xFFF2F2F7),
                      Color(0xFFFAFAFB),
                    ],
            ),
          ),
        ),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
          child: CustomPaint(
            painter: _LiquidGlassBackgroundPainter(isDark: isDark),
          ),
        ),
        CustomPaint(painter: _GlassSheenPainter(isDark: isDark)),
        CustomPaint(painter: _MaterialGrainPainter(isDark: isDark)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.035),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.52),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.30),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserScaffoldBackground extends StatelessWidget {
  const _UserScaffoldBackground({
    required this.image,
    required this.opacity,
    required this.gradientTop,
    required this.gradientBottom,
  });

  final Image image;
  final double opacity;
  final Color gradientTop;
  final Color gradientBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: opacity.clamp(0.0, 1.0), child: image),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientTop, gradientBottom],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.22 : 0.10,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiquidGlassBackgroundPainter extends CustomPainter {
  const _LiquidGlassBackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final primaryPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.075),
                const Color(0xFF8E8E93).withValues(alpha: 0.035),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.42),
                const Color(0xFFAEAEB2).withValues(alpha: 0.10),
                Colors.transparent,
              ],
      ).createShader(bounds)
      ..blendMode = isDark ? BlendMode.softLight : BlendMode.plus;

    final warmPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? [
                const Color(0xFFFF9F0A).withValues(alpha: 0.030),
                Colors.white.withValues(alpha: 0.026),
                Colors.transparent,
              ]
            : [
                const Color(0xFFFFF4DF).withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.16),
                Colors.transparent,
              ],
      ).createShader(bounds)
      ..blendMode = isDark ? BlendMode.screen : BlendMode.softLight;

    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.055),
                Colors.white.withValues(alpha: 0.018),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.16),
                Colors.transparent,
              ],
      ).createShader(bounds)
      ..blendMode = BlendMode.softLight;

    canvas.drawPath(_upperRibbon(size, diagonal), primaryPaint);
    canvas.drawPath(_lowerRibbon(size, diagonal), warmPaint);
    canvas.drawPath(_glassVeil(size), glassPaint);
  }

  Path _upperRibbon(Size size, double diagonal) {
    return Path()
      ..moveTo(-diagonal * 0.20, size.height * 0.06)
      ..cubicTo(
        size.width * 0.20,
        -size.height * 0.10,
        size.width * 0.52,
        size.height * 0.16,
        size.width * 1.18,
        size.height * 0.02,
      )
      ..lineTo(size.width * 1.28, size.height * 0.42)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.34,
        size.width * 0.20,
        size.height * 0.56,
        -diagonal * 0.22,
        size.height * 0.30,
      )
      ..close();
  }

  Path _lowerRibbon(Size size, double diagonal) {
    return Path()
      ..moveTo(-diagonal * 0.12, size.height * 0.70)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.48,
        size.width * 0.56,
        size.height * 0.82,
        size.width * 1.16,
        size.height * 0.58,
      )
      ..lineTo(size.width * 1.12, size.height * 1.16)
      ..lineTo(-diagonal * 0.10, size.height * 1.10)
      ..close();
  }

  Path _glassVeil(Size size) {
    return Path()
      ..moveTo(size.width * 0.10, -size.height * 0.05)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.38,
        size.height * 0.58,
        size.width * 0.88,
        size.height * 1.08,
      )
      ..lineTo(size.width * 1.16, size.height * 1.08)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.44,
        size.width * 0.64,
        size.height * 0.10,
        size.width * 0.28,
        -size.height * 0.08,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _GlassSheenPainter extends CustomPainter {
  const _GlassSheenPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.02),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.18),
                Colors.transparent,
              ],
      ).createShader(Offset.zero & size);

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.16 + i * 0.18);
      final path = Path()
        ..moveTo(-size.width * 0.12, y)
        ..cubicTo(
          size.width * 0.20,
          y - 34,
          size.width * 0.52,
          y + 40,
          size.width * 1.12,
          y - 10,
        );
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassSheenPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _MaterialGrainPainter extends CustomPainter {
  const _MaterialGrainPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.028 : 0.018,
      );
    const step = 6.0;
    final columns = (size.width / step).ceil();
    final rows = (size.height / step).ceil();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final seed = (x * 37 + y * 17) % 29;
        if (seed > 5) continue;
        final dx = x * step + (seed % 3) * 0.7;
        final dy = y * step + (seed % 5) * 0.45;
        canvas.drawCircle(Offset(dx, dy), 0.42, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaterialGrainPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
