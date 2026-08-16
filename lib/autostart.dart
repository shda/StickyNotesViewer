import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Manages the "run at Windows login" (autostart) registry entry for the app.
///
/// Windows-only; methods are no-ops returning `false` on other platforms.
class Autostart {
  Autostart._();

  static const String _runKey =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _valueName = 'StickyNotesViewer';

  /// Whether the app is currently registered to launch at Windows login.
  static bool isEnabled() {
    if (!Platform.isWindows) {
      return false;
    }
    return using((arena) {
      final data = arena<Uint8>(1024);
      final dataSize = arena<Uint32>()..value = 1024;
      final result = RegGetValue(
        HKEY_CURRENT_USER,
        arena.pcwstr(_runKey),
        arena.pcwstr(_valueName),
        RRF_RT_REG_SZ,
        nullptr,
        data.cast(),
        dataSize,
      );
      return result == ERROR_SUCCESS;
    });
  }

  /// Registers or unregisters the app for launch at Windows login.
  ///
  /// Returns `true` on success.
  static bool setEnabled(bool enabled) {
    if (!Platform.isWindows) {
      return false;
    }
    return using((arena) {
      if (enabled) {
        final value = '"${Platform.resolvedExecutable}"';
        final data = arena.pcwstr(value);
        final result = RegSetKeyValue(
          HKEY_CURRENT_USER,
          arena.pcwstr(_runKey),
          arena.pcwstr(_valueName),
          REG_SZ,
          data.cast(),
          (value.length + 1) * 2,
        );
        return result == ERROR_SUCCESS;
      }
      final result = RegDeleteKeyValue(
        HKEY_CURRENT_USER,
        arena.pcwstr(_runKey),
        arena.pcwstr(_valueName),
      );
      return result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND;
    });
  }
}
