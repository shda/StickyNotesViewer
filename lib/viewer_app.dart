import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'markdown_styles.dart';
import 'notes_store.dart';
import 'widgets/config_dialog.dart';
import 'widgets/title_bar.dart';
import 'widgets/window_settings_dialog.dart';
import 'window_constants.dart';
import 'windows_file_dialog.dart';

class ViewerApp extends StatefulWidget {
  const ViewerApp({super.key});

  @override
  State<ViewerApp> createState() => _ViewerAppState();
}

class _ViewerAppState extends State<ViewerApp> with WidgetsBindingObserver {
  String? _markdown;
  String? _fileName;
  String? _filePath;
  String? _noteId;
  WindowController? _windowController;
  NotesStore? _store;
  Timer? _boundsTimer;
  Timer? _watchTimer;
  Timer? _settingsDebounce;
  DateTime? _lastModified;
  bool _focused = false;
  bool _hovered = false;
  bool _watchEnabled = false;
  double _fontScale = 1.0;
  Color _titleColor = kDefaultTitleColor;

  bool get _interactive => _focused || _hovered;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWindow());
  }

  @override
  void dispose() {
    _boundsTimer?.cancel();
    _watchTimer?.cancel();
    _settingsDebounce?.cancel();
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

  String? _noteIdFromArguments(String arguments) {
    const prefix = '$viewerArgument:';
    if (arguments.startsWith(prefix)) {
      return arguments.substring(prefix.length);
    }
    return null;
  }

  Future<void> _showWindow() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      try {
        final controller = await WindowController.fromCurrentEngine();
        _windowController = controller;
        final store = await NotesStore.open();
        _store = store;

        final noteId = _noteIdFromArguments(controller.arguments);
        if (noteId == null) {
          await controller.setTitle('app_title'.tr());
        } else {
          final note = await store.findById(noteId);
          final file = note == null ? null : File(note.filePath);
          if (note == null || file == null || !await file.exists()) {
            if (note != null) {
              await store.remove(noteId);
            }
            await controller.close();
            return;
          }
          await controller.setBounds(WindowBounds(
            x: note.x,
            y: note.y,
            width: note.width,
            height: note.height,
          ));
          final content = await file.readAsString(encoding: utf8);
          final fileName = file.uri.pathSegments.last;
          await controller.setTitle(fileName);
          setState(() {
            _noteId = noteId;
            _markdown = content;
            _fileName = fileName;
            _filePath = note.filePath;
            _watchEnabled = note.watchEnabled;
            _fontScale = note.fontScale;
            _titleColor = Color(note.titleColor);
          });
          if (_watchEnabled) {
            _startWatching();
          }
        }

        _boundsTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _saveBounds(),
        );
        await controller.show();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _saveBounds() async {
    final noteId = _noteId;
    final controller = _windowController;
    final store = _store;
    if (noteId == null || controller == null || store == null) {
      return;
    }
    try {
      final bounds = await controller.getBounds();
      if (bounds == null) {
        return;
      }
      await store.updateBounds(
        noteId,
        x: bounds.x,
        y: bounds.y,
        width: bounds.width,
        height: bounds.height,
      );
    } catch (_) {}
  }

  Future<void> _openFile() async {
    final nativeHandle = await _windowController?.getNativeHandle();
    final path = await pickMarkdownFile(
      parentWindowHandle: nativeHandle,
      dialogTitle: 'pick_file_dialog_title'.tr(),
    );

    if (path == null) {
      return;
    }

    final file = File(path);
    final content = await file.readAsString(encoding: utf8);
    final fileName = file.uri.pathSegments.last;

    setState(() {
      _markdown = content;
      _fileName = fileName;
      _filePath = file.path;
    });

    final store = _store;
    final controller = _windowController;
    if (store == null || controller == null) {
      return;
    }
    try {
      if (_noteId == null) {
        final bounds = await controller.getBounds();
        final note = NoteEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          filePath: file.path,
          x: bounds?.x ?? 0,
          y: bounds?.y ?? 0,
          width: bounds?.width ?? 800,
          height: bounds?.height ?? 600,
          watchEnabled: _watchEnabled,
          fontScale: _fontScale,
          titleColor: _titleColor.toARGB32(),
        );
        await store.add(note);
        _noteId = note.id;
      } else {
        await store.updateFilePath(_noteId!, file.path);
      }
      await controller.setTitle(fileName);
      if (_watchEnabled) {
        _startWatching();
      }
    } catch (_) {}
  }

  void _startWatching() {
    _stopWatching();
    final path = _filePath;
    if (path == null || !_watchEnabled) {
      return;
    }
    _lastModified = null;
    _watchTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkFileChanged(),
    );
    _checkFileChanged();
  }

  void _stopWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  Future<void> _checkFileChanged() async {
    final path = _filePath;
    if (path == null || !_watchEnabled) {
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        return;
      }
      final modified = await file.lastModified();
      if (_lastModified != null && modified == _lastModified) {
        return;
      }
      _lastModified = modified;
      final content = await file.readAsString(encoding: utf8);
      if (!mounted) {
        return;
      }
      setState(() => _markdown = content);
    } catch (_) {}
  }

  Future<void> _toggleWatch() async {
    setState(() => _watchEnabled = !_watchEnabled);
    final store = _store;
    final noteId = _noteId;
    if (store != null && noteId != null) {
      try {
        await store.updateWatchEnabled(noteId, _watchEnabled);
      } catch (_) {}
    }
    if (_watchEnabled) {
      _startWatching();
    } else {
      _stopWatching();
    }
  }

  Future<void> _openWindowSettings(BuildContext context) {
    return showWindowSettingsDialog(
      context,
      initialFontScale: _fontScale,
      initialTitleColor: _titleColor,
      onChanged: _onWindowSettingsChanged,
    );
  }

  void _onWindowSettingsChanged(double fontScale, Color titleColor) {
    setState(() {
      _fontScale = fontScale;
      _titleColor = titleColor;
    });
    _settingsDebounce?.cancel();
    _settingsDebounce = Timer(const Duration(milliseconds: 500), () {
      _persistWindowSettings();
    });
  }

  Future<void> _persistWindowSettings() async {
    final store = _store;
    final noteId = _noteId;
    if (store == null || noteId == null) {
      return;
    }
    try {
      await store.updateWindowSettings(
        noteId,
        fontScale: _fontScale,
        titleColor: _titleColor.toARGB32(),
      );
    } catch (_) {}
  }

  Future<void> _openNewWindow() async {
    await WindowController.create(
      const WindowConfiguration(
        arguments: viewerArgument,
        hiddenAtLaunch: true,
      ),
    );
  }

  Future<void> _closeWindow() async {
    _boundsTimer?.cancel();
    _stopWatching();
    final store = _store;
    final noteId = _noteId;
    if (store != null && noteId != null) {
      try {
        await store.remove(noteId);
      } catch (_) {}
    }
    await _windowController?.close();
  }

  String? get _markdownImageDirectory {
    final path = _filePath;
    if (path == null) {
      return null;
    }
    final dir = File(path).parent.path.replaceAll('\\', '/');
    return 'file:///$dir/';
  }

  String _normalizeMarkdownImages(String md) {
    // Translate Obsidian-style sizing "![alt|W](src)" / "![alt|WxH](src)" into
    // the flutter_markdown_plus syntax "![alt](src#WxH)" so the default image
    // builder applies the requested dimensions.
    return md.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\|(\d+)(?:x(\d+))?\]\(([^)]+)\)'),
      (m) {
        final alt = m.group(1)!;
        final width = m.group(2)!;
        final height = m.group(3);
        final src = m.group(4)!;
        final dim = '${width}x${height ?? width}';
        return '![$alt]($src#$dim)';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_title'.tr(),
      themeMode: ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        scaffoldBackgroundColor: const Color(0xFF333333),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Scaffold(
            body: Column(
              children: [
                TitleBar(
                  title: _fileName ?? 'app_title'.tr(),
                  focused: _interactive,
                  color: _titleColor,
                  onDragStart: () => _windowController?.startDrag(),
                  onClose: _closeWindow,
                  onOpenConfig: () => showConfigDialog(context),
                  onOpenWindowSettings: () => _openWindowSettings(context),
                  showWatchButton: _fileName != null,
                  watchEnabled: _watchEnabled,
                  onToggleWatch: _toggleWatch,
                ),
              Expanded(
                child: _markdown == null
                    ? Center(
                        child: Text(
                          'empty_note'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Markdown(
                        data: _normalizeMarkdownImages(_markdown!),
                        selectable: true,
                        styleSheet: darkMarkdownStyleSheet(
                          context,
                          scale: _fontScale,
                        ),
                        imageDirectory: _markdownImageDirectory,
                      ),
              ),
            ],
          ),
          floatingActionButton: IgnorePointer(
            ignoring: !_interactive,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              opacity: _interactive ? 1 : 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'new-window',
                    onPressed: _openNewWindow,
                    tooltip: 'new_window'.tr(),
                    child: const Icon(Icons.open_in_new),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'open-file',
                    onPressed: _openFile,
                    tooltip: 'open_file'.tr(),
                    child: const Icon(Icons.folder_open),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
