import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Default title-bar color (amber.shade200).
const kDefaultTitleColor = Color(0xFFFFE082);

/// The palette of title-bar colors offered in the per-window settings dialog.
const kTitleColors = <Color>[
  Color(0xFFFFE082), // amber (default)
  Color(0xFFEF9A9A), // red
  Color(0xFFFFB74D), // orange
  Color(0xFFFFF59D), // yellow
  Color(0xFFA5D6A7), // green
  Color(0xFF80CBC4), // teal
  Color(0xFF90CAF9), // blue
  Color(0xFFCE93D8), // purple
];

/// Opens the per-window settings dialog (font scale, line spacing, title
/// color).
///
/// Changes are applied live via [onChanged] as the user drags a slider or taps
/// a color.
Future<void> showWindowSettingsDialog(
  BuildContext context, {
  required double initialFontScale,
  required double initialLineHeight,
  required Color initialTitleColor,
  required void Function(double fontScale, double lineHeight, Color titleColor)
      onChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _WindowSettingsDialog(
      initialFontScale: initialFontScale,
      initialLineHeight: initialLineHeight,
      initialTitleColor: initialTitleColor,
      onChanged: onChanged,
    ),
  );
}

class _WindowSettingsDialog extends StatefulWidget {
  const _WindowSettingsDialog({
    required this.initialFontScale,
    required this.initialLineHeight,
    required this.initialTitleColor,
    required this.onChanged,
  });

  final double initialFontScale;
  final double initialLineHeight;
  final Color initialTitleColor;
  final void Function(double fontScale, double lineHeight, Color titleColor)
      onChanged;

  @override
  State<_WindowSettingsDialog> createState() => _WindowSettingsDialogState();
}

class _WindowSettingsDialogState extends State<_WindowSettingsDialog> {
  late double _fontScale;
  late double _lineHeight;
  late Color _titleColor;

  @override
  void initState() {
    super.initState();
    _fontScale = widget.initialFontScale.clamp(0.2, 2.0);
    _lineHeight = widget.initialLineHeight.clamp(0.1, 2.0);
    _titleColor = widget.initialTitleColor;
  }

  void _emit() => widget.onChanged(_fontScale, _lineHeight, _titleColor);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'window_settings'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'close'.tr(),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'font_size'.tr(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          _fontScale.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontScale,
                    min: 0.2,
                    max: 2.0,
                    onChanged: (v) {
                      setState(() => _fontScale = v);
                      _emit();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'line_spacing'.tr(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          _lineHeight.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _lineHeight,
                    min: 0.1,
                    max: 2.0,
                    onChanged: (v) {
                      setState(() => _lineHeight = v);
                      _emit();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'title_color'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in kTitleColors)
                        _ColorDot(
                          color: color,
                          selected: color.toARGB32() == _titleColor.toARGB32(),
                          onTap: () {
                            setState(() => _titleColor = color);
                            _emit();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('save'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.white24, width: 1),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.black87)
            : null,
      ),
    );
  }
}
