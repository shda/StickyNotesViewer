#ifndef DESKTOP_MULTI_WINDOW_WINDOWS_FLUTTER_WINDOW_WRAPPER_H_
#define DESKTOP_MULTI_WINDOW_WINDOWS_FLUTTER_WINDOW_WRAPPER_H_

#include <Windows.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/method_result.h>
#include <memory>
#include <string>

class FlutterWindowWrapper {
 public:
  FlutterWindowWrapper(const std::string& window_id,
                       HWND hwnd,
                       const std::string& window_argument = "")
      : window_id_(window_id), hwnd_(hwnd), window_argument_(window_argument) {}

  ~FlutterWindowWrapper() = default;

  std::string GetWindowId() const { return window_id_; }

  std::string GetWindowArgument() const { return window_argument_; }

  HWND GetWindowHandle() { return hwnd_; }

  void SetChannel(
      std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>>
          channel) {
    channel_ = channel;
  }

  void NotifyWindowEvent(const std::string& event,
                         const flutter::EncodableMap& data) {
    if (channel_) {
      channel_->InvokeMethod(event,
                             std::make_unique<flutter::EncodableValue>(data));
    }
  }

  void HandleWindowMethod(
      const std::string& method,
      const flutter::EncodableMap* arguments,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method == "window_show") {
      if (hwnd_) {
        ::ShowWindow(hwnd_, SW_SHOW);
      }
      result->Success();
    } else if (method == "window_hide") {
      if (hwnd_) {
        ::ShowWindow(hwnd_, SW_HIDE);
      }
      result->Success();
    } else if (method == "window_minimize") {
      if (hwnd_) {
        ::ShowWindow(hwnd_, SW_MINIMIZE);
      }
      result->Success();
    } else if (method == "window_maximize") {
      if (hwnd_) {
        ::ShowWindow(hwnd_, SW_MAXIMIZE);
      }
      result->Success();
    } else if (method == "window_close") {
      if (hwnd_) {
        ::PostMessage(hwnd_, WM_CLOSE, 0, 0);
      }
      result->Success();
    } else if (method == "window_start_drag") {
      ::ReleaseCapture();
      ::SendMessage(hwnd_, WM_NCLBUTTONDOWN, HTCAPTION, 0);
      result->Success();
    } else if (method == "window_get_bounds") {
      if (hwnd_) {
        WINDOWPLACEMENT placement{};
        placement.length = sizeof(placement);
        ::GetWindowPlacement(hwnd_, &placement);
        const RECT& rc = placement.rcNormalPosition;
        flutter::EncodableMap bounds;
        bounds[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(rc.left));
        bounds[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(rc.top));
        bounds[flutter::EncodableValue("width")] =
            flutter::EncodableValue(static_cast<double>(rc.right - rc.left));
        bounds[flutter::EncodableValue("height")] =
            flutter::EncodableValue(static_cast<double>(rc.bottom - rc.top));
        result->Success(flutter::EncodableValue(bounds));
      } else {
        result->Success();
      }
    } else if (method == "window_set_bounds") {
      if (hwnd_ && arguments) {
        const auto x = std::get<double>(
            arguments->at(flutter::EncodableValue("x")));
        const auto y = std::get<double>(
            arguments->at(flutter::EncodableValue("y")));
        const auto width = std::get<double>(
            arguments->at(flutter::EncodableValue("width")));
        const auto height = std::get<double>(
            arguments->at(flutter::EncodableValue("height")));
        ::SetWindowPos(hwnd_, nullptr, static_cast<int>(x),
                       static_cast<int>(y), static_cast<int>(width),
                       static_cast<int>(height),
                       SWP_NOZORDER | SWP_NOACTIVATE);
      }
      result->Success();
    } else if (method == "window_set_title") {
      if (hwnd_ && arguments) {
        const auto& title = std::get<std::string>(
            arguments->at(flutter::EncodableValue("title")));
        const int length =
            ::MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, nullptr, 0);
        if (length > 0) {
          std::wstring wide_title(length, 0);
          ::MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1,
                                &wide_title[0], length);
          ::SetWindowTextW(hwnd_, wide_title.c_str());
        }
      }
      result->Success();
    } else {
      result->Error("-1", "unknown method: " + method);
    }
  }

 protected:
  void SetWindowHandle(HWND hwnd) { hwnd_ = hwnd; }

 private:
  std::string window_id_;
  HWND hwnd_;
  std::string window_argument_;
  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // DESKTOP_MULTI_WINDOW_WINDOWS_FLUTTER_WINDOW_WRAPPER_H_
