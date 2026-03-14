# 🖥️ Desktop Platform — Widget & API Updates (Flutter 3.27 → 3.41)

This document catalogs **every** new widget, updated widget, new property, and API change relevant to **Windows**, **macOS**, and **Linux** desktop targets introduced from Flutter 3.27 through 3.41.

---

## Multi-Window Support (3.32 / 3.35 / 3.41)

> **⚠️ ESTADO en Stable 3.41 — LEER ANTES DE CONTINUAR**
>
> Las APIs nativas de multi-window (`RegularWindowController`, `DialogWindowController`, `TooltipWindowController`, `PopupWindowController`) **existen en el SDK pero son `@internal`** y están protegidas por un feature flag:
> ```dart
> bool isWindowingEnabled = debugEnabledFeatureFlags.contains('windowing');
> ```
> **No están disponibles en el canal `stable`.** Solo accesibles en canal `main` con flag experimental.
>
> **Para proyectos en stable 3.41: usa `desktop_multi_window: ^0.3.0`** (plugin de producción, arquitectura multi-engine).

### Regular Windows — Linux (3.41) [Experimental/Internal]
- **Estado:** Implementación lista internamente para Linux, marcada `@internal`. Requiere canal `main` + feature flag.
- Canonical contribuyó fixes de accessibility, app lifecycle, focus traversal e input events en contextos multi-window.

### Dialog Windows — Windows Win32 (3.41) [Experimental/Internal]
- **Estado:** Native dialog windows implementadas internamente para Win32, aún `@internal`.

### Popup / Dialog / Tooltip Windows (3.41) [Experimental/Internal]
- Las APIs de popups, diálogos y tooltips multi-window **existen en el SDK** pero siguen siendo `@internal`.
- **Para stable 3.41:** El plugin `desktop_multi_window: ^0.3.0` provee soporte completo de producción.

### Desktop Multi-Window Progress (3.32)
- Progreso significativo en soporte multi-window. Canonical resolvió:
  - Accessibility en contextos multi-window
  - App lifecycle management entre ventanas
  - Focus traversal entre ventanas
  - Input event handling en múltiples surfaces

---

## Multi-Window Architecture — Plugin Stable: `desktop_multi_window` (3.41)

### Arquitectura: Multi-Engine (Una engine Flutter por ventana)
- `desktop_multi_window: ^0.3.0` crea una **engine Flutter independiente por cada ventana**.
- Cada ventana es un proceso nativo separado de Flutter con su propio aislado Dart.
- La comunicación entre ventanas se realiza via `WindowMethodChannel` (JSON sobre Method Channels nativos).
- **Consecuencia:** El estado NO se comparte directamente. Usa `WindowMethodChannel` para sincronizar por eventos.

> **⚠️ DIFERENCIA CON EL API EXPERIMENTAL:**  
> El API `@internal` del SDK apunta a una arquitectura single-isolate (un engine compartido).  
> Esa arquitectura **no está disponible en stable**. En stable, cada ventana = engine separada.

### Setup: `pubspec.yaml`
```yaml
dependencies:
  desktop_multi_window: ^0.3.0
```

### `main.dart` — Bootstrap Multi-Ventana
```dart
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detectar si somos ventana principal o sub-ventana
  if (args.firstOrNull == 'multi_window') {
    final windowController = await WindowController.fromCurrentEngine();
    final argsJson = windowController.arguments;
    final config = argsJson != null ? jsonDecode(argsJson) as Map<String, dynamic> : <String, dynamic>{};
    
    runApp(SubWindowApp(config: config, controller: windowController));
    return;
  }

  runApp(const MainApp());
}
```

### `WindowController.create()` — Abrir Nueva Ventana
```dart
import 'package:desktop_multi_window/desktop_multi_window.dart';

Future<void> openFormWindow() async {
  final controller = await WindowController.create(
    WindowConfiguration(
      title: 'Nueva Persona',
      size: const Size(600, 450),
      hiddenAtLaunch: true, // Evita parpadeo al posicionar/configurar
      arguments: jsonEncode({'type': 'form', 'title': 'Nueva Persona'}),
    ),
  );
  await controller.setFrame(const Rect.fromLTWH(200, 200, 600, 450));
  await controller.show();
}
```

### `WindowMethodChannel` — Comunicación Entre Ventanas
```dart
// Canal compartido (mismo nombre en ambas ventanas)
const _syncChannel = WindowMethodChannel(
  'app/sync',
  mode: ChannelMode.unidirectional, // Sin respuesta de vuelta
);

// En la ventana principal — escuchar mensajes de sub-ventanas
void initSyncListener() {
  _syncChannel.setMethodCallHandler((call) async {
    if (call.method == 'recordSaved') {
      ref.invalidate(recordsProvider); // Refrescar datos
    }
  });
}

// En la sub-ventana — notificar a la ventana principal
Future<void> onSave() async {
  await _persistRecord();
  await _syncChannel.invokeMethod('recordSaved');
  await _closeWindow();
}
```

### `WindowController.fromCurrentEngine()` — Control de la Ventana Actual
```dart
// ✅ CORRECTO — cerrar sub-ventana
Future<void> _closeWindow() async {
  final controller = await WindowController.fromCurrentEngine();
  await controller.hide(); // O controller.close()
}

// ❌ INCORRECTO — mata todo el proceso en desktop
// SystemNavigator.pop();
```

### `WindowController.getAll()` — Listar Todas las Ventanas
```dart
Future<void> closeAllSecondaryWindows() async {
  final windows = await WindowController.getAll();
  for (final w in windows) {
    // windowId == 0 es la ventana principal
    if (w.windowId != 0) await w.close();
  }
}
```

