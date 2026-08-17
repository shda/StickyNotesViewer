import 'dart:convert';
import 'dart:io';

import 'notes_store.dart';

const kSupportedLanguageCodes = ['en', 'ru'];

const kDefaultLanguageCode = 'en';

const kMarkdownThemes = ['dark', 'light'];

const kDefaultMarkdownTheme = 'dark';

class AppSettings {
  AppSettings._(this._file);

  final File _file;

  static Future<AppSettings> open() async {
    final dir = appDataDirectory();
    await dir.create(recursive: true);
    return AppSettings._(
        File('${dir.path}${Platform.pathSeparator}settings.json'));
  }

  Future<Map<String, dynamic>> _readAll() async {
    try {
      if (!await _file.exists()) {
        return {};
      }
      final json =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      return json;
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    try {
      final all = await _readAll();
      all.addAll(patch);
      await _file.writeAsString(jsonEncode(all));
    } catch (_) {}
  }

  Future<String> loadLanguageCode() async {
    final code = (await _readAll())['language'] as String?;
    if (code != null && kSupportedLanguageCodes.contains(code)) {
      return code;
    }
    return kDefaultLanguageCode;
  }

  Future<void> saveLanguageCode(String code) async {
    if (!kSupportedLanguageCodes.contains(code)) {
      return;
    }
    await _save({'language': code});
  }

  Future<String> loadMarkdownTheme() async {
    final theme = (await _readAll())['mdTheme'] as String?;
    if (theme != null && kMarkdownThemes.contains(theme)) {
      return theme;
    }
    return kDefaultMarkdownTheme;
  }

  Future<void> saveMarkdownTheme(String theme) async {
    if (!kMarkdownThemes.contains(theme)) {
      return;
    }
    await _save({'mdTheme': theme});
  }
}
