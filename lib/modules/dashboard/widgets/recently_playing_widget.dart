import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/latest_media_model.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 继续观看组件
class RecentlyPlayingWidget extends StatelessWidget {
  const RecentlyPlayingWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final playingMedia = mediaServerController.playingMedia;
      if (playingMedia.value == null || playingMedia.value!.isEmpty) {
        return const _EmptyState(
          icon: CupertinoIcons.play_rectangle,
          title: '暂无继续观看内容',
          subtitle: '开始播放后会在这里继续追看',
        );
      }

      return SizedBox(
        height: 214,
        child: ListView.separated(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: playingMedia.value!.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final media = playingMedia.value![index];
            return SizedBox(width: 280, child: _ContinueCard(media: media));
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.media});

  final LatestMedia media;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final progress = ((media.percent ?? 0) / 100).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: '${media.title}，继续观看',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.34),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: palette.surfaceAlt),
              ),
              media.image.isNotEmpty
                  ? CachedImage(
                      imageUrl: ImageUtil.convertInternalImageUrl(media.image),
                      fit: BoxFit.cover,
                    )
                  : _BackdropFallback(palette: palette),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.07),
                      Colors.black.withValues(alpha: 0.52),
                    ],
                    stops: const [0.0, 0.56, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Flexible(
                      child: _GlassPill(
                        text: media.type.isEmpty ? '继续观看' : media.type,
                        icon: CupertinoIcons.play_fill,
                      ),
                    ),
                    const Spacer(),
                    _CircleButton(
                      icon: CupertinoIcons.play_arrow_solid,
                      size: 38,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.rectangle_stack,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            media.libraryName.isNotEmpty
                                ? media.libraryName
                                : media.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                        if (progress > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ProgressBar(
                      value: progress > 0 ? progress : 0.08,
                      color: palette.warningAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackdropFallback extends StatelessWidget {
  const _BackdropFallback({required this.palette});

  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surfaceAlt,
            Color.alphaBlend(
              palette.primary.withValues(alpha: 0.16),
              palette.surfaceAlt,
            ),
            Color.alphaBlend(
              palette.warmAccent.withValues(alpha: 0.12),
              palette.surfaceAlt,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.play_rectangle,
          color: Colors.white.withValues(alpha: 0.58),
          size: 40,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.size = 36});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 3.5,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.tileSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Icon(icon, color: palette.mutedText, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.titleText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