### `WindowConfiguration` — Parámetros de Creación

| Propiedad | Tipo | Descripción |
|---|---|---|
| `title` | `String?` | Título en la barra del OS |
| `size` | `Size?` | Tamaño inicial de la ventana |
| `hiddenAtLaunch` | `bool` | `true` para posicionar antes de mostrar |
| `arguments` | `String?` | JSON para pasar a la nueva ventana |

### Registro de Plugins en Sub-Ventanas (Linux/macOS)
```cpp
// linux/runner/my_application.cc — Registrar plugins en Flutter Engine
#include "generated_plugin_registrant.h"

static void my_application_activate(GApplication* application) {
  // El plugin desktop_multi_window crea engines adicionales;
  // asegurarse de llamar RegisterPlugins en cada engine creado.
  RegisterPlugins(fl_engine);
}
```

### Pattern Completo: Ventana Principal + Sub-Ventana

```dart
// lib/windows/main_window.dart
class MainWindow extends ConsumerStatefulWidget { ... }
class _MainWindowState extends ConsumerState<MainWindow> {
  final _syncChannel = const WindowMethodChannel('app/sync', mode: ChannelMode.unidirectional);

  @override
  void initState() {
    super.initState();
    _syncChannel.setMethodCallHandler((call) async {
      if (call.method == 'recordSaved') ref.invalidate(recordsProvider);
    });
  }

  Future<void> _openFormWindow() async {
    final controller = await WindowController.create(
      WindowConfiguration(
        title: 'Nuevo Registro',
        hiddenAtLaunch: true,
        arguments: jsonEncode({'type': 'form'}),
      ),
    );
    await controller.setFrame(const Rect.fromLTWH(300, 200, 600, 450));
    await controller.show();
  }
}

// lib/windows/form_window.dart
class FormWindow extends ConsumerStatefulWidget { ... }
class _FormWindowState extends ConsumerState<FormWindow> {
  final _syncChannel = const WindowMethodChannel('app/sync', mode: ChannelMode.unidirectional);
  final bool isDesktopSubWindow;

  Future<void> _onSave() async {
    await ref.read(saveRecordProvider.notifier).save();
    if (isDesktopSubWindow) {
      await _syncChannel.invokeMethod('recordSaved');
      final controller = await WindowController.fromCurrentEngine();
      await controller.hide();
    } else {
      Navigator.of(context).pop(); // Fallback para modo navegación clásica
    }
  }
}
```

### Performance: Plugin Stable vs API Experimental (cuando esté disponible)

| Métrica | `desktop_multi_window` (Stable) | API Nativa (Experimental, no stable) |
|---|---|---|
| Tiempo de apertura | ~800 ms - 1.5 s | ~100 ms (proyectado) |
| CPU idle por ventana | 2–5% por engine | < 0.5% global (proyectado) |
| Comunicación cross-window | Async JSON (Method Channels) | Sincrónico (memoria compartida) |
| Disponibilidad en stable | ✅ `desktop_multi_window ^0.3.0` | ❌ Solo canal `main` + feature flag |
| Hot Reload | Manual por engine | Unificado (proyectado) |

---

## Client-Side Decorations / Frameless Windows (3.4x)

### What It Is
- Equivalent to `JFrame.setUndecorated(true)` in Java/Swing or `StageStyle.UNDECORATED` in JavaFX.
- Flutter draws the title bar and window control buttons (Close, Minimize, Maximize) as ordinary widgets — enabling full brand customization (Discord, Spotify, VS Code style).
- Configuration is set in the native runner (`windows/runner/main.cpp`, `macos/Runner/AppDelegate.swift`, Linux GTK runner) and then reflected in Flutter with `scaffoldBackgroundColor: Colors.transparent`.

### Custom Title Bar Pattern
```dart
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final viewId = View.of(context).viewId;

    return GestureDetector(
      onPanUpdate: (_) =>
          SystemChannels.window.invokeMethod('startDragging', {'id': viewId}),
      child: Container(
        height: 40,
        color: Colors.blueGrey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('My App', style: TextStyle(color: Colors.white)),
            ),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () => SystemChannels.window
                    .invokeMethod('minimize', {'id': viewId}),
              ),
              IconButton(
                icon: const Icon(Icons.crop_square, color: Colors.white),
                onPressed: () => SystemChannels.window
                    .invokeMethod('maximize', {'id': viewId}),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () async {
                  // ✅ CORRECTO: Para sub-ventanas (plugin desktop_multi_window)
                  // Para ventana principal, cerrar con window_manager o SystemNavigator
                  final controller = await WindowController.fromCurrentEngine();
                  await controller.hide();
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
```
- **Hit-testing:** Because all windows share the same engine, hit-testing correctly distinguishes clicks on the custom "Close" button from widgets underneath it.
- **Hover animations:** Unlike native OS buttons, Flutter buttons in a custom title bar support `MouseRegion`, `AnimatedContainer`, or `Hero` transitions.

---

## Transparent Windows & Native Overlays (3.4x)

- Secondary windows can be fully **frameless + transparent** for use as:
  - Desktop widget overlays
  - Native toast/notification popups floating above other applications
  - Screenshot / screen-crop tools
- Requires `scaffoldBackgroundColor: Colors.transparent` in `MaterialApp` and configuration in the native OS runner to set the window background to transparent.
- Works on Windows, macOS, and Linux without third-party plugins.

---

## Per-View Lifecycle — `AppLifecycleListener` (3.4x)

