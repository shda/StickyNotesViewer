import 'package:flutter/material.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.title,
    required this.focused,
    required this.onDragStart,
    required this.onClose,
  });

  final String title;
  final bool focused;
  final VoidCallback onDragStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: focused ? 40 : 10,
      clipBehavior: Clip.hardEdge,
      color: Colors.amber.shade200,
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
              child: IconButton(
                onPressed: onClose,
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
