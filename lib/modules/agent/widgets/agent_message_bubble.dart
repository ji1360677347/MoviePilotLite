import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class AgentMessageBubble extends StatelessWidget {
  const AgentMessageBubble({super.key, required this.message});

  final AgentChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;
    final bubbleColor = isUser ? colorScheme.primary : colorScheme.surface;
    final foreground = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final listWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        final sideInset = isUser ? 52.0 : 52.0;
        final avatarWidth = isUser ? 0.0 : 38.0;
        final bubbleMaxWidth = (listWidth - sideInset - avatarWidth).clamp(
          120.0,
          760.0,
        );

        return SizedBox(
          width: listWidth,
          child: Padding(
            padding: EdgeInsets.only(
              left: isUser ? sideInset : 0,
              right: isUser ? 0 : sideInset,
              bottom: 14,
            ),
            child: Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  _AssistantAvatar(colorScheme: colorScheme),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 5),
                          bottomRight: Radius.circular(isUser ? 5 : 16),
                        ),
                        border: Border.all(
                          color: isUser
                              ? colorScheme.primary.withValues(alpha: 0.24)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.58,
                                ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.tools.isNotEmpty)
                            _ToolEvents(tools: message.tools),
                          if (message.content.trim().isNotEmpty)
                            isUser
                                ? SelectableText(
                                    message.content,
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                                  )
                                : _MarkdownContent(
                                    key: ValueKey(
                                      'md-${message.id}-${message.status.name}',
                                    ),
                                    markdown: message.content,
                                  ),
                          if (message.attachments.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _AttachmentList(attachments: message.attachments),
                          ],
                          if (message.status ==
                              AgentMessageStatus.streaming) ...[
                            const SizedBox(height: 9),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoActivityIndicator(
                                  radius: 7,
                                  color: isUser
                                      ? foreground
                                      : colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '生成中',
                                  style: TextStyle(
                                    color: isUser
                                        ? foreground.withValues(alpha: 0.78)
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (message.status == AgentMessageStatus.failed) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  size: 14,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '发送失败',
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.74),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Icon(
        CupertinoIcons.sparkles,
        size: 15,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedMarkdown = _normalizeMarkdownForPlus(markdown);
    final segments = _splitMarkdownSegments(normalizedMarkdown);
    final styleSheet = _agentMarkdownStyle(theme, colorScheme);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments)
          if (segment.table != null)
            _AgentMarkdownTable(
              table: segment.table!,
              styleSheet: styleSheet,
              colorScheme: colorScheme,
            )
          else if (segment.text.trim().isNotEmpty)
            MarkdownBody(
              data: segment.text.trim(),
              selectable: true,
              fitContent: true,
              shrinkWrap: true,
              softLineBreak: true,
              styleSheet: styleSheet,
              onTapLink: (_, href, __) {
                if (href == null || href.trim().isEmpty) return;
                WebUtil.open(url: href);
              },
            ),
      ],
    );
  }
}

MarkdownStyleSheet _agentMarkdownStyle(
  ThemeData theme,
  ColorScheme colorScheme,
) {
  final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
    color: colorScheme.onSurface,
    height: 1.55,
    letterSpacing: 0,
  );
  final headingStyle = theme.textTheme.titleMedium?.copyWith(
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w800,
    height: 1.28,
    letterSpacing: 0,
  );
  final tableBodyStyle = theme.textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurface,
    height: 1.32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  final tableHeadStyle = tableBodyStyle?.copyWith(
    color: colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w800,
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: bodyStyle,
    pPadding: const EdgeInsets.only(bottom: 6),
    a: bodyStyle?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
    h1: headingStyle?.copyWith(fontSize: 18),
    h2: headingStyle?.copyWith(fontSize: 17),
    h3: headingStyle?.copyWith(fontSize: 16),
    h4: headingStyle?.copyWith(fontSize: 15),
    h5: headingStyle?.copyWith(fontSize: 14),
    h6: headingStyle?.copyWith(fontSize: 13),
    h1Padding: const EdgeInsets.only(top: 6, bottom: 8),
    h2Padding: const EdgeInsets.only(top: 6, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 5, bottom: 7),
    h4Padding: const EdgeInsets.only(top: 4, bottom: 6),
    blockSpacing: 8,
    listIndent: 18,
    tableHead: tableHeadStyle,
    tableBody: tableBodyStyle,
    tableHeadAlign: TextAlign.left,
    tablePadding: const EdgeInsets.symmetric(vertical: 6),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    tableHeadCellsPadding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 7,
    ),
    tableBorder: TableBorder.all(
      color: colorScheme.outlineVariant.withValues(alpha: 0.58),
      width: 0.8,
    ),
    tableCellsDecoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
    ),
    tableHeadCellsDecoration: BoxDecoration(
      color: colorScheme.primaryContainer.withValues(alpha: 0.22),
    ),
    tableColumnWidth: const FlexColumnWidth(),
    tableScrollbarThumbVisibility: false,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.50),
        ),
      ),
    ),
  );
}

