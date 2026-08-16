import 'package:flutter/material.dart';

import 'manager_app.dart';
import 'viewer_app.dart';
import 'window_constants.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final isViewer = args.any(
    (a) => a == viewerArgument || a.startsWith('$viewerArgument:'),
  );
  if (isViewer) {
    runApp(const ViewerApp());
  } else {
    runApp(const ManagerApp());
  }
}
