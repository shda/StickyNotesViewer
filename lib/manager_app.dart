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
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _restoring = true;
    _startup();
    _windowsSub = onWindowsChanged.listen((_) => _scheduleWindowsCheck());
  }

  Future<void> _startup() async {
    await _hideManagerWindow();
    await _restoreNotes();
  }

  Future<void> _hideManagerWindow() async {
    WidgetsBinding.instance.addPostFrameCallback((_) => _hideNow());
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _hideNow();
  }

  Future<void> _hideNow() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      await controller.hide();
    } catch (_) {}
  }

  Future<void> _restoreNotes() async {
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
      _scheduleWindowsCheck();
    }
  }

  void _scheduleWindowsCheck() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _checkWindowsAndExit);
  }

  Future<void> _checkWindowsAndExit() async {
    if (_restoring) {
      return;
    }
    try {
      final windows = await WindowController.getAll();
      final hasViewer = windows.any(
        (w) =>
            w.arguments == viewerArgument ||
            w.arguments.startsWith('$viewerArgument:'),
      );
      if (!hasViewer) {
        exit(0);
      }
    } catch (_) {}
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
