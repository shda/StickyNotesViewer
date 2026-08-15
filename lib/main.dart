import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const viewerArgument = 'viewer';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.contains(viewerArgument)) {
    runApp(const ViewerApp());
  } else {
    runApp(const ManagerApp());
  }
}

class ManagerApp extends StatefulWidget {
  const ManagerApp({super.key});

  @override
  State<ManagerApp> createState() => _ManagerAppState();
}

class _ManagerAppState extends State<ManagerApp> {
  StreamSubscription<void>? _windowsSub;
  Timer? _debounce;
  bool _creatingViewer = false;

  @override
  void initState() {
    super.initState();
    _hideManagerWindow();
    _ensureViewer();
    _windowsSub = onWindowsChanged.listen((_) => _scheduleEnsureViewer());
  }

  void _hideManagerWindow() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _hideNow());
    Future<void>.delayed(const Duration(milliseconds: 500), _hideNow);
  }

  Future<void> _hideNow() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      await controller.hide();
    } catch (_) {}
  }

  void _scheduleEnsureViewer() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _ensureViewer);
  }

  Future<void> _ensureViewer() async {
    if (_creatingViewer) {
      return;
    }
    _creatingViewer = true;
    try {
      final windows = await WindowController.getAll();
      final hasViewer = windows.any((w) => w.arguments == viewerArgument);
      if (!hasViewer) {
        await WindowController.create(
          const WindowConfiguration(
            arguments: viewerArgument,
            hiddenAtLaunch: false,
          ),
        );
      }
    } catch (_) {
    } finally {
      _creatingViewer = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _windowsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: SizedBox()));
  }
}

class ViewerApp extends StatefulWidget {
  const ViewerApp({super.key});

  @override
  State<ViewerApp> createState() => _ViewerAppState();
}

class _ViewerAppState extends State<ViewerApp> {
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

  Future<void> _openNewWindow() async {
    await WindowController.create(
      const WindowConfiguration(
        arguments: viewerArgument,
        hiddenAtLaunch: false,
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
        floatingActionButton: Column(
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
    );
  }
}
