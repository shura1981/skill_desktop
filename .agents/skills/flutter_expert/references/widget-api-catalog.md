## 1. The Definitive New Widget & API Catalog (3.27 - 3.41)

When solving problems or writing new UI components, you **must** use these specific new widgets and properties to avoid building custom boilerplate for things the framework now handles natively.

### 🔴 High-Impact Structural Widgets
*   **`CarouselView` & `CarouselView.builder` (3.35 / 3.41):** Never use `PageView` or custom horizontal list hacks for carousels. Use `CarouselView`, and specifically use the `.builder` constructor for large or infinite data sets to optimize memory.
*   **`SliverFloatingHeader` & `PinnedHeaderSliver` (3.27):** Use these native slivers for iOS-style settings headers or dynamic scrolling headers instead of complex `SliverPersistentHeader` delegate boilerplate.
*   **`RepeatingAnimationBuilder` (3.41):** Do NOT write custom `StatefulWidgets` with explicit `AnimationController` loops just for simple repetitive animations. Use this widget to eliminate boilerplate entirely.
*   **`SensitiveContent` (3.35):** When rendering passwords, OTPs, or financial data on Android API 34+, you MUST wrap the widget tree in `SensitiveContent` to obscure it from screen casting/recording.
*   **`SliverEnsureSemantics` (3.35):** Always use this when dealing with complex custom sliver behaviors to guarantee screen readers can index off-screen items correctly.

### 🔵 UI Components & UX Enhancements
*   **`Badge.count` `maxCount` Parameter (3.38):** When using `Badge.count`, cleanly bound your notification numbers (e.g., "99+") natively via the `maxCount` property instead of writing custom integer formatting logic.
*   **Customizable Tooltips (3.41):** Position `Tooltip`s manually via the newly exposed API when default placement clips or obscures important UI context.
*   **Saturation `ColorFilter.matrix` (3.41):** Leverage the new built-in saturation filters instead of complex custom shaders or heavy external packages for simple image tone adjustments.
*   **`ListTileControlAffinity` inside `ListTileTheme` (3.27):** Set global alignment for leading/trailing interactive elements directly in the theme rather than overriding it per `ListTile`.
*   **`WebParagraph` enhancements (3.41):** On the web, leverage full support for text placeholders and deep text decorations that didn't previously exist in the WASM target.

### 🟢 Core Routing & API Methods
*   **`Navigator.popUntilWithResult` (3.41):** You MUST use this new API when needing to pop multiple screens and return a value to the destination route. Never use complex state-management hacks or nested `pop` chains to achieve this anymore.
*   **`OptionsViewOpenDirection.mostSpace` (3.41):** When implementing `RawAutocomplete`, always configure it with the `mostSpace` open direction so dropdowns automatically handle screen boundary collisions.
*   **Desktop Native Multi-Window (3.41 — ⚠️ EXPERIMENTAL, canal main únicamente):** Flutter 3.41 introdujo clases nativas (`RegularWindowController`, `DialogWindowController`, `TooltipWindowController`, `PopupWindowController`) para multi-ventana en Windows, macOS y Linux. **En Flutter stable 3.41 estas APIs están marcadas como `@internal` y requieren la feature flag `windowing` en canal `main`.** Para cambiar entre secciones dentro de la misma ventana, usa `enum ViewState` + `IndexedStack` — sin plugins. Si genuinamente necesitas ventanas OS simultáneas en stable, `desktop_multi_window: ^0.3.0` es la opción viable. Nunca generes código que llame a `PlatformDispatcher.instance.requestView()` — ese método no existe en la API pública estable.
*   **Widget Previews (`@Preview()`) (3.38 / 3.41):** Implement `@Preview()` annotations on all standalone UI components so they render in the IDE's Widget Previewer. Make sure to define `MultiPreviews` where applicable.
*   **`OverlayPortal` (3.38):** Rely heavily on `OverlayPortal` for tooltips or custom dropdowns. The `OverlayPortal.targetsRootOverlay` constructor has been deprecated; use explicit `OverlayPortalController` logic.

