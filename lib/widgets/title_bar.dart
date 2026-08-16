import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.title,
    required this.focused,
    required this.onDragStart,
    required this.onClose,
    required this.onOpenConfig,
    required this.onOpenWindowSettings,
    this.showWatchButton = false,
    this.watchEnabled = false,
    this.onToggleWatch,
    this.color = const Color(0xFFFFE082),
  });

  final String title;
  final bool focused;
  final VoidCallback onDragStart;
  final VoidCallback onClose;
  final VoidCallback onOpenConfig;
  final VoidCallback onOpenWindowSettings;
  final bool showWatchButton;
  final bool watchEnabled;
  final VoidCallback? onToggleWatch;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: focused ? 40 : 10,
      clipBehavior: Clip.hardEdge,
      color: color,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => onDragStart(),
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  opacity: focused ? 1 : 0,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !focused,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              opacity: focused ? 1 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showWatchButton)
                    IconButton(
                      onPressed: onToggleWatch,
                      tooltip: watchEnabled
                          ? 'watch_on'.tr()
                          : 'watch_off'.tr(),
                      icon: Icon(
                        watchEnabled
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 18,
                      ),
                    ),
                  IconButton(
                    onPressed: onOpenConfig,
                    tooltip: 'config'.tr(),
                    icon: const Icon(Icons.settings, size: 18),
                  ),
                  IconButton(
                    onPressed: onOpenWindowSettings,
                    tooltip: 'window_settings'.tr(),
                    icon: const Icon(Icons.more_horiz, size: 20),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'close'.tr(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
