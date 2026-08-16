import 'package:flutter/material.dart';

import 'manager_app.dart';
import 'viewer_app.dart';
import 'window_constants.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.contains(viewerArgument)) {
    runApp(const ViewerApp());
  } else {
    runApp(const ManagerApp());
  }
}
