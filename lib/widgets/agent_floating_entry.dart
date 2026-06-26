import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

final agentFloatingEntryRouteHidden = ValueNotifier<bool>(false);

class AgentFloatingRouteObserver extends NavigatorObserver {
  void _sync(Route<dynamic>? route) {
    agentFloatingEntryRouteHidden.value = route?.settings.name == '/agent';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sync(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sync(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _sync(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sync(newRoute);
  }
}

class AgentFloatingEntry extends StatefulWidget {
  const AgentFloatingEntry({super.key});

  @override
  State<AgentFloatingEntry> createState() => _AgentFloatingEntryState();
}

class _AgentFloatingEntryState extends State<AgentFloatingEntry>
    with SingleTickerProviderStateMixin {
  static const Size _entrySize = Size(64, 64);
  static const double _edgePadding = 14;

  Offset? _position;
  Animation<Offset>? _snapAnimation;
  late final AnimationController _snapController;
  bool _dragged = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _snapController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 260),
          )
          ..addListener(() {
            final animation = _snapAnimation;
            if (animation == null || !mounted) return;
            setState(() => _position = animation.value);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _snapAnimation = null;
            }
          });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: agentFloatingEntryRouteHidden,
      builder: (context, hiddenByRoute, _) {
        return Obx(() {
          final appService = Get.find<AppService>();
          if (hiddenByRoute || !appService.canShowAiAgentEntry) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight) {
                return const SizedBox.shrink();
              }

              final safePadding = MediaQuery.paddingOf(context);
              final minY = safePadding.top + kToolbarHeight + _edgePadding;
              final maxY =
                  constraints.maxHeight -
                  _entrySize.height -
                  safePadding.bottom -
                  _edgePadding;
              final bounds = _DragBounds(
                minX: _edgePadding,
                maxX: (constraints.maxWidth - _entrySize.width - _edgePadding)
                    .clamp(_edgePadding, double.infinity),
                minY: minY,
                maxY: maxY < minY ? minY : maxY,
              );
              final current = _constrainPosition(
                _position ?? Offset(bounds.maxX, constraints.maxHeight * 0.62),
                bounds,
              );
              if (_position != current) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _position = current);
                  }
                });
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: current.dx,
                    top: current.dy,
                    width: _entrySize.width,
                    height: _entrySize.height,
                    child: _AgentFloatingButton(
                      isDragging: _isDragging,
                      onTap: _openAgent,
                      onDragStart: () {
                        _snapController.stop();
                        setState(() {
                          _dragged = false;
                          _isDragging = true;
                        });
                      },
                      onDragUpdate: (delta) {
                        _dragged = true;
                        setState(() {
                          final latest = _position ?? current;
                          _position = _constrainPosition(
                            latest + delta,
                            bounds,
                          );
                        });
                      },
                      onDragEnd: () {
                        final latest = _position ?? current;
                        final wasDragged = _dragged;
                        final centerX =
                            bounds.minX + (bounds.maxX - bounds.minX) / 2;
                        final target = _constrainPosition(
                          Offset(
                            latest.dx < centerX ? bounds.minX : bounds.maxX,
                            latest.dy,
                          ),
                          bounds,
                        );
                        setState(() => _isDragging = false);
                        _animateTo(target, bounds);
                        if (wasDragged) {
                          Future<void>.delayed(
                            const Duration(milliseconds: 80),
                            () {
                              if (mounted) _dragged = false;
                            },
                          );
                        }
                      },
                      shouldIgnoreTap: () => _dragged,
                    ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  void _animateTo(Offset target, _DragBounds bounds) {
    final begin = _constrainPosition(_position ?? target, bounds);
    final end = _constrainPosition(target, bounds);
    if ((begin - end).distance < 0.5) {
      setState(() => _position = end);
      return;
    }

    _snapAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  Offset _constrainPosition(Offset value, _DragBounds bounds) {
    return Offset(
      value.dx.clamp(bounds.minX, bounds.maxX).toDouble(),
      value.dy.clamp(bounds.minY, bounds.maxY).toDouble(),
    );
  }

  void _openAgent() {
    if (_dragged) return;
    if (Get.currentRoute == '/agent') return;
    Get.toNamed('/agent');
  }
}

class _AgentFloatingButton extends StatefulWidget {
  const _AgentFloatingButton({
    required this.isDragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.shouldIgnoreTap,
  });

  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final bool Function() shouldIgnoreTap;

  @override
  State<_AgentFloatingButton> createState() => _AgentFloatingButtonState();
}

class _AgentFloatingButtonState extends State<_AgentFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'AI 对话助手',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!widget.shouldIgnoreTap()) widget.onTap();
        },
        onPanStart: (_) => widget.onDragStart(),
        onPanUpdate: (details) => widget.onDragUpdate(details.delta),
        onPanEnd: (_) => widget.onDragEnd(),
        onPanCancel: widget.onDragEnd,
        child: AnimatedScale(
          scale: widget.isDragging ? 0.92 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _idleController,
            builder: (context, child) {
              final tick = reduceMotion ? 0.0 : _idleController.value;
              final wave = math.sin(tick * math.pi * 2);
              final bob = widget.isDragging ? 0.0 : wave * 1.6;
              final breathe = widget.isDragging ? 1.0 : 1 + wave * 0.018;
              final earTilt = widget.isDragging ? 0.0 : wave * 0.06;
              return Transform.translate(
                offset: Offset(0, bob),
                child: Transform.scale(
                  scale: breathe,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 2,
                          child: Transform.scale(
                            scaleX: widget.isDragging ? 0.86 : 1 + wave * 0.04,
                            child: Container(
                              width: 38,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.shadow.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 7,
                          left: 13,
                          child: Transform.rotate(
                            angle: -0.42 - earTilt,
                            child: _PetEar(colorScheme: colorScheme),
                          ),
                        ),
                        Positioned(
                          top: 7,
                          right: 13,
                          child: Transform.rotate(
                            angle: 0.42 + earTilt,
                            child: _PetEar(colorScheme: colorScheme),
                          ),
                        ),
                        Positioned(
                          top: 6 + wave * 1.2,
                          right: 7,
                          child: Icon(
                            CupertinoIcons.sparkles,
                            size: 13,
                            color: colorScheme.tertiary.withValues(alpha: 0.86),
                          ),
                        ),
                        Positioned(
                          left: 7,
                          bottom: 17,
                          child: Transform.rotate(
                            angle: -0.34 + wave * 0.08,
                            child: _PetTail(colorScheme: colorScheme),
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.32, -0.48),
                              radius: 0.88,
                              colors: [
                                colorScheme.onPrimary.withValues(alpha: 0.94),
                                colorScheme.primaryContainer,
                                colorScheme.primary,
                              ],
                              stops: const [0, 0.34, 1],
                            ),
                            border: Border.all(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.22,
                              ),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.34,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 12,
                                offset: const Offset(-4, -3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 9,
                                left: 14,
                                child: Container(
                                  width: 14,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.24,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 22,
                                left: 14,
                                child: _PetEye(color: colorScheme.onPrimary),
                              ),
                              Positioned(
                                top: 22,
                                right: 14,
                                child: _PetEye(color: colorScheme.onPrimary),
                              ),
                              Positioned(
                                top: 34,
                                child: Container(
                                  width: 12,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.64,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PetEar extends StatelessWidget {
  const _PetEar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 18,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

class _PetEye extends StatelessWidget {
  const _PetEye({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PetTail extends StatelessWidget {
  const _PetTail({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 22,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _DragBounds {
  const _DragBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
}