- Before 3.35, minimizing any window paused the entire engine. Now each view has an **independent lifecycle state**.
- Use `AppLifecycleListener` inside a view's widget tree to respond to that specific window's visibility and focus changes:

```dart
_listener = AppLifecycleListener(
  onHide: () => /* this window was minimized or hidden */,
  onShow: () => /* this window became visible again */,
  onPause: () => /* engine paused rendering this view */,
);
```
- Dispose the listener in `dispose()` to avoid leaks.

---

## Multi-Monitor Metrics — Per-View `devicePixelRatio` (3.4x)

- **Never assume a single global `devicePixelRatio`** in desktop apps. Each `FlutterView` reports its own DPR based on the display it currently occupies.
- When the user drags a window from a 1080p monitor to a 4K monitor, Flutter automatically recalculates the DPR for that view only and emits a redraw without affecting other windows.

```dart
final FlutterView view = View.of(context);
final Size logicalSize = view.physicalSize / view.devicePixelRatio;
print('Window ${view.viewId} logical size: $logicalSize');
```

---

## Cross-Window Pointer Events (3.4x)

- The unified engine tracks the cursor position relative to **all** open windows simultaneously.
- **`MouseTracker` (global):** The framework detects when the pointer leaves Window A and enters Window B, firing `onExit`/`onEnter` events correctly — essential for floating tool palettes (Photoshop-style).
- **`FocusManager` (global):** Only one window holds keyboard focus at a time. The `FocusManager` transfers focus natively between views without dropping key events.

---

## System Integration APIs (3.4x)

### `PlatformMenuBar` — Native OS Menu Bar
- Use for native menu bars (macOS menu bar at top of screen, Windows application menu).
- Do **not** use floating overlay menus or third-party packages for menu bars on desktop.
- Pairs with `Shortcuts` + `Actions` for keyboard shortcut handling scoped to the focused window.

### Window Icons Per Window
- **Historical context:** Before SDK 3.4x, the app icon was defined exclusively at compile time via `.ico` (Windows) or `.icns` (macOS) files. Changing a specific window's icon at runtime was impossible without native platform hacks.
- Each window (`viewId`) can now have its own distinct taskbar/dock icon set **at runtime**:
```dart
await SystemChannels.window.invokeMethod('setWindowIcon', {
  'id': viewId,
  'asset': 'assets/icons/warning.png',
});
```

### System Tray
- ⚠️ **Correction:** Flutter SDK 3.4x does **NOT** expose System Tray through any Dart API (`dart:ui`, `SystemChannels`, or `PlatformDispatcher`). The `tray_manager` plugin is **required** for all system tray functionality (see the full `tray_manager` section below).

---

## Core Desktop Widgets: `View`, `ViewAnchor`, `Display`

### `View` Widget
- Root widget representing a `FlutterView` in the widget tree.
- `View.of(context)` returns the nearest `FlutterView` in context — always use this instead of `WidgetsBinding.instance.window` (deprecated in 3.4x multi-window contexts).

### `ViewAnchor` Widget (3.4x)
- **New widget.** Anchors a secondary `FlutterView` to a specific position within the parent view's widget tree.
- The distinction vs. `PlatformDispatcher.requestView()`: a plain `requestView()` opens an **independent** window at an arbitrary OS position. `ViewAnchor` opens a view **anchored** to a widget's position within the layout — e.g., a full-window tooltip, a floating tool panel anchored to a toolbar button, or a per-widget popup panel.
- Usage pattern:
  ```dart
  ViewAnchor(
    view: MySecondaryWindowContent(),
    child: ElevatedButton(
      onPressed: openPanel,
      child: const Text('Open Panel'),
    ),
  );
  ```

### `Display` Class (`dart:ui`)
- Represents a physical monitor connected to the system.
- Exposes `size`, `devicePixelRatio`, and refresh rate of the physical display.
- Use it to **query monitor capabilities before creating a view**, e.g., to decide which monitor to open a secondary window on in a multi-monitor setup:
  ```dart
  final displays = PlatformDispatcher.instance.displays;
  for (final display in displays) {
    print('Display ${display.id}: ${display.size} @ ${display.devicePixelRatio}x');
  }
  ```

### UI/Platform Thread Merge (3.35)
- UI and platform threads have been **merged by default on Windows and Linux**, leading to dramatically smoother window resizing and reduced frame drops during interactive resize operations.

### Impeller — Desktop
- **3.27**: Impeller active as default renderer. Metal rendering surface refined for macOS.
- **3.29 → 3.41**: Continued optimization of Impeller on desktop. Fragment shaders support synchronous image decoding and 128-bit float textures across all desktop platforms.

---

## macOS-Specific Changes

### Swift Package Manager (SPM) (3.27 → 3.41)
- **3.27**: SPM migration begins for macOS/iOS plugins.
- **3.41**: **Full SPM support is stable.** CocoaPods is considered legacy for macOS apps.

### Minimum macOS Version (3.32)
- Raised to **macOS 10.15 Catalina**.

### CupertinoDesktopTextSelectionToolbar (3.41)
- Fix to prevent crash when toolbar is accessed in certain configurations on macOS.

### Wide Gamut Color (P3) — macOS (3.27)
- P3 color space support for more vibrant visuals on modern Apple displays.

---

## Windows-Specific Changes

### Dialog Window Implementation (3.41)
- Native Win32 dialog windows can now be created directly from Flutter without platform channels or workarounds.

### Regular Window Implementation (3.41)
- Regular (non-popup) windows supported for multi-window applications.

### Smooth Resizing (3.35)
- Thread merge removes jank during window resizing on Windows.

