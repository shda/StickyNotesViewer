import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

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