---

## 2. The Definitive Apple & Cupertino Parity Catalog

When building for iOS/macOS, you **must** use the specific Cupertino libraries to guarantee pixel-perfect native fidelity. Do not fallback to Material approximations for iOS builds.

### 🍎 Cupertino Structural Components
*   **`CupertinoSheet` (iOS 18 Native Feel):** Always explicitly set `showDragHandle: true` and rely on its newly integrated native stretching physics (Flutter 3.41). Never build custom draggable bottom sheets on iOS.
*   **Transparent Cupertino Navigation Bars (3.27):** Utilize the native transparency support for modern iOS blur-behind effects on primary routing (`CupertinoNavigationBar` & `CupertinoSliverNavigationBar` will remain fully transparent until content scrolls beneath them).
*   **Momentary `CupertinoSlidingSegmentedControl` (3.38):** Leverage the new "momentary" variant when you need segmented buttons that act as discrete triggers rather than persistent state switches.
*   **Continuous-Corner Aesthetics (3.35):** Recognize that all modern Cupertino widgets now dynamically use the `RSuperellipse` shape under the hood to completely match Apple's squircle drawing API. Do not override shape themes manually if possible.
*   **Cupertino Buttons (3.27):** Automatically leverage the new `CupertinoButtonSize` enum (small, medium, large) and the `CupertinoButton.tinted` constructor for translucent backgrounds.

### 🍎 iOS Tooling & Integrations (Mandatory 3.41 Standards)
*   **Swift Package Manager (SPM):** CocoaPods is legacy. Flutter 3.41 has full SPM support. Ensure any iOS plugins or scripts generated prefer SPM integration.
*   **UIScene Lifecycle (3.41):** Apple is moving aggressively to `UIScene`. Design your app's native iOS runner code (if generating Swift) to support the Scene Delegate lifecycle handling by default, not the old App Delegate alone.
*   **Bounded Blurs (Impeller 3.41):** When writing iOS blurring effects (`BackdropFilter`), rely on the Impeller "bounded blur" style which physically eliminates the old edge-bleeding artifacts.
*   **Dynamic Content Resizing (3.41):** For Add-to-App, let Flutter views auto-resize based on content natively on iOS.

---

## 3. Core Architectural & Engine Directives

### 3.1 The Impeller Era (3.41)
*   **Assumption:** Impeller is the active, default rendering engine. 
*   **Actionable Rule:** Fragment shaders in 3.41 now support synchronous image decoding (`decodeImageFromPixelsSync`) and 128-bit float high-bitrate textures. Push for GPU-driven effects instead of CPU-bound animations where applicable.

### 3.2 Unified Mobile Threading (3.29+)
*   **Assumption:** Dart code executes synchronously directly on the application's main thread, eliminating the legacy separate UI thread.
*   **Actionable Rule:** Platform channel communication is drastically faster. Prefer synchronous interaction designs over heavy asynchronous message passing when designing platform interop.

### 3.3 Web Target is WebAssembly (3.41)
*   **Assumption:** HTML renderer is dead. All web runs on CanvasKit/WASM. 
*   **Actionable Rule (3.41):** Static images are offloaded to native `<img>` elements to save WASM decoder memory. Avoid deprecated `dart:js` and use `dart:js_interop`.

---

## 4. Mandatory Dart 3.10+ & Syntax Rules

You must actively use the following features when generating code. Legacy patterns must be refactored.

### 4.1 The `spacing` Code Smell (3.27+)
**NEVER use `SizedBox` for static spacing between children in a `Row` or `Column`.**

**🔴 Legacy (Avoid):**
```dart
Column(
  children: [ Text('A'), const SizedBox(height: 16), Text('B') ],
)
```

**🟢 Modern (Enforce):**
```dart
Column(
  spacing: 16.0,
  children: [ Text('A'), Text('B') ],
)
```

