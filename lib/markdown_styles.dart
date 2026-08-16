import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

MarkdownStyleSheet darkMarkdownStyleSheet(BuildContext context) {
  return MarkdownStyleSheet.fromTheme(
    Theme.of(context),
  ).copyWith(
    p: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      height: 1.4,
    ),
    h1: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    h2: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    h3: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
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
    tableHead: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    tableBody: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    tableBorder: TableBorder.all(color: Colors.white24),
    h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
    h2Padding: const EdgeInsets.only(top: 16, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
    pPadding: const EdgeInsets.symmetric(vertical: 6),
  );
}
