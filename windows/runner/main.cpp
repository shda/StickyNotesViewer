#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr UINT kRestoreForegroundTimerId = 1;
constexpr UINT kRestoreForegroundDelayMs = 2500;

HWND g_previous_foreground = nullptr;

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // The notes must stay in the background: remember the foreground window
  // from before any window of this process was created and restore it
  // once the startup is done.
  g_previous_foreground = ::GetForegroundWindow();

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"sticky_notes_viewer", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::SetTimer(nullptr, kRestoreForegroundTimerId, kRestoreForegroundDelayMs,
             nullptr);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    if (msg.message == WM_TIMER && msg.wParam == kRestoreForegroundTimerId) {
      ::KillTimer(nullptr, kRestoreForegroundTimerId);
      if (g_previous_foreground != nullptr &&
          ::IsWindow(g_previous_foreground)) {
        ::SetForegroundWindow(g_previous_foreground);
      }
      continue;
    }
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
