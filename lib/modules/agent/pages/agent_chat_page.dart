import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/agent/controllers/agent_controller.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_input_bar.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_message_bubble.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_session_panel.dart';

class AgentChatPage extends StatefulWidget {
  const AgentChatPage({super.key});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final _inputController = TextEditingController();
  late final AgentController _controller;
  bool _isSessionPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AgentController>();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _openSessionDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSessionPanelOpen) return;
    setState(() => _isSessionPanelOpen = true);
  }

  void _closeSessionDrawer() {
    if (!_isSessionPanelOpen) return;
    setState(() => _isSessionPanelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final showSidePanel = MediaQuery.sizeOf(context).width >= 840;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _AgentAppBar(
        showSessionAction: !showSidePanel,
        onTapSessions: _openSessionDrawer,
        onTapNewSession: () {
          _inputController.clear();
          _controller.startNewSession();
        },
      ),
      body: showSidePanel
          ? Row(
              children: [
                const SizedBox(width: 312, child: AgentSessionPanel()),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: _ChatPane(controller: _inputController)),
              ],
            )
          : Stack(
              children: [
                _ChatPane(controller: _inputController),
                _SessionPanelOverlay(
                  visible: _isSessionPanelOpen,
                  onClose: _closeSessionDrawer,
                ),
              ],
            ),
    );
  }
}

class _SessionPanelOverlay extends StatelessWidget {
  const _SessionPanelOverlay({required this.visible, required this.onClose});

  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 380 ? width * 0.90 : 336.0;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: 0,
              right: visible ? 0 : -panelWidth,
              bottom: 0,
              width: panelWidth,
              child: Material(
                color: colorScheme.surface,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                child: AgentSessionPanel(onSelected: onClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AgentAppBar({
    required this.showSessionAction,
    required this.onTapSessions,
    required this.onTapNewSession,
  });

  final bool showSessionAction;
  final VoidCallback onTapSessions;
  final VoidCallback onTapNewSession;

  @override
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 68,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: '返回',
        onPressed: Get.back,
        icon: const Icon(CupertinoIcons.chevron_left),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agent 对话',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() {
                  final controller = Get.find<AgentController>();
                  final connected =
                      controller.activeServerSessionId.value?.isNotEmpty ??
                      false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: connected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.56,
                                ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? '已连接会话' : '新会话',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showSessionAction)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              tooltip: '历史会话',
              onPressed: onTapSessions,
              icon: const Icon(CupertinoIcons.sidebar_right, size: 19),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton.filled(
            tooltip: '新对话',
            onPressed: onTapNewSession,
            icon: const Icon(CupertinoIcons.square_pencil, size: 18),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _ChatPane extends StatefulWidget {
  const _ChatPane({required this.controller});

  final TextEditingController controller;

  @override
  State<_ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<_ChatPane> {
  final _scrollController = ScrollController();
  late final AgentController _controller;
  Worker? _messagesWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AgentController>();
    _messagesWorker = ever(_controller.messages, (_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.025),
          colorScheme.surface,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingMessages.value) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (_controller.messages.isEmpty) {
                return const _EmptyChat();
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: AgentMessageBubble(
                      message: _controller.messages[index],
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            final error = _controller.messageError.value;
            if (error == null || error.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 18,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          Obx(
            () => AgentInputBar(
              controller: widget.controller,
              enabled: !_controller.isSending.value,
              onSend: () {
                final text = widget.controller.text;
                widget.controller.clear();
                _controller.sendMessage(text);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 60), () {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                CupertinoIcons.sparkles,
                size: 31,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '开始一段 Agent 对话',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                '媒体推荐、资源搜索、订阅整理',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _EmptyPromptPill(text: '找片'),
                _EmptyPromptPill(text: '整理订阅'),
                _EmptyPromptPill(text: '解释结果'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPromptPill extends StatelessWidget {
  const _EmptyPromptPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
