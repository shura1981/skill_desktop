import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and menu.
///
/// When the window is minimized, the app is hidden and can be restored from
/// the tray menu.
class TrayController with TrayListener, WindowListener {
  static const _showKey = 'show';
  static const _backgroundKey = 'background';

  static late final TrayController _instance;

  TrayController._();

  static Future<void> initialize() async {
    _instance = TrayController._();

    // Ensure the tray manager is ready.
    await trayManager.setIcon(await _ensureTrayIconPath());
    await trayManager.setContextMenu(_buildContextMenu());
    trayManager.addListener(_instance);
    windowManager.addListener(_instance);
  }

  static Future<String> _ensureTrayIconPath() async {
    final asset = _trayAssetByPlatform();
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final extension = p.extension(asset);
    final file = File(p.join(tempDir.path, 'tray_icon$extension'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _trayAssetByPlatform() {
    if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    }
    if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.icns';
    }
    return 'assets/icons/tray_icon.png';
  }

  static Menu _buildContextMenu() {
    return Menu(items: [
      MenuItem(label: 'Mostrar', key: _showKey),
      MenuItem(label: 'Segundo plano', key: _backgroundKey),
    ]);
  }

  @override
  void onTrayIconMouseDown() {}

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseDown() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == _showKey) {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == _backgroundKey) {
      windowManager.hide();
    }
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'minimize') {
      windowManager.hide();
    }
  }
}
