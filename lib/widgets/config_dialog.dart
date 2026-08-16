import 'package:flutter/material.dart';

Future<void> showConfigDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ConfigDialog(),
  );
}

class ConfigDialog extends StatelessWidget {
  const ConfigDialog({super.key});

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
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Конфигурация',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 1),
            const Expanded(child: SizedBox()),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Сохранить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
