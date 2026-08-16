import 'dart:convert';
import 'dart:io';

import 'notes_store.dart';

const kSupportedLanguageCodes = ['en', 'ru'];

const kDefaultLanguageCode = 'en';

class AppSettings {
  AppSettings._(this._file);

  final File _file;

  static Future<AppSettings> open() async {
    final dir = appDataDirectory();
    await dir.create(recursive: true);
    return AppSettings._(
        File('${dir.path}${Platform.pathSeparator}settings.json'));
  }

  Future<String> loadLanguageCode() async {
    try {
      if (!await _file.exists()) {
        return kDefaultLanguageCode;
      }
      final json =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      final code = json['language'] as String?;
      if (code != null && kSupportedLanguageCodes.contains(code)) {
        return code;
      }
    } catch (_) {}
    return kDefaultLanguageCode;
  }

  Future<void> saveLanguageCode(String code) async {
    if (!kSupportedLanguageCodes.contains(code)) {
      return;
    }
    try {
      await _file.writeAsString(jsonEncode({'language': code}));
    } catch (_) {}
  }
}
