import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import 'notes_store.dart';
import 'window_constants.dart';

class ManagerApp extends StatefulWidget {
  const ManagerApp({super.key});

  @override
  State<ManagerApp> createState() => _ManagerAppState();
}

class _ManagerAppState extends State<ManagerApp> {
  StreamSubscription<void>? _windowsSub;
  Timer? _debounce;
  bool _creatingViewer = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _hideManagerWindow();
    _restoreNotes();
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

  Future<void> _restoreNotes() async {
    _restoring = true;
    try {
      final store = await NotesStore.open();
      final notes = await store.load();
      if (notes.isEmpty) {
        await _createFreshViewer();
        return;
      }
      for (final note in notes) {
        try {
          final file = File(note.filePath);
          if (!await file.exists()) {
            await store.remove(note.id);
            continue;
          }
          await WindowController.create(
            WindowConfiguration(
              arguments: '$viewerArgument:${note.id}',
              hiddenAtLaunch: true,
            ),
          );
        } catch (_) {}
      }
    } catch (_) {
      try {
        await _createFreshViewer();
      } catch (_) {}
    } finally {
      _restoring = false;
    }
  }

  void _scheduleEnsureViewer() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _ensureViewer);
  }

  Future<void> _ensureViewer() async {
    if (_creatingViewer || _restoring) {
      return;
    }
    _creatingViewer = true;
    try {
      final windows = await WindowController.getAll();
      final hasViewer = windows.any(
        (w) =>
            w.arguments == viewerArgument ||
            w.arguments.startsWith('$viewerArgument:'),
      );
      if (!hasViewer) {
        await _createFreshViewer();
      }
    } catch (_) {
    } finally {
      _creatingViewer = false;
    }
  }

  Future<void> _createFreshViewer() async {
    await WindowController.create(
      const WindowConfiguration(
        arguments: viewerArgument,
        hiddenAtLaunch: false,
      ),
    );
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
