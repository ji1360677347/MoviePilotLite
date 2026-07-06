import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.extendBodyBehindAppBar = true,
    this.includeUserBackground = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  final bool includeUserBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DashboardPageBackground(
              includeUserBackground: includeUserBackground,
            ),
          ),
          body,
        ],
      ),
    );
  }
}

class DashboardPageBackground extends StatelessWidget {
  const DashboardPageBackground({super.key, this.includeUserBackground = true});

  final bool includeUserBackground;

  @override
  Widget build(BuildContext context) {
    final appService = Get.find<AppService>();
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final backgroundBytes = appService.backgroundImageBytes.value;
      final backgroundOpacity = appService.backgroundImageOpacity.value;
      final gradientTop = appService.backgroundImageGradientTop.value;
      final gradientBottom = appService.backgroundImageGradientBottom.value;
      final hasUserBackground =
          includeUserBackground &&
          appService.backgroundImageEnabled.value &&
          backgroundBytes != null;

      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: palette.pageBackground),
          if (hasUserBackground)
            _DashboardBackgroundImage(
              bytes: backgroundBytes,
              opacity: backgroundOpacity,
              gradientTop: gradientTop,
              gradientBottom: gradientBottom,
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.overlay.withValues(
                      alpha: palette.isDark ? 0.18 : 0.08,
                    ),
                    palette.pageBackgroundAlt,
                    palette.pageBackground,
                  ],
                  stops: const [0, 0.68, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.primary.withValues(
                        alpha: palette.isDark ? 0.18 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _DashboardBackgroundImage extends StatelessWidget {
  const _DashboardBackgroundImage({
    required this.bytes,
    required this.opacity,
    required this.gradientTop,
    required this.gradientBottom,
  });

  final Uint8List? bytes;
  final double opacity;
  final Color gradientTop;
  final Color gradientBottom;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: Image.memory(
              bytes!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientTop, gradientBottom],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
