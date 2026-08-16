#include "flutter_window.h"

#include "flutter_windows.h"

#include "tchar.h"

#include <windowsx.h>

#include <iostream>

#include "multi_window_manager.h"
#include "multi_window_plugin_internal.h"

namespace {

constexpr int kResizeBorderWidth = 8;
constexpr const wchar_t* kChildResizeStateProp = L"DMWChildResizeState";

struct ChildResizeState {
  WNDPROC original_proc = nullptr;
};

ChildResizeState* GetChildResizeState(HWND hwnd) {
  return reinterpret_cast<ChildResizeState*>(
      ::GetProp(hwnd, kChildResizeStateProp));
}

bool IsResizeHit(int ht) {
  return ht >= HTLEFT && ht <= HTBOTTOMRIGHT;
}

int GetResizeMargin(HWND top) {
  HMONITOR monitor = ::MonitorFromWindow(top, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  return static_cast<int>(kResizeBorderWidth * dpi / 96.0);
}

// Subclasses the Flutter view (the child window that covers the whole client
// area of the frameless window) to provide edge hit-testing.
//
// The actual resize is delegated to the system: on a non-client button-down in
// the resize margin we forward the message to the top-level window, whose
// default procedure performs a native modal resize. Windows then handles mouse
// capture, tracking, and button release itself, so there is no manual state
// that can get stuck (the previous manual implementation lost mouse capture
// during fast drags and never received WM_LBUTTONUP, leaving the window stuck
// in "resizing" mode with a resize cursor).
LRESULT CALLBACK ChildWndProc(HWND hwnd,
                              UINT message,
                              WPARAM wparam,
                              LPARAM lparam) {
  ChildResizeState* state = GetChildResizeState(hwnd);
  WNDPROC original = state ? state->original_proc : nullptr;
  HWND top = ::GetAncestor(hwnd, GA_ROOT);

  switch (message) {
    case WM_NCHITTEST: {
      LRESULT result = original ? ::CallWindowProc(original, hwnd, message,
                                                   wparam, lparam)
                                : ::DefWindowProc(hwnd, message, wparam,
                                                  lparam);
      if (result != HTCLIENT || !top || ::IsZoomed(top)) {
        return result;
      }
      POINT pt = {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      ::ScreenToClient(top, &pt);
      RECT rc;
      ::GetClientRect(top, &rc);
      const int margin = GetResizeMargin(top);
      const bool left = pt.x < margin;
      const bool right = pt.x >= rc.right - margin;
      const bool top_edge = pt.y < margin;
      const bool bottom = pt.y >= rc.bottom - margin;
      if (top_edge && left) {
        return HTTOPLEFT;
      }
      if (top_edge && right) {
        return HTTOPRIGHT;
      }
      if (bottom && left) {
        return HTBOTTOMLEFT;
      }
      if (bottom && right) {
        return HTBOTTOMRIGHT;
      }
      if (top_edge) {
        return HTTOP;
      }
      if (bottom) {
        return HTBOTTOM;
      }
      if (left) {
        return HTLEFT;
      }
      if (right) {
        return HTRIGHT;
      }
      return HTCLIENT;
    }

    case WM_NCLBUTTONDOWN:
      if (top && IsResizeHit(static_cast<int>(wparam))) {
        // Let Windows perform the resize natively on the top-level window.
        ::ReleaseCapture();
        ::SendMessage(top, WM_NCLBUTTONDOWN, wparam, lparam);
        return 0;
      }
      break;

    case WM_NCDESTROY: {
      LRESULT result = original ? ::CallWindowProc(original, hwnd, message,
                                                   wparam, lparam)
                                : ::DefWindowProc(hwnd, message, wparam,
                                                  lparam);
      ::RemoveProp(hwnd, kChildResizeStateProp);
      delete state;
      return result;
    }
  }

  return original ? ::CallWindowProc(original, hwnd, message, wparam, lparam)
                  : ::DefWindowProc(hwnd, message, wparam, lparam);
}

}  // namespace

FlutterWindow::FlutterWindow(const std::string& id,
                             const WindowConfiguration config)
    : id_(id), window_argument_(config.arguments) {}

bool FlutterWindow::OnCreate() {
  // Called when the window is created
  RECT frame = GetClientArea();

  flutter::DartProject project(L"data");
  std::vector<std::string> entrypoint_args = {"multi_window", id_,
                                              window_argument_};
  project.set_dart_entrypoint_arguments(entrypoint_args);
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project);

  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    std::cerr << "Failed to setup FlutterViewController." << std::endl;
    return false;
  }

  auto view_handle = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(view_handle);

  // Subclass the Flutter view to provide resize hit-testing for the frameless
  // window (the top-level window's own WM_NCHITTEST is never consulted for
  // points inside the client area).
  auto* state = new ChildResizeState();
  ::SetProp(view_handle, kChildResizeStateProp, state);
  state->original_proc = reinterpret_cast<WNDPROC>(::SetWindowLongPtr(
      view_handle, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(ChildWndProc)));

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  MultiWindowManager::Instance()->RemoveManagedFlutterWindowLater(id_);
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

FlutterWindow::~FlutterWindow() {
  // Cleanup is handled by Win32Window::Destroy()
}