---

## Linux-Specific Changes

### Regular Windows Implementation (3.41)
- **New**: Regular windowed applications natively supported.
- Linux runner style updated for new examples.

### Smooth Resizing (3.35)
- Thread merge removes jank during window resizing on Linux.

---

## Desktop-Relevant Cross-Platform Widgets

### SelectionArea — Shift+Click (3.27)
- `SelectionArea` now supports **Shift + Click** gesture for extending text selections on Linux, macOS, and Windows.
- New `clearSelection` method to programmatically remove active selections.

### SelectableRegion (3.41)
- Tapping outside of `SelectableRegion` now correctly **dismisses the selection**.
- `SelectableRegion` should not show Flutter-rendered context menu when the web context menu is enabled.

### NavigationRail — Scrollable (3.35)
- `NavigationRail` is now **scrollable** with more configuration options — ideal for desktop layouts with many navigation items.

### NavigationDrawer — Headers/Footers (3.35)
- `NavigationDrawer` now supports **headers and footers** for richer desktop navigation patterns.

### RawMenuAnchor (3.32)
- **New widget.** An unstyled menu anchor for highly customized desktop-style menus.

### MenuAnchor Improvements (3.27)
- Removed unused early key event listener.
- Focus refactoring for `RawMenuAnchor` base.
- Hover traversal fixes for better desktop mouse interaction patterns.

### Expansible & ExpansibleController (3.32)
- **New widget.** A flexible base for expandable/collapsible panels — useful in desktop settings panels, file explorers, and complex list UIs.

### Tooltip — Manual Positioning (3.41)
- Position `Tooltip`s manually via newly exposed API — especially useful on wide desktop screens where default placement may clip.

### Navigator.popUntilWithResult (3.41)
- Pop multiple routes and return a value — useful for desktop multi-pane navigation flows.

### Widget Previews — `@Preview()` (3.38 / 3.41)
- **3.38**: Experimental widget previewer with VS Code and Android Studio integration.
- **3.41**: Enhanced with embedded Flutter Inspector. `MultiPreviews` support.

### Text Input Improvements (3.32)
- `onTapUpOutside` behavior customizable in `TextField`.
- Any widget usable as error message for `FormField` (not just `Text`).

---

## Desktop Accessibility

### Semantics Tree Performance (3.32)
- Semantics tree builds approximately **80% faster** on all platforms including desktop.

### SemanticsRole API (3.32 / 3.35)
- **3.32**: New API for specifying semantic roles at the widget subtree level.
- **3.35**: `SemanticsLabelBuilder` for dynamic semantic labels.

### Segmented Control Radio Role (3.41)
- Segmented control widgets now properly apply the `radioGroup` semantic role for assistive technologies on desktop.

---

## Desktop-Relevant Dart & Syntax Changes

### Dart 3.10 Dot Shorthands (3.38)
- Enum prefix dropping: `MainAxisAlignment.center` → `.center`. Especially impactful for reducing verbosity in large desktop-centric widget trees.

### Dart 3.8 Null-Aware Elements (3.32)
- Null-aware collection elements for cleaner list/map construction in complex desktop UIs.

### spacing Parameter (3.27)
- `Row`, `Column`, `Flex` all support `spacing` property — eliminates `SizedBox` spacers in dense desktop layouts.

---

## Breaking Changes & Deprecations (Desktop)

| Version | Change | Migration |
|---------|--------|-----------|
| 3.27 | `AssetManifest.json` generation discontinued | Use binary asset manifest |
| 3.27 | Objective-C iOS/macOS projects deprecated | Use Swift |
| 3.32 | Minimum macOS raised to 10.15 | Update deployment target |
| 3.32 | `ExpansionTileController` deprecated | Use `ExpansibleController` |
| 3.32 | `SystemContextMenuController.show` deprecated | Use newer menu APIs |
| 3.35 | Observatory support removed | Use Dart DevTools |
| 3.38 | `CupertinoDynamicColor.withOpacity` deprecated | Use `.withValues(alpha:)` |
| 3.38 | `OverlayPortal.targetsRootOverlay` deprecated | Use `OverlayPortalController` directly |
| 3.41 | Material & Cupertino decoupling begins | Libraries moving to standalone packages |

---

## Plugin `window_manager` — Referencia Completa y Guía de Migración

