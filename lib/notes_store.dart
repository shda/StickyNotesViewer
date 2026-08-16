import 'dart:convert';
import 'dart:io';

class NoteEntry {
  NoteEntry({
    required this.id,
    required this.filePath,
    this.x = 0,
    this.y = 0,
    this.width = 800,
    this.height = 600,
  });

  factory NoteEntry.fromJson(Map<String, dynamic> json) {
    return NoteEntry(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 800,
      height: (json['height'] as num?)?.toDouble() ?? 600,
    );
  }

  final String id;
  String filePath;
  double x;
  double y;
  double width;
  double height;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

Directory _dataDirectory() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    final base = (appData != null && appData.isNotEmpty)
        ? appData
        : Directory.current.path;
    return Directory('$base${Platform.pathSeparator}StickyNotesViewer');
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return Directory(
        '$home/Library/Application Support/StickyNotesViewer');
  }
  return Directory(
      '${Directory.current.path}${Platform.pathSeparator}StickyNotesViewer');
}

class NotesStore {
  NotesStore._(this._file);

  final File _file;

  static Future<NotesStore> open() async {
    final dir = _dataDirectory();
    await dir.create(recursive: true);
    return NotesStore._(File('${dir.path}${Platform.pathSeparator}notes.json'));
  }

  Future<List<NoteEntry>> load() async {
    try {
      if (!await _file.exists()) {
        return [];
      }
      final raw = await _file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = json['notes'] as List<dynamic>? ?? const [];
      return list
          .map((e) => NoteEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<NoteEntry?> findById(String id) async {
    final notes = await load();
    for (final note in notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }

  Future<void> _save(List<NoteEntry> notes) async {
    final content = jsonEncode({
      'notes': notes.map((n) => n.toJson()).toList(),
    });
    final tmp = File(
        '${_file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await tmp.writeAsString(content);
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (await _file.exists()) {
          await _file.delete();
        }
        await tmp.rename(_file.path);
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    try {
      await _file.writeAsString(content);
    } catch (_) {}
    try {
      if (await tmp.exists()) {
        await tmp.delete();
      }
    } catch (_) {}
  }

  Future<void> add(NoteEntry note) async {
    final notes = await load();
    notes.removeWhere((n) => n.id == note.id);
    notes.add(note);
    await _save(notes);
  }

  Future<void> updateBounds(
    String id, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final notes = await load();
    final index = notes.indexWhere((n) => n.id == id);
    if (index < 0) {
      return;
    }
    final note = notes[index];
    note.x = x;
    note.y = y;
    note.width = width;
    note.height = height;
    await _save(notes);
  }

  Future<void> updateFilePath(String id, String filePath) async {
    final notes = await load();
    final index = notes.indexWhere((n) => n.id == id);
    if (index < 0) {
      return;
    }
    notes[index].filePath = filePath;
    await _save(notes);
  }

  Future<void> remove(String id) async {
    final notes = await load();
    notes.removeWhere((n) => n.id == id);
    await _save(notes);
  }
}
