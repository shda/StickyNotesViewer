import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? _markdown;
  String? _fileName;

  Future<void> _openFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown'],
      dialogTitle: 'Открыть Markdown файл',
    );

    if (result == null || result.path == null) {
      return;
    }

    final file = File(result.path!);
    final content = await file.readAsString(encoding: utf8);

    setState(() {
      _markdown = content;
      _fileName = file.uri.pathSegments.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Notes Viewer',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: _fileName == null
            ? null
            : AppBar(
                title: Text(_fileName!),
                centerTitle: true,
              ),
        body: _markdown == null
            ? const Center(
                child: Text(
                  'Откройте Markdown файл',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Markdown(
                data: _markdown!,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  h1: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  code: const TextStyle(
                    color: Colors.black87,
                    backgroundColor: Color(0xFFF0F0F0),
                  ),
                  codeblockDecoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
                  h2Padding: const EdgeInsets.only(top: 16, bottom: 8),
                  h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
                  pPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openFile,
          tooltip: 'Открыть файл',
          child: const Icon(Icons.folder_open),
        ),
      ),
    );
  }
}
