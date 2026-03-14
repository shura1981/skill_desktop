import 'package:flutter/material.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopApp.initialize();
  runApp(const DesktopApp());
}
