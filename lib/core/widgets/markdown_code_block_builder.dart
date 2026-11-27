import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom [MarkdownElementBuilder] for fenced code blocks (`<pre>`) that adds
/// a header bar with language label, a copy-to-clipboard button, and
/// horizontal scrolling for long lines.
class MarkdownCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawCode = element.textContent;
    final code = rawCode.endsWith('\n')
        ? rawCode.substring(0, rawCode.length - 1)
        : rawCode;

    String language = '';
    if (element.children != null && element.children!.isNotEmpty) {
      final firstChild = element.children!.first;
      if (firstChild is md.Element && firstChild.tag == 'code') {
        final className = firstChild.attributes['class'] ?? '';
        if (className.startsWith('language-')) {
          language = className.substring('language-'.length);
        }
      }
    }

    return _CodeBlockView(code: code, language: language);
  }
}

class _CodeBlockView extends StatefulWidget {
  final String code;
  final String language;

  const _CodeBlockView({required this.code, required this.language});

  @override
  State<_CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<_CodeBlockView> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D7DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFEAEFF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D7DE)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language.isEmpty ? 'code' : widget.language,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF57606A),
                  ),
                ),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _copied
                              ? Colors.green.shade700
                              : const Color(0xFF57606A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Disalin' : 'Salin',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _copied
                                ? Colors.green.shade700
                                : const Color(0xFF57606A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF24292F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