String _normalizeMarkdownForPlus(String source) {
  final normalized = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('⭐', '★');
  final lines = normalized.split('\n');
  final result = <String>[];
  var inFence = false;
  var previousWasTable = false;

  void appendNormalizedLine(String line) {
    final trimmed = line.trim();
    final isTable = !inFence && _isLikelyMarkdownTableLine(line);
    final isBlockHeading = !inFence && RegExp(r'^#{1,6}\s+').hasMatch(line);

    if ((isTable || isBlockHeading) &&
        result.isNotEmpty &&
        result.last.trim().isNotEmpty &&
        !(isTable && previousWasTable)) {
      result.add('');
    }

    if (!isTable &&
        previousWasTable &&
        trimmed.isNotEmpty &&
        result.isNotEmpty &&
        result.last.trim().isNotEmpty) {
      result.add('');
    }

    result.add(line);
    previousWasTable = isTable;
  }

  for (final originalLine in lines) {
    var line = originalLine;
    final trimmedLeft = line.trimLeft();

    if (trimmedLeft.startsWith('```') || trimmedLeft.startsWith('~~~')) {
      inFence = !inFence;
      result.add(line);
      previousWasTable = false;
      continue;
    }

    if (!inFence) {
      line = line.replaceFirstMapped(
        RegExp(r'^(#{1,6})(\S)'),
        (match) => '${match.group(1)} ${match.group(2)}',
      );
      final headingTableMatch = RegExp(
        r'^(#{1,6}\s+)([^|\n]+?)\s*(\|.*\|)\s*$',
      ).firstMatch(line);
      if (headingTableMatch != null) {
        appendNormalizedLine(
          '${headingTableMatch.group(1)}${headingTableMatch.group(2)?.trim()}',
        );
        for (final expandedLine in _expandCompressedTableLines(
          headingTableMatch.group(3) ?? '',
        )) {
          appendNormalizedLine(expandedLine);
        }
        continue;
      }
    }

    final expandedLines = !inFence ? _expandCompressedTableLines(line) : [line];
    for (final expandedLine in expandedLines) {
      appendNormalizedLine(expandedLine);
    }
  }

  return result.join('\n').trim();
}

List<String> _expandCompressedTableLines(String line) {
  final expanded = line
      .replaceAllMapped(
        RegExp(r'\|\s*(#{1,6}\s+)'),
        (match) => '|\n\n${match.group(1)}',
      )
      .replaceAllMapped(
        RegExp(r'\|\|\s*(?=:?-{2,}:?(?:\s*\||$))'),
        (_) => '|\n|',
      )
      .replaceAllMapped(
        RegExp(r'\|\|\s*(?=(?:\*\*)?[^|\s#-])'),
        (_) => '|\n| ',
      );
  return expanded.split('\n');
}

bool _isLikelyMarkdownTableLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;
  return '|'.allMatches(trimmed).length >= 2;
}

