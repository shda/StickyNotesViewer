import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Markdown style sheet for the note content area.
///
/// [dark] selects the colour scheme:
/// - `true`  — dark background (#333333) with white elements (default);
/// - `false` — light background (#F7F7F7) with black elements.
MarkdownStyleSheet markdownStyleSheet(BuildContext context,
    {double scale = 1.0, double lineHeight = 1.4, bool dark = true}) {
  final text = dark ? Colors.white : const Color(0xFF1A1A1A);
  final secondary = dark ? const Color(0xFFE0E0E0) : const Color(0xFF555555);
  final codeBg = dark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
  final link = dark ? const Color(0xFF81D4FA) : const Color(0xFF1565C0);
  final border = dark ? Colors.white70 : Colors.black54;
  final tableBorder = dark ? Colors.white24 : Colors.black12;

  return MarkdownStyleSheet.fromTheme(
    Theme.of(context),
  ).copyWith(
    p: TextStyle(
      color: text,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    listBullet: TextStyle(
      color: text,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    h1: TextStyle(
      color: text,
      fontSize: 28 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h2: TextStyle(
      color: text,
      fontSize: 24 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h3: TextStyle(
      color: text,
      fontSize: 20 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h4: TextStyle(
      color: text,
      fontSize: 18 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h5: TextStyle(
      color: text,
      fontSize: 17 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h6: TextStyle(
      color: text,
      fontSize: 16 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    a: TextStyle(
      color: link,
      decoration: TextDecoration.underline,
    ),
    blockquote: TextStyle(
      color: text,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    blockquoteDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: BorderRadius.all(Radius.circular(4)),
      border: Border(
        left: BorderSide(color: border, width: 3),
      ),
    ),
    code: TextStyle(
      color: secondary,
      backgroundColor: codeBg,
    ),
    codeblockDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    tableHead: TextStyle(
      color: text,
      fontWeight: FontWeight.w600,
      height: lineHeight,
    ),
    tableBody: TextStyle(
      color: text,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    tableBorder: TableBorder.all(color: tableBorder),
    blockSpacing: 8.0 * lineHeight / 1.4,
    h1Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h2Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
    pPadding: const EdgeInsets.symmetric(vertical: 6),
  );
}