> **⚠️ Migration Notice (2026):** `window_manager` is being migrated to [`nativeapi-flutter`](https://github.com/libnativeapi/nativeapi-flutter), a new version based on a unified C++ core library (`libnativeapi/nativeapi`) for more complete and consistent cross-platform native API support.

### SDK Native vs `window_manager` — Decision Table

| Operation | Flutter SDK 3.4x Native | `window_manager` Plugin |
|---|---|---|
| Open secondary window | ✅ `PlatformDispatcher.requestView()` | ✅ Own API |
| Close window | ✅ `PlatformDispatcher.closeView(viewId)` | ✅ `windowManager.close()` / `destroy()` |
| Dynamic title | ✅ `SystemChannels.window` | ✅ `windowManager.setTitle()` |
| Minimize / Maximize | ✅ `SystemChannels.window` | ✅ Own API |
| Window drag | ✅ `SystemChannels.window` | ✅ `windowManager.startDragging()` |
| Per-window runtime icons | ✅ `SystemChannels.window` | ✅ `windowManager.setIcon()` (Windows) |
| Frameless windows | ✅ Native runner config | ✅ `setAsFrameless()` / `TitleBarStyle` |
| **Exact screen position** | ❌ Not exposed to Dart | ✅ `setPosition(Offset)` / `getPosition()` |
| **Minimum / Maximum size** | ❌ Not exposed to Dart | ✅ `setMinimumSize(Size)` / `setMaximumSize(Size)` |
| **Always on top** | ❌ Not exposed to Dart | ✅ `setAlwaysOnTop(bool)` |
| **Always on bottom** | ❌ Not exposed to Dart | ✅ `setAlwaysOnBottom(bool)` (Linux, Windows) |
| **Lock resize** | ❌ Not exposed to Dart | ✅ `setResizable(bool)` |
| **Lock move** | ❌ Not exposed to Dart | ✅ `setMovable(bool)` (macOS) |
| **Center on screen** | ❌ Not exposed to Dart | ✅ `center()` / `setAlignment(Alignment)` |
| **Query state (isMaximized, isFocused...)** | ❌ Not exposed to Dart | ✅ Fully available |
| **Window opacity** | ❌ Not exposed to Dart | ✅ `setOpacity(double)` |
| **Intercept close** (confirm dialog) | ❌ Not exposed to Dart | ✅ `setPreventClose(bool)` |
| **Skip taskbar/dock** | ❌ Not exposed to Dart | ✅ `setSkipTaskbar(bool)` |
| **Window shadow** | ❌ Not exposed to Dart | ✅ `setHasShadow(bool)` (macOS, Windows) |
| **Taskbar progress bar** | ❌ Not exposed to Dart | ✅ `setProgressBar(double)` (macOS, Windows) |
| **Dock badge** | ❌ Not exposed to Dart | ✅ `setBadgeLabel(String?)` (macOS) |
| **Aspect ratio** | ❌ Not exposed to Dart | ✅ `setAspectRatio(double)` |
| **Fullscreen** | ❌ Not exposed to Dart | ✅ `setFullScreen(bool)` |
| **Visible on all workspaces** | ❌ Not exposed to Dart | ✅ `setVisibleOnAllWorkspaces(bool)` (macOS) |
| **Side docking (Aero snap)** | ❌ Not exposed to Dart | ✅ `dock({side, width})` (Windows) |
| **Mouse event pass-through** | ❌ Not exposed to Dart | ✅ `setIgnoreMouseEvents(bool, {forward})` |
| **Edge resizing** | ❌ Not exposed to Dart | ✅ `startResizing(ResizeEdge)` (Linux, Windows) |
| **Hide at launch** (no flash) | Manual runner config | ✅ `waitUntilReadyToShow()` pattern |
| Window events (resize, move, focus...) | Basic `AppLifecycleListener` | ✅ Full `WindowListener` mixin |

### Installation & Initialization

```yaml
dependencies:
  window_manager: ^0.5.1
```

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized(); // Always first

  WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // For custom title bars
  );

  // Hide until Flutter is ready → prevents unstyled window flash
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
```

### Full API Reference

#### Position & Size
```dart
await windowManager.getPosition();               // → Offset
await windowManager.setPosition(Offset(100, 200), animate: true);
await windowManager.center();                    // Center on active screen
await windowManager.setAlignment(Alignment.center, animate: true);
await windowManager.getSize();                   // → Size
await windowManager.setSize(Size(1280, 720), animate: true);
await windowManager.setMinimumSize(Size(800, 600));
await windowManager.setMaximumSize(Size(1920, 1080));
await windowManager.setAspectRatio(16 / 9);
await windowManager.getBounds();                 // → Rect
await windowManager.setBounds(Rect.fromLTWH(0, 0, 1280, 720));
```

#### Window State
```dart
await windowManager.isVisible();                 // → bool
await windowManager.show();  await windowManager.hide();
await windowManager.isFocused();                 // → bool (macOS, Windows)
await windowManager.focus(); await windowManager.blur();
await windowManager.isMaximized(); await windowManager.maximize(); await windowManager.unmaximize();
await windowManager.isMinimized(); await windowManager.minimize(); await windowManager.restore();
await windowManager.isFullScreen(); await windowManager.setFullScreen(true);
```

#### User Interaction Restrictions
```dart
await windowManager.setResizable(false);         // Disable user resize
await windowManager.setMovable(false);           // macOS only
await windowManager.setMinimizable(false);       // macOS, Windows
await windowManager.setMaximizable(false);       // macOS, Windows
await windowManager.setClosable(false);          // macOS, Windows
```

#### Appearance
```dart
await windowManager.setTitle('My App');
await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
await windowManager.setAsFrameless();
await windowManager.setBackgroundColor(Colors.transparent);
await windowManager.setOpacity(0.95);
await windowManager.setBrightness(Brightness.dark);
await windowManager.setHasShadow(false);         // macOS, Windows
```

#### Z-Order & Taskbar
```dart
await windowManager.setAlwaysOnTop(true);
await windowManager.setAlwaysOnBottom(true);     // Linux, Windows
await windowManager.setSkipTaskbar(true);
await windowManager.setProgressBar(0.75);        // macOS, Windows
await windowManager.setBadgeLabel('99+');        // macOS dock badge
await windowManager.setIcon('assets/app.ico');  // Windows
await windowManager.setVisibleOnAllWorkspaces(true, visibleOnFullScreen: true); // macOS
```

#### Close Interception
```dart
await windowManager.setPreventClose(true);
await windowManager.close();                     // Respects setPreventClose
await windowManager.destroy();                   // Force close, no dialog
```

#### Advanced Actions
```dart
await windowManager.startDragging();             // From custom title bar widget
await windowManager.startResizing(ResizeEdge.bottomRight); // Linux, Windows
await windowManager.setIgnoreMouseEvents(true, forward: true); // Click-through overlay
await windowManager.popUpWindowMenu();           // Native window context menu
await windowManager.dock(side: DockSide.left, width: 400); // Windows Aero snap
await windowManager.getId();                     // HWND (Windows) / window number (macOS)
```

### `WindowListener` — Full Event Mixin

```dart
class _MyState extends State<MyWidget> with WindowListener {
  @override void initState() { super.initState(); windowManager.addListener(this); }
  @override void dispose() { windowManager.removeListener(this); super.dispose(); }

