import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'services/settings_service.dart';
import 'services/user_repository.dart';
import 'tray/tray_controller.dart';
import 'ui/home_page.dart';

/// Entry widget for the desktop app.
///
/// It provides global services (settings, database) via [Provider], and
/// applies Material 3 theming using the persisted accent color + theme mode.
class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  /// Initializes desktop-specific services (window manager, tray, settings,
  /// and local database).
  static Future<void> initialize() async {
    await WindowManager.instance.ensureInitialized();

    await SettingsService.initialize();
    await UserRepository.initialize();

    await WindowManager.instance.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1000, 700),
        center: true,
        titleBarStyle: TitleBarStyle.hidden,
        title: 'Flutter Desktop App',
      ),
      () async {
        await WindowManager.instance.show();
        await WindowManager.instance.focus();
      },
    );

    await TrayController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsService.instance),
        Provider.value(value: UserRepository.instance),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, child) {
          final theme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: settings.seedColor),
          );

          final darkTheme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: settings.seedColor,
              brightness: Brightness.dark,
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Desktop',
            theme: theme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
