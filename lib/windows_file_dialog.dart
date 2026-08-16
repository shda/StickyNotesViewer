import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Opens the native Windows file-open dialog for Markdown files and returns
/// the absolute path of the selected file, or `null` if the user cancels.
///
/// Uses the modern `IFileOpenDialog` COM API rather than the legacy
/// `GetOpenFileNameW`.
///
/// IMPORTANT: the dialog is shown synchronously on the main UI thread. It must
/// run on the same thread that owns the parent window — if it is shown from a
/// background isolate, Windows does not properly modal/foreground it, so the
/// dialog opens behind other windows and keeps losing focus.
Future<String?> pickMarkdownFile({
  int? parentWindowHandle,
  String? dialogTitle,
}) {
  return Future.value(_pickFileSync(parentWindowHandle, dialogTitle));
}

String? _pickFileSync(int? parentWindowHandle, String? dialogTitle) {
  // The Flutter main thread is already COM-initialized as STA by the runner
  // (see windows/runner/main.cpp). CoInitializeEx here returns S_FALSE
  // ("already initialized"), which is not an error. Only call CoUninitialize
  // if we actually initialized COM ourselves (which won't happen on the main
  // thread, but is kept for correctness if this ever runs elsewhere).
  final hr = CoInitializeEx(
    COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE,
  );
  final initializedHere = hr == S_OK;

  try {
    return using((arena) {
      final dialog = arena.com<IFileOpenDialog>(FileOpenDialog);

      final options = dialog.getOptions() |
          FOS_FORCEFILESYSTEM |
          FOS_NOCHANGEDIR |
          FOS_FILEMUSTEXIST |
          FOS_DONTADDTORECENT;
      dialog.setOptions(FILEOPENDIALOGOPTIONS(options));

      dialog.setTitle(arena.pcwstr(dialogTitle ?? 'Open File'));

      final filters = arena<COMDLG_FILTERSPEC>(2);
      filters[0]
        ..pszName = arena.pwstr('Markdown (*.md, *.markdown)')
        ..pszSpec = arena.pwstr('*.md;*.markdown');
      filters[1]
        ..pszName = arena.pwstr('All files (*.*)')
        ..pszSpec = arena.pwstr('*.*');
      dialog.setFileTypes(2, filters);

      final parentHwnd = parentWindowHandle != null
          ? Pointer.fromAddress(parentWindowHandle) as HWND
          : null;

      try {
        dialog.show(parentHwnd);
      } on WindowsException catch (e) {
        if (e.hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
          return null;
        }
        rethrow;
      }

      final selectedItem = dialog.getResult();
      if (selectedItem == null) {
        return null;
      }

      final item = arena.adopt(selectedItem);
      final pathPtr = item.getDisplayName(SIGDN_FILESYSPATH);
      try {
        return pathPtr.toDartString();
      } finally {
        CoTaskMemFree(pathPtr);
      }
    });
  } finally {
    if (initializedHere) {
      CoUninitialize();
    }
  }
}
