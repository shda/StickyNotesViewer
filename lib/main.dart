import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'manager_app.dart';
import 'viewer_app.dart';
import 'window_constants.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final settings = await AppSettings.open();
  final languageCode = await settings.loadLanguageCode();
  final mdDark = (await settings.loadMarkdownTheme()) == 'dark';

  final isViewer = args.any(
    (a) => a == viewerArgument || a.startsWith('$viewerArgument:'),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(languageCode),
      child: isViewer
          ? ViewerApp(initialMdDark: mdDark)
          : const ManagerApp(),
    ),
  );
}
