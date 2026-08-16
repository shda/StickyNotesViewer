#include "flutter_window.h"

#include <cstdio>
#include <cstring>

#include "flutter_windows.h"

#include "tchar.h"

#include <windowsx.h>

#include <iostream>

#include "multi_window_manager.h"
#include "multi_window_plugin_internal.h"

namespace {

constexpr int kResizeBorderWidth = 8;
constexpr int kMinResizeWidth = 200;
constexpr int kMinResizeHeight = 150;

constexpr const wchar_t* kChildResizeStateProp = L"DMWChildResizeState";

struct ChildResizeState {
  WNDPROC original_proc = nullptr;
  bool active = false;
  int mode = 0;
  POINT start_cursor{};
  RECT start_rect{};
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

// Subclasses the Flutter view (the child window that covers the whole
// client area of the frameless window) to provide edge hit-testing and
// manual resizing, because for points inside the client area the system
// never consults the top-level window's WM_NCHITTEST.
LRESULT CALLBACK ChildWndProc(HWND hwnd,
                              UINT message,
                              WPARAM wparam,
                              LPARAM lparam) {
  ChildResizeState* state = GetChildResizeState(hwnd);
  WNDPROC original = state ? state->original_proc : nullptr;
  HWND top = ::GetAncestor(hwnd, GA_ROOT);

  if (message == WM_LBUTTONDOWN || message == WM_LBUTTONUP ||
      message == WM_NCLBUTTONDOWN || message == WM_NCLBUTTONUP ||
      message == WM_MOUSEMOVE) {
    static int count = 0;
    if (count < 300) {
      count++;
      char buf[128];
      sprintf_s(buf, sizeof(buf), "CHILD msg=0x%X x=%d y=%d\n", (unsigned)message,
                (int)(short)LOWORD(lparam), (int)(short)HIWORD(lparam));
      FILE* dbg = nullptr;
      fopen_s(&dbg, "C:\\Users\\user\\AppData\\Local\\Temp\\kilo\\mouse_log.txt", "a");
      if (dbg) {
        fwrite(buf, 1, strlen(buf), dbg);
        fclose(dbg);
      }
    }
  }

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
      if (state && top && IsResizeHit(static_cast<int>(wparam))) {
        state->active = true;
        state->mode = static_cast<int>(wparam);
        ::GetCursorPos(&state->start_cursor);
        ::GetWindowRect(top, &state->start_rect);
        ::SetCapture(hwnd);
        return 0;
      }
      break;

    case WM_MOUSEMOVE:
    case WM_NCMOUSEMOVE: {
      if (state && state->active) {
        POINT cur;
        ::GetCursorPos(&cur);
        const int dx = cur.x - state->start_cursor.x;
        const int dy = cur.y - state->start_cursor.y;
        RECT nr = state->start_rect;
        const int mode = state->mode;
        if (mode == HTLEFT || mode == HTTOPLEFT || mode == HTBOTTOMLEFT) {
          nr.left += dx;
          if (nr.right - nr.left < kMinResizeWidth) {
            nr.left = nr.right - kMinResizeWidth;
          }
        }
        if (mode == HTRIGHT || mode == HTTOPRIGHT || mode == HTBOTTOMRIGHT) {
          nr.right += dx;
          if (nr.right - nr.left < kMinResizeWidth) {
            nr.right = nr.left + kMinResizeWidth;
          }
        }
        if (mode == HTTOP || mode == HTTOPLEFT || mode == HTTOPRIGHT) {
          nr.top += dy;
          if (nr.bottom - nr.top < kMinResizeHeight) {
            nr.top = nr.bottom - kMinResizeHeight;
          }
        }
        if (mode == HTBOTTOM || mode == HTBOTTOMLEFT ||
            mode == HTBOTTOMRIGHT) {
          nr.bottom += dy;
          if (nr.bottom - nr.top < kMinResizeHeight) {
            nr.bottom = nr.top + kMinResizeHeight;
          }
        }
        ::SetWindowPos(top, nullptr, nr.left, nr.top, nr.right - nr.left,
                       nr.bottom - nr.top, SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
      }
      break;
    }

    case WM_LBUTTONUP:
    case WM_NCLBUTTONUP:
      if (state && state->active) {
        state->active = false;
        ::ReleaseCapture();
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

  // Subclass the Flutter view to provide resize hit-testing and manual
  // resizing for the frameless window.
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