List<_MarkdownSegment> _splitMarkdownSegments(String source) {
  final lines = source.split('\n');
  final segments = <_MarkdownSegment>[];
  final textBuffer = <String>[];
  var index = 0;
  var inFence = false;

  void flushText() {
    final text = textBuffer.join('\n').trim();
    if (text.isNotEmpty) {
      segments.add(_MarkdownSegment.text(text));
    }
    textBuffer.clear();
  }

  String? takeTrailingHeading() {
    var index = textBuffer.length - 1;
    while (index >= 0 && textBuffer[index].trim().isEmpty) {
      index--;
    }
    if (index < 0) return null;
    final match = RegExp(
      r'^\s*#{1,6}\s+(.+?)\s*$',
    ).firstMatch(textBuffer[index]);
    if (match == null) return null;
    final title = match.group(1)?.trim();
    textBuffer.removeRange(index, textBuffer.length);
    return title == null || title.isEmpty ? null : title;
  }

  while (index < lines.length) {
    final line = lines[index];
    final trimmedLeft = line.trimLeft();
    if (trimmedLeft.startsWith('```') || trimmedLeft.startsWith('~~~')) {
      inFence = !inFence;
      textBuffer.add(line);
      index++;
      continue;
    }

    if (!inFence &&
        _isLikelyMarkdownTableLine(line) &&
        index + 1 < lines.length &&
        _isLikelyMarkdownTableLine(lines[index + 1])) {
      final separator = _splitMarkdownTableRow(lines[index + 1]);
      if (_isMarkdownSeparatorRow(separator)) {
        final tableLines = <String>[line, lines[index + 1]];
        index += 2;
        while (index < lines.length &&
            _isLikelyMarkdownTableLine(lines[index])) {
          tableLines.add(lines[index]);
          index++;
        }
        final table = _parseMarkdownTable(tableLines);
        if (table != null) {
          final title = takeTrailingHeading();
          flushText();
          segments.add(_MarkdownSegment.table(table.copyWith(title: title)));
          continue;
        }
      } else {
        textBuffer.add(line);
        index++;
        continue;
      }
    }

    textBuffer.add(line);
    index++;
  }

  flushText();
  return segments.isEmpty ? [_MarkdownSegment.text(source)] : segments;
}

_AgentMarkdownTableData? _parseMarkdownTable(List<String> lines) {
  if (lines.length < 2) return null;
  final header = _splitMarkdownTableRow(lines.first);
  final separator = _splitMarkdownTableRow(lines[1]);
  if (header.isEmpty || !_isMarkdownSeparatorRow(separator)) return null;
  final rows = <List<String>>[];
  for (final line in lines.skip(2)) {
    final row = _splitMarkdownTableRow(line);
    if (row.any((cell) => cell.trim().isNotEmpty)) {
      rows.add(row);
    }
  }
  if (rows.isEmpty) return null;
  return _AgentMarkdownTableData(header: header, rows: rows);
}

List<String> _splitMarkdownTableRow(String line) {
  var value = line.trim();
  if (value.startsWith('|')) value = value.substring(1);
  if (value.endsWith('|')) value = value.substring(0, value.length - 1);
  return value.split('|').map((cell) => cell.trim()).toList();
}

bool _isMarkdownSeparatorRow(List<String> cells) {
  if (cells.isEmpty) return false;
  return cells.every((cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell.trim()));
}

class _MarkdownSegment {
  const _MarkdownSegment._({this.text = '', this.table});

  factory _MarkdownSegment.text(String text) => _MarkdownSegment._(text: text);

  factory _MarkdownSegment.table(_AgentMarkdownTableData table) {
    return _MarkdownSegment._(table: table);
  }

  final String text;
  final _AgentMarkdownTableData? table;
}

class _AgentMarkdownTableData {
  const _AgentMarkdownTableData({
    required this.header,
    required this.rows,
    this.title,
  });

  final List<String> header;
  final List<List<String>> rows;
  final String? title;

  _AgentMarkdownTableData copyWith({String? title}) {
    return _AgentMarkdownTableData(
      header: header,
      rows: rows,
      title: title ?? this.title,
    );
  }
}

class _AgentMarkdownTable extends StatelessWidget {
  const _AgentMarkdownTable({
    required this.table,
    required this.styleSheet,
    required this.colorScheme,
  });

