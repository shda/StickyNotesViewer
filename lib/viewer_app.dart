import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'markdown_styles.dart';
import 'widgets/title_bar.dart';
import 'window_constants.dart';

class ViewerApp extends StatefulWidget {
  const ViewerApp({super.key});

  @override
  State<ViewerApp> createState() => _ViewerAppState();
}

class _ViewerAppState extends State<ViewerApp> with WidgetsBindingObserver {
  String? _markdown;
  String? _fileName;
  WindowController? _windowController;
  bool _focused = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWindow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focused = state == AppLifecycleState.resumed;
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  Future<void> _showWindow() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      try {
        final controller = await WindowController.fromCurrentEngine();
        _windowController = controller;
        await controller.show();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

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

  Future<void> _openNewWindow() async {
    await WindowController.create(
      const WindowConfiguration(
        arguments: viewerArgument,
        hiddenAtLaunch: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Notes Viewer',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        scaffoldBackgroundColor: const Color(0xFF333333),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Column(
          children: [
            TitleBar(
              title: _fileName ?? 'Sticky Notes Viewer',
              focused: _focused,
              onDragStart: () => _windowController?.startDrag(),
              onClose: () => _windowController?.close(),
            ),
            Expanded(
              child: _markdown == null
                  ? const Center(
                      child: Text(
                        'Откройте Markdown файл',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    )
                  : Markdown(
                      data: _markdown!,
                      selectable: true,
                      styleSheet: darkMarkdownStyleSheet(context),
                    ),
            ),
          ],
        ),
        floatingActionButton: IgnorePointer(
          ignoring: !_focused,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            opacity: _focused ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'new-window',
                  onPressed: _openNewWindow,
                  tooltip: 'Новое окно',
                  child: const Icon(Icons.open_in_new),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'open-file',
                  onPressed: _openFile,
                  tooltip: 'Открыть файл',
                  child: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
