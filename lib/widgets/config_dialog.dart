import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../autostart.dart';

Future<void> showConfigDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ConfigDialog(),
  );
}

class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late bool _autostart;

  @override
  void initState() {
    super.initState();
    _autostart = Autostart.isEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 420,
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'config'.tr(),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'language'.tr(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          dropdownColor: const Color(0xFF4A4A4A),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          value: context.locale.languageCode,
                          items: kSupportedLanguageCodes
                              .map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(_languageName(code)),
                                ),
                              )
                              .toList(),
                          onChanged: (code) async {
                            if (code == null) {
                              return;
                            }
                            await context.setLocale(Locale(code));
                            await AppSettings.open()
                                .then((s) => s.saveLanguageCode(code));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'autostart'.tr(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: _autostart,
                          onChanged: (v) {
                            setState(() => _autostart = v);
                            Autostart.setEnabled(v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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

  String _languageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
      default:
        return 'English';
    }
  }
}