  @override void onWindowClose() {}
  @override void onWindowFocus() { setState(() {}); } // Always call setState here
  @override void onWindowBlur() {}
  @override void onWindowMaximize() {}
  @override void onWindowUnmaximize() {}
  @override void onWindowMinimize() {}
  @override void onWindowRestore() {}
  @override void onWindowResize() {}
  @override void onWindowResized() {}
  @override void onWindowMove() {}
  @override void onWindowMoved() {}
  @override void onWindowEnterFullScreen() {}
  @override void onWindowLeaveFullScreen() {}
  @override void onWindowDocked() {}   // Windows only
  @override void onWindowUndocked() {} // Windows only
  @override void onWindowEvent(String eventName) {} // All events
}
```

### Pattern: Confirm Before Close

```dart
void _init() async => await windowManager.setPreventClose(true);

@override
void onWindowClose() async {
  if (!await windowManager.isPreventClose()) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Close the app?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close')),
      ],
    ),
  );
  if (ok == true) await windowManager.destroy();
}
```

### `TitleBarStyle` Enum

| Value | Effect |
|---|---|
| `TitleBarStyle.normal` | Native OS title bar (default) |
| `TitleBarStyle.hidden` | Title bar hidden, window buttons still visible (macOS traffic lights) |

Set `windowButtonVisibility: false` inside `setTitleBarStyle` to also hide the macOS traffic light buttons when using `TitleBarStyle.hidden`.

---

## Plugin `tray_manager` — System Tray (Required — Not in SDK)

> **Critical correction:** Flutter SDK 3.4x does **NOT** expose System Tray via any Dart API. `tray_manager` is **mandatory** for all system tray functionality.

> **⚠️ Migration Notice (2026):** Also being migrated to [`nativeapi-flutter`](https://github.com/libnativeapi/nativeapi-flutter).

### Platform Support Matrix

| Method | Linux | macOS | Windows |
|---|---|---|---|
| `setIcon` | ✅ | ✅ | ✅ |
| `setContextMenu` | ✅ | ✅ | ✅ |
| `destroy` | ✅ | ✅ | ✅ |
| `setToolTip` | ➖ | ✅ | ✅ |
| `popUpContextMenu` | ➖ | ✅ | ✅ |
| `getBounds` | ➖ | ✅ | ✅ |
| `setIconPosition` | ➖ | ✅ | ➖ |

### Installation

```yaml
dependencies:
  tray_manager: ^0.5.2
```

**Linux — required system dependency:**
```bash
sudo apt-get install libayatana-appindicator3-dev
# or:
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

> **GNOME (Linux):** The [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) shell extension may be required to display the tray icon in GNOME environments.

### Basic Setup

```dart
import 'package:flutter/material.dart' hide MenuItem; // Important: hide MenuItem to avoid conflict
import 'package:tray_manager/tray_manager.dart';

Future<void> initTray() async {
  await trayManager.setIcon(
    Platform.isWindows
        ? 'images/tray_icon.ico'  // Windows requires .ico
        : 'images/tray_icon.png', // macOS and Linux use .png
  );
  await trayManager.setToolTip('My App'); // macOS and Windows only

  await trayManager.setContextMenu(Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Show Window'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Exit'),
    ],
  ));
}
```

### Full API

```dart
await trayManager.setIcon('images/tray.png');
await trayManager.setIconPosition(TrayIconPositionMode.auto); // macOS only
await trayManager.setToolTip('My App');                       // macOS, Windows
await trayManager.setContextMenu(menu);
await trayManager.popUpContextMenu();                         // macOS, Windows
final Rect? bounds = await trayManager.getBounds();           // macOS, Windows
await trayManager.destroy();
```

### `TrayListener` Mixin — All Events

```dart
class _MyState extends State<MyWidget> with TrayListener {
  @override void initState() { super.initState(); trayManager.addListener(this); }
  @override void dispose() { trayManager.removeListener(this); super.dispose(); }

  @override void onTrayIconMouseDown() { trayManager.popUpContextMenu(); }
  @override void onTrayIconRightMouseDown() {}
  @override void onTrayIconRightMouseUp() {}
  @override void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window': windowManager.show();
      case 'exit_app': windowManager.destroy();
    }
  }
}
```

### Pattern: Minimize to Tray (`tray_manager` + `window_manager`)

```dart
// Intercept close button → hide to tray instead of quitting
@override
void onWindowClose() async {
  await windowManager.hide(); // Window hidden, tray icon stays active
}

// Tray icon left-click → restore window
@override
void onTrayIconMouseDown() => windowManager.show();
```

### Known Issues

