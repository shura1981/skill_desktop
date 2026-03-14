import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'windows/main_window.dart';
import 'windows/form_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MultiWindowApp()));
}

/// Root widget that manages rendering across all open OS windows.
///
/// Uses the Flutter 3.4x native multi-window API (PlatformDispatcher +
/// ViewCollection) so that all windows share a single Dart Isolate and the
/// same Riverpod ProviderScope — no serialization or IPC required.
class MultiWindowApp extends StatefulWidget {
  const MultiWindowApp({super.key});

  @override
  State<MultiWindowApp> createState() => _MultiWindowAppState();
}

class _MultiWindowAppState extends State<MultiWindowApp> {
  /// All currently open FlutterViews, keyed by viewId for fast lookup.
  final Map<int, ui.FlutterView> _views = {};

  @override
  void initState() {
    super.initState();
    // Register all views that are already open (the main window is view 0).
    for (final view in WidgetsBinding.instance.platformDispatcher.views) {
      _views[view.viewId] = view;
    }

    WidgetsBinding.instance.platformDispatcher.onViewCreated =
        (ui.FlutterView view) {
          setState(() => _views[view.viewId] = view);
        };

    WidgetsBinding.instance.platformDispatcher.onViewDisposed =
        (int viewId) {
          setState(() => _views.remove(viewId));
        };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onViewCreated = null;
    WidgetsBinding.instance.platformDispatcher.onViewDisposed = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(
      views: _views.values.map((view) {
        return View(
          view: view,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Desktop App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            home: view.viewId == 0
                ? const MainWindowPage()
                : const FormWindowPage(),
          ),
        );
      }).toList(),
    );
  }
}