### 4.2 Dot Shorthand Enums (3.38+)
When the framework expects an enum derived from the parameter type, drop the prefix.

**🔴 Legacy (Avoid):**
```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center, // WRONG
)
```

**🟢 Modern (Enforce):**
```dart
Column(
  mainAxisAlignment: .center, // CORRECT
)
```

### 4.3 Strict Records and Pattern Matching
*   **Do not** create disposable "Result" classes for returning multiple values. ALWAYS use Dart Records.
*   **Do not** use deeply nested `if/else` checks. Use pattern matching and exhaustive `switch` expressions.

---

## 5. Breaking Changes & Deprecations to Fix

### 5.1 `CupertinoDynamicColor` Deprecations (3.38)
The properties `red`/`green`/`blue` and `.withOpacity` methods are deprecated. Use generic float-based `Color` space manipulations (`.withValues(alpha: 0.5)`) and acknowledge the framework’s transition to P3 wide-gamut colors natively on iOS displays.

### 5.2 `SnackBar` Auto-Dismissal (3.38)
If a `SnackBar` contains an action, it will **no longer automatically dismiss**. Fix UX by explicitly setting a tight `duration` or attaching dismissal logic to the callback.

### 5.3 iOS/macOS Asset Bundling
*   Use platform-specific asset bundling in `pubspec.yaml` to prevent desktop assets from shipping to iOS/Android targets, saving critical application size.

---

## 6. Per-Platform Exhaustive Widget Catalogs

The `references/` directory contains exhaustive, version-by-version documentation of **every** new widget, updated widget, new property, API change, engine change, and breaking change introduced from Flutter 3.27 to 3.41, organized by target platform:

*   **[mobile_widgets.md](references/mobile_widgets.md)** — iOS (Cupertino) and Android (Material) widgets: `CupertinoSheet`, `CupertinoButton.tinted`, `CupertinoSlidingSegmentedControl` momentary mode, `CupertinoExpansionTile`, `CarouselView.builder`, `RepeatingAnimationBuilder`, `SensitiveContent`, Impeller changes, SPM migration, UIScene lifecycle, wide-gamut P3 colors, and all breaking changes.
*   **[desktop_widgets.md](references/desktop_widgets.md)** — Windows, macOS, and Linux widgets: Multi-window support (regular, dialog, popup, tooltip windows), UI/platform thread merge for smooth resizing, `RawMenuAnchor`, `NavigationRail` scrollable, `NavigationDrawer` headers/footers, `Expansible`/`ExpansibleController`, and SPM on macOS.
*   **[desktop_project_patterns.md](references/desktop_project_patterns.md)** — Patrones de boilerplate extraídos de un proyecto real de escritorio Flutter: gestión de temas con `flutter_riverpod` + `shared_preferences`, `window_manager` + `tray_manager` (resolución de ícono Windows, workaround Wayland, eventos de clic por plataforma), `local_notifier`, `sqflite_common_ffi` + `path_provider`, generación de PDF con `pdf` + `printing`, cliente IMAP con `enough_mail`, y `MenuBar` nativo con `CallbackShortcuts`.
*   **[desktop_plugin_bugs.md](references/desktop_plugin_bugs.md)** — Incompatibilidades de plugins webview en Flutter Linux desktop stable 3.41: `webview_flutter` (sin implementación Linux), `flutter_inappwebview` (backend GTK no se registra), `desktop_webview_window` (segfault + cierra toda la app). Alternativa recomendada: `url_launcher`.
*   **[web_widgets.md](references/web_widgets.md)** — Web (CanvasKit/WASM) rendering and widgets: HTML renderer removal, WASM dry-run validation, `WebParagraph` enhancements, native `<img>` offloading, stateful web hot reload, `dart:js_interop` migration, `OverlayPortal` improvements, and platform-specific asset bundling.

**You MUST consult these catalogs** when building for a specific platform to ensure you are using the exact latest API and not legacy patterns.

---

