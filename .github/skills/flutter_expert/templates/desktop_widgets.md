# 🖥️ Desktop Platform — Widget & API Updates (Flutter 3.27 → 3.41)

This document catalogs **every** new widget, updated widget, new property, and API change relevant to **Windows**, **macOS**, and **Linux** desktop targets introduced from Flutter 3.27 through 3.41.

---

## Multi-Window Support (3.32 / 3.35 / 3.41)

### Regular Windows — Linux (3.41)
- **New API**: `Regular Windows` implementation for Linux allows creating standard OS windows from Flutter.
- Canonical contributed fixes for accessibility, app lifecycle, focus traversal, and input events in multi-window contexts.

### Dialog Windows — Windows Win32 (3.41)
- **New API**: Native dialog windows implemented for the Windows platform.

### Popup / Dialog / Tooltip Windows (3.41)
- Flutter 3.41 officially supports **multi-window popups**, **dialogs**, and **tooltip windows** natively on Windows, macOS, and Linux. Community plugins for multi-window are no longer necessary.

### Desktop Multi-Window Progress (3.32)
- Significant progress in multi-window support across desktop platforms. Canonical addressed issues related to:
  - Accessibility in multi-window contexts
  - App lifecycle management across windows
  - Focus traversal between windows
  - Input event handling across multiple surfaces

---

## Multi-Window Architecture — Single Isolate (3.4x Deep Dive)

### Architecture Principle
- All windows in a Flutter 3.4x desktop app share a **single Dart Isolate** and a single engine instance. There is **no separate process or serialization** between windows.
- This is a fundamental departure from community plugins (`multi_window_manager`, `bitsdojo_window`, etc.) which spawn separate engine instances per window.
- **Consequence:** Any state manager (Riverpod, Bloc, Signals) works cross-window out of the box. A `Stream` update in Window A immediately rebuilds widgets in Window B.

### `PlatformDispatcher` — Core API
- `PlatformDispatcher.instance.requestView()` — Opens a new native OS window and returns its `viewId`.
- `PlatformDispatcher.instance.closeView(int viewId)` — Destroys the view. Never close `viewId == 0` (main window).
- `PlatformDispatcher.instance.views` — Iterable of all currently open `FlutterView`s.

```dart
import 'dart:ui';

// Open a new window
void openWindow() {
  PlatformDispatcher.instance.requestView();
}

// Close a secondary window safely
void closeWindow(int viewId) {
  if (viewId != 0) {
    PlatformDispatcher.instance.closeView(viewId);
  }
}
```

### Route Content by `viewId`
- Use `View.of(context).viewId` as the discriminator inside `MaterialApp.builder` to render different widget trees per window:

```dart
MaterialApp(
  builder: (context, child) {
    return switch (View.of(context).viewId) {
      0 => const MainWindow(),
      1 => const ToolPanelWindow(),
      _ => const GenericWindow(),
    };
  },
);
```

### `SystemChannels.window` — Runtime Window Control
All per-window operations are invoked via `SystemChannels.window.invokeMethod(method, {'id': viewId, ...})`:

| Method | Description |
|---|---|
| `setWindowTitle` | Change the OS title bar text for a specific window |
| `setWindowIcon` | Set a distinct taskbar/dock icon for a specific window |
| `minimize` | Minimize a specific window to the taskbar |
| `maximize` | Maximize/restore a specific window |
| `startDragging` | Begin native OS drag of window (for frameless title bars) |

### Performance: Native SDK vs Legacy Plugins

| Metric | Legacy Plugins | Native SDK 3.4x |
|---|---|---|
| Window open time | ~1.5 s | ~100 ms |
| CPU usage (idle) | 2–5% per window | < 0.5% global |
| Cross-window communication | Async (Method Channels + JSON) | Synchronous (direct memory reference) |
| Hot Reload | Manual per engine | Unified (one click, all windows) |

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
                onPressed: () => viewId == 0
                    ? SystemNavigator.pop()
                    : PlatformDispatcher.instance.closeView(viewId),
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
- Native system tray (notification area) integration is available without external plugins in SDK 3.4x.
- Supports minimize-to-tray, tray icon menus, and tray tooltips natively via platform channels.

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
