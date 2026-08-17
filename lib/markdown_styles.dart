import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

MarkdownStyleSheet darkMarkdownStyleSheet(BuildContext context,
    {double scale = 1.0, double lineHeight = 1.4}) {
  return MarkdownStyleSheet.fromTheme(
    Theme.of(context),
  ).copyWith(
    p: TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    listBullet: TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    h1: TextStyle(
      color: Colors.white,
      fontSize: 28 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h2: TextStyle(
      color: Colors.white,
      fontSize: 24 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h3: TextStyle(
      color: Colors.white,
      fontSize: 20 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h4: TextStyle(
      color: Colors.white,
      fontSize: 18 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h5: TextStyle(
      color: Colors.white,
      fontSize: 17 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    h6: TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    ),
    a: TextStyle(
      color: const Color(0xFF81D4FA),
      decoration: TextDecoration.underline,
    ),
    blockquote: TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      border: const Border(
        left: BorderSide(color: Colors.white70, width: 3),
      ),
    ),
    code: const TextStyle(
      color: Color(0xFFE0E0E0),
      backgroundColor: Color(0xFF2A2A2A),
    ),
    codeblockDecoration: const BoxDecoration(
      color: Color(0xFF2A2A2A),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    tableHead: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: lineHeight,
    ),
    tableBody: TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      height: lineHeight,
    ),
    tableBorder: TableBorder.all(color: Colors.white24),
    blockSpacing: 8.0 * lineHeight / 1.4,
    h1Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h2Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
    pPadding: const EdgeInsets.symmetric(vertical: 6),
  );
}