- **`app_links` conflict:** If used together, `app_links` must be `>= 6.3.3`. Older versions block event propagation and prevent tray menu item clicks from firing.
- **GNOME (Linux):** Tray icon may not appear without the [AppIndicator extension](https://extensions.gnome.org/extension/615/appindicator-support/).

### Real-World Pattern: Windows Tray Icon Path Resolution

On Windows, `tray_manager` **rejects Flutter asset paths** (`'assets/icon.png'`). It requires an **absolute on-disk path** to a `.ico` file. The path differs between `flutter run` (debug) and the compiled release. This helper resolves both:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

String resolveTrayIconPath() {
  if (Platform.isWindows) {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = [
      p.join(exeDir, 'resources', 'app_icon.ico'),                                      // Release
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'), // Debug
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),                   // Fallback
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
  }
  return 'assets/tray_icon.png'; // macOS and Linux accept Flutter asset paths
}

// Usage in main():
await trayManager.setIcon(resolveTrayIconPath());
```

### Real-World Pattern: Platform-Specific Right-Click Event Differences

Each OS fires the context-menu event at a different moment. Missing this causes the menu to never appear on one platform:

```dart
/// WINDOWS: context menu on right mouse DOWN
@override
void onTrayIconRightMouseDown() {
  if (Platform.isWindows) trayManager.popUpContextMenu();
}

/// LINUX: context menu on right mouse UP
@override
void onTrayIconRightMouseUp() {
  if (Platform.isLinux) trayManager.popUpContextMenu();
}

/// macOS: OS handles right-click natively — do NOT call popUpContextMenu()
```

### Real-World Pattern: Restore Window from Tray (Wayland Workaround)

On Linux/Wayland, `windowManager.show()` alone may fail to bring the window to the foreground. Production-proven solution:

```dart
@override
void onTrayIconMouseDown() async {
  if (!await windowManager.isFocused()) {
    if (await windowManager.isMinimized()) await windowManager.restore();
    if (Platform.isLinux) await windowManager.hide(); // Wayland: hide first to force re-raise
    await windowManager.show();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await Future.delayed(const Duration(milliseconds: 300));
    await windowManager.setAlwaysOnTop(false);
  }
}
```

---

## `desktop_multi_window` — ✅ REQUERIDO en Stable 3.41

> **Usa este plugin para multi-window en producción.** Las APIs nativas del SDK (`RegularWindowController`, etc.) son `@internal` y solo accesibles en canal `main` con feature flag experimental.
>
> `desktop_multi_window: ^0.3.0` es la solución de producción para Flutter stable 3.41.

Arquitectura: **engine Flutter independiente por ventana** (multi-process). Comunicación via `WindowMethodChannel`.

| `desktop_multi_window` (Stable) | API Nativa SDK (Experimental — NO disponible en stable) |
|---|---|
| `WindowController.create(WindowConfiguration(...))` | `RegularWindowController()` — `@internal` |
| `WindowController.fromCurrentEngine()` | — no equivalente en stable |
| `WindowMethodChannel('name', mode: ChannelMode.unidirectional)` | Estado compartido directo (proyectado) |
| `controller.hide()` / `controller.close()` | `PlatformDispatcher.instance.closeView(viewId)` — NO existe en stable |
| `WindowController.getAll()` | `PlatformDispatcher.instance.views` — solo accesible via `@internal` |
| `WindowConfiguration(arguments: jsonEncode({...}))` | Constructor `@internal` con parámetros distintos |

---

## Native `MenuBar` + Keyboard Shortcuts (SDK — No Plugin Required)

Flutter Desktop natively provides `MenuBar`, `MenuItemButton`, `SubmenuButton`, and `MenuAcceleratorLabel`. The correct pattern wraps `Scaffold.body` with `CallbackShortcuts` + `Focus`.

**Critical rule:** A shortcut in `MenuItemButton.shortcut` only fires when the **menu is open**. `CallbackShortcuts` + `Focus(autofocus: true)` are **required** for global keyboard shortcuts.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openNewDialog,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _showPrintDialog,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refresh,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            MenuBar(
              children: [
                SubmenuButton(
                  child: const MenuAcceleratorLabel('&File'), // Alt+F to open
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add, size: 16),
                      onPressed: _openNewDialog,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                      child: const MenuAcceleratorLabel('&New\tCtrl+N'),
                    ),
                    const Divider(),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.print, size: 16),
                      onPressed: _showPrintDialog,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyP, control: true),
                      child: const MenuAcceleratorLabel('&Print\tCtrl+P'),
                    ),
                    const Divider(),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.exit_to_app, size: 16),
                      onPressed: _exitApp,
                      child: const MenuAcceleratorLabel('E&xit'),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(child: _currentView),
          ],
        ),
      ),
    ),
  );
}
```

| Concept | Detail |
|---|---|
| `MenuAcceleratorLabel('&File')` | `&` marks the next letter as Alt accelerator (`Alt+F`) |
| `'\tCtrl+N'` in label | Tab character produces native right-aligned shortcut hint |
| `CallbackShortcuts` + `Focus(autofocus:true)` | Required for global shortcuts (without menu open) |
| `RawMenuAnchor` | Fully custom menu with no default styling (Flutter 3.32+) |

---

## Plugin `local_notifier` — Desktop OS Notifications

Dispatches native desktop notifications (Windows Notification Center, macOS, libnotify on Linux).

```yaml
dependencies:
  local_notifier: ^0.1.5
```

```dart
import 'package:local_notifier/local_notifier.dart';

// main() — required before showing notifications
await localNotifier.setup(appName: 'My App');

// Simple notification
await LocalNotification(title: 'My App', body: 'Task complete.').show();

// With action buttons
final n = LocalNotification(
  title: 'New Message',
  body: 'You have a new message.',
  actions: [
    LocalNotificationAction(type: 'button', text: 'Open'),
    LocalNotificationAction(type: 'button', text: 'Dismiss'),
  ],
);
n.onClickAction = (i) { if (i == 0) windowManager.show(); };
await n.show();
```

---

## Desktop Database: `sqflite_common_ffi` + `path_provider`

`sqflite` is bound to Java/ObjC mobile wrappers and **cannot be used directly on desktop**. Use `sqflite_common_ffi` which links SQLite via FFI to system C libraries.

```yaml
dependencies:
  sqflite_common_ffi: ^2.3.3
  path_provider: ^2.1.4
  path: ^1.9.0
```

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async => _db ??= await _initDB('app.db');

  Future<Database> _initDB(String fileName) async {
    // CRITICAL: initialize FFI before any database operation
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    return databaseFactory.openDatabase(
      join(dir.path, fileName),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) => db.execute('''
          CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)
        '''),
      ),
    );
  }
}
```

| `path_provider` Method | Windows | macOS | Linux |
|---|---|---|---|
| `getApplicationDocumentsDirectory()` | `Documents\AppName` | `~/Documents` | `~/Documents` |
| `getApplicationSupportDirectory()` | `AppData\Roaming\AppName` | `~/Library/Application Support/AppName` | `~/.local/share/AppName` |
| `getTemporaryDirectory()` | `%TEMP%` | `/tmp` | `/tmp` |
| `getDownloadsDirectory()` | `Downloads` | `~/Downloads` | `~/Downloads` |

---

## Theme Management: `flutter_riverpod` + `shared_preferences`

Pattern for dynamic theme (Light/Dark/System) + accent color with cross-session persistence:

```dart
class ThemeSettings {
  final ThemeMode mode;
  final Color accentColor;
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.accentColor = const Color(0xFF1565C0),
  });
  ThemeSettings copyWith({ThemeMode? mode, Color? accentColor}) => ThemeSettings(
    mode: mode ?? this.mode, accentColor: accentColor ?? this.accentColor,
  );
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() { _load(); return const ThemeSettings(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode');
    final colorInt = prefs.getInt('accent_color');
    state = ThemeSettings(
      mode: modeStr != null
          ? ThemeMode.values.firstWhere((e) => e.name == modeStr, orElse: () => ThemeMode.system)
          : ThemeMode.system,
      accentColor: colorInt != null ? Color(colorInt) : const Color(0xFF1565C0),
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    (await SharedPreferences.getInstance()).setString('theme_mode', mode.name);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    (await SharedPreferences.getInstance()).setInt('accent_color', color.toARGB32());
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(ThemeNotifier.new);

// MaterialApp consumption:
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      themeMode: theme.mode,
      theme: ThemeData(colorSchemeSeed: theme.accentColor, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: theme.accentColor, brightness: Brightness.dark),
      home: const MainWindow(),
    );
  }
}