  final _AgentMarkdownTableData table;
  final MarkdownStyleSheet styleSheet;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final title = table.title?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${table.rows.length} 条',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++)
            _AgentMarkdownTableRowCard(
              header: table.header,
              row: table.rows[rowIndex],
              styleSheet: styleSheet,
              colorScheme: colorScheme,
              isLast: rowIndex == table.rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _AgentMarkdownTableRowCard extends StatelessWidget {
  const _AgentMarkdownTableRowCard({
    required this.header,
    required this.row,
    required this.styleSheet,
    required this.colorScheme,
    required this.isLast,
  });

  final List<String> header;
  final List<String> row;
  final MarkdownStyleSheet styleSheet;
  final ColorScheme colorScheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final title = row.isEmpty ? '' : row.first;
    final metaValues = row.length <= 1 ? <String>[] : row.skip(1).toList();
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            _AgentMarkdownTableLabel(
              label: _tableHeaderAt(header, 0),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 3),
            _AgentMarkdownCell(
              markdown: title,
              styleSheet: _agentMarkdownCellStyle(
                styleSheet,
                colorScheme,
                isPrimary: true,
              ),
            ),
          ],
          if (metaValues.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var index = 0; index < metaValues.length; index++)
                  _AgentMarkdownTableChip(
                    label: _tableHeaderAt(header, index + 1),
                    value: metaValues[index],
                    styleSheet: _agentMarkdownCellStyle(
                      styleSheet,
                      colorScheme,
                    ),
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AgentMarkdownTableChip extends StatelessWidget {
  const _AgentMarkdownTableChip({
    required this.label,
    required this.value,
    required this.styleSheet,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final MarkdownStyleSheet styleSheet;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _AgentMarkdownTableLabel(
                label: label,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: _AgentMarkdownCell(markdown: value, styleSheet: styleSheet),
          ),
        ],
      ),
    );
  }
}

class _AgentMarkdownTableLabel extends StatelessWidget {
  const _AgentMarkdownTableLabel({
    required this.label,
    required this.colorScheme,
  });

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Text(
      label,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: 0,
      ),
    );
  }
}

class _AgentMarkdownCell extends StatelessWidget {
  const _AgentMarkdownCell({required this.markdown, required this.styleSheet});

  final String markdown;
  final MarkdownStyleSheet styleSheet;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown.trim().isEmpty ? '-' : markdown.trim(),
      selectable: true,
      fitContent: true,
      shrinkWrap: true,
      softLineBreak: true,
      styleSheet: styleSheet,
      onTapLink: (_, href, __) {
        if (href == null || href.trim().isEmpty) return;
        WebUtil.open(url: href);
      },
    );
  }
}

MarkdownStyleSheet _agentMarkdownCellStyle(
  MarkdownStyleSheet base,
  ColorScheme colorScheme, {
  bool isPrimary = false,
}) {
  final style = base.p?.copyWith(
    fontSize: isPrimary ? 15 : 13,
    fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
    height: isPrimary ? 1.32 : 1.25,
    color: colorScheme.onSurface,
  );
  return base.copyWith(
    p: style,
    pPadding: EdgeInsets.zero,
    strong: style?.copyWith(fontWeight: FontWeight.w900),
    tablePadding: EdgeInsets.zero,
  );
}

String _tableHeaderAt(List<String> header, int index) {
  if (index >= header.length) return '';
  return header[index].trim();
}

class _ToolEvents extends StatelessWidget {
  const _ToolEvents({required this.tools});

  final List<AgentToolEvent> tools;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tool in tools)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.wand_stars,
                    size: 13,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tool.message.isEmpty ? '工具执行完成' : tool.message,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({required this.attachments});

  final List<AgentAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final attachment in attachments)
          attachment.isImage
              ? _ImageAttachment(attachment: attachment)
              : _FileAttachment(attachment: attachment),
      ],
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.attachment});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final url = ImageUtil.convertCacheImageUrl(attachment.url);
    return GestureDetector(
      onTap: attachment.url.isEmpty
          ? null
          : () => WebUtil.open(url: attachment.url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedImage(
          imageUrl: url,
          width: 118,
          height: 86,
          fit: BoxFit.cover,
          errorWidget: _AttachmentFallback(icon: CupertinoIcons.photo),
        ),
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.attachment});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = attachment.name.isNotEmpty ? attachment.name : '附件';
    return InkWell(
      onTap: attachment.url.isEmpty
          ? null
          : () => WebUtil.open(url: attachment.url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.76),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_text_fill,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentFallback extends StatelessWidget {
  const _AttachmentFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(icon, size: 24)),
    );
  }
}
