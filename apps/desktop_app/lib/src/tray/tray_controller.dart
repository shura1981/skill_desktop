import 'dart:convert';
import 'dart:io';

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
    final bytes = base64Decode(_trayIconBase64);
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'tray_icon.png'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
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

// A tiny 16x16 PNG icon (a simple circle) encoded in base64.
// You can replace this with your own icon if desired.
const _trayIconBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAAAJklEQVR4AWP8z8Dwn4GBgYF' 
    'jI2NgYGBg4GIDw4GLA8GCA/8JgYAM+QGJj7ZJ1wAAAABJRU5ErkJggg==';