---

## PDF Generation & Native Printing: `pdf` + `printing`

Two complementary plugins by the same author (DavBfr):
- **`pdf`** — Builds PDF documents using a widget API *identical* to Flutter (`pw.Column`, `pw.Text`, `pw.Table`, etc.) but rendering to PDF vectors, not the screen.
- **`printing`** — Bridge to native OS print spoolers on Windows, macOS, and Linux. Also supports saving to disk, print preview, and sharing.

```yaml
dependencies:
  pdf: ^3.11.1
  printing: ^5.13.2
```

### Generate a PDF Document

All `pdf` widgets use the `pw` prefix to distinguish them from Flutter widgets:

```dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintService {
  /// Returns PDF bytes. Pass to `Printing.layoutPdf` or save with `File.writeAsBytes()`.
  static Future<Uint8List> generatePdf(List<Map<String, dynamic>> rows) async {
    final pdf = pw.Document(title: 'Report', creator: 'My App');

    // pw.MultiPage handles pagination automatically
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Users Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headers: ['ID', 'Name', 'D.O.B', 'Phone'],
            data: rows.map((r) => [
              r['id'].toString(), r['name'], r['dob'], r['phone'],
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
    return pdf.save();
  }
}
```

### Print / Preview / Save to Disk

```dart
import 'package:printing/printing.dart';

// Open native OS print dialog
await Printing.layoutPdf(
  onLayout: (format) => PrintService.generatePdf(rows),
  name: 'Users Report',
);

// Save PDF to Downloads folder without print dialog
final bytes = await PrintService.generatePdf(rows);
final file = File(p.join((await getDownloadsDirectory())!.path, 'report.pdf'));
await file.writeAsBytes(bytes);

// Share / open with external viewer
await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
```

### `pw` Widget API (Flutter Analogues)

| `pw` Widget | Flutter Equivalent | Notes |
|---|---|---|
| `pw.Document()` | — | Root PDF container |
| `pw.Page` / `pw.MultiPage` | — | `MultiPage` auto-paginates |
| `pw.Text(s, style: pw.TextStyle(...))` | `Text` | Does NOT accept Flutter's `TextStyle` |
| `pw.Column` / `pw.Row` / `pw.Stack` | Direct equivalents | Same layout model |
| `pw.Container` / `pw.SizedBox` | Direct equivalents | — |
| `pw.Image(MemoryImage(bytes))` | `Image.memory` | Requires `Uint8List` |
| `pw.Table.fromTextArray(...)` | `DataTable` | Headers + styled cells |
| `pw.Header` | — | Styled section header |
| `PdfColors.blue800` | `Colors.blue[800]` | PDF-specific color palette |
| `PdfPageFormat.a4` | — | Page size (also `letter`, `legal`, ...) |

### Custom Fonts

```dart
final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
final ttf = pw.Font.ttf(fontData);

pdf.addPage(pw.Page(
  build: (ctx) => pw.Text('Hello', style: pw.TextStyle(font: ttf)),
));
