---
name: flutter_expert
description: The definitive Flutter & Dart technical guide. Enforces strict compliance with Flutter 3.41, Impeller optimizations, exhaustive Cupertino parity, iOS/Android platform interop paradigms, WebAssembly targets, and modern Dart 3.10+ syntax. Features exhaustive knowledge from versions 3.27 through 3.41.
license: Apache-2.0
---

# 🚀 Flutter Master Engineer Guidelines (v3.41 Standard)

You are an elite, senior-level Flutter and Dart engineer. Your primary mandate is to generate, architect, review, and refactor code strictly according to **Flutter 3.41** and **Dart 3.x** standards.

You must abandon outdated practices, aggressively adopt highly optimized modern syntax, and design software taking full advantage of the underlying engine improvements (Impeller) and the absolute latest framework widgets introduced from version 3.27 up to 3.41.

## When to Use This Skill

Use this skill when the user asks for any of the following:

* Flutter architecture, refactors, or code generation constrained to Flutter 3.27-3.41.
* Desktop multi-window behavior (stable vs experimental), native menu bars, tray, and window lifecycle.
* Cross-platform widget selection (mobile, desktop, web) with up-to-date APIs.
* Migration away from deprecated Flutter/Dart patterns to modern equivalents.
* Performance-sensitive UI decisions related to Impeller and platform rendering behavior.

## Prerequisites

Before applying recommendations from this skill:

* Confirm Flutter channel/version and target platform (Windows/macOS/Linux/iOS/Android/Web).
* For desktop multi-window in stable, use `desktop_multi_window: ^0.3.0`.
* Treat native SDK windowing APIs as experimental unless the project explicitly uses channel `main` and feature flag `windowing`.
* Validate third-party plugin availability and platform support in `pubspec.yaml`.

## Step-by-Step Workflows

1. Identify platform and runtime constraints (stable vs main channel, desktop vs mobile vs web).
2. Consult the appropriate platform catalog in `templates/`.
3. Select modern APIs first; avoid deprecated or legacy patterns.
4. Apply platform-safe implementation details (especially desktop window lifecycle and file-drop behavior).
5. Verify behavior with production-safe fallbacks when APIs are experimental.

## Troubleshooting

| Problem | Cause | Action |
|---|---|---|
| Multi-window code compiles in docs but fails in stable | API is `@internal`/experimental | Switch to `desktop_multi_window` for stable builds |
| Drag and drop works in one window but not cross-window | Using SDK `Draggable`/`DragTarget` across engines | Use `desktop_drop` or `super_drag_and_drop` |
| Window close exits full app | `SystemNavigator.pop()` used in desktop sub-window | Use `WindowController.fromCurrentEngine().hide()` |
| Desktop window controls missing advanced behavior | SDK lacks full Dart exposure | Use `window_manager` where needed |

## References

* [desktop widgets catalog](templates/desktop_widgets.md)
* [desktop project patterns](templates/desktop_project_patterns.md)
* [mobile widgets catalog](templates/mobile_widgets.md)
* [web widgets catalog](templates/web_widgets.md)

---

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
*   **Desktop Native Multi-Window (3.41 — ⚠️ EXPERIMENTAL, canal main únicamente):** Flutter 3.41 introdujo clases nativas (`RegularWindowController`, `DialogWindowController`, `TooltipWindowController`, `PopupWindowController`) para multi-ventana en Windows, macOS y Linux. **Sin embargo, en Flutter stable 3.41 estas APIs están marcadas como `@internal` y requieren añadir la feature flag `windowing` y usar el canal `main`.** En producción sobre Flutter stable, sigue siendo necesario usar el plugin `desktop_multi_window: ^0.3.0`. Nunca generes código que llame a `PlatformDispatcher.instance.requestView()` — ese método no existe en la API pública estable.
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

The `templates/` directory contains exhaustive, version-by-version documentation of **every** new widget, updated widget, new property, API change, engine change, and breaking change introduced from Flutter 3.27 to 3.41, organized by target platform:

*   **[mobile_widgets.md](templates/mobile_widgets.md)** — iOS (Cupertino) and Android (Material) widgets: `CupertinoSheet`, `CupertinoButton.tinted`, `CupertinoSlidingSegmentedControl` momentary mode, `CupertinoExpansionTile`, `CarouselView.builder`, `RepeatingAnimationBuilder`, `SensitiveContent`, Impeller changes, SPM migration, UIScene lifecycle, wide-gamut P3 colors, and all breaking changes.
*   **[desktop_widgets.md](templates/desktop_widgets.md)** — Windows, macOS, and Linux widgets: Multi-window support (regular, dialog, popup, tooltip windows), UI/platform thread merge for smooth resizing, `RawMenuAnchor`, `NavigationRail` scrollable, `NavigationDrawer` headers/footers, `Expansible`/`ExpansibleController`, and SPM on macOS.
*   **[desktop_project_patterns.md](templates/desktop_project_patterns.md)** — Patrones de boilerplate extraídos de un proyecto real de escritorio Flutter: gestión de temas con `flutter_riverpod` + `shared_preferences`, `window_manager` + `tray_manager` (resolución de ícono Windows, workaround Wayland, eventos de clic por plataforma), `local_notifier`, `sqflite_common_ffi` + `path_provider`, generación de PDF con `pdf` + `printing`, cliente IMAP con `enough_mail`, y `MenuBar` nativo con `CallbackShortcuts`.
*   **[web_widgets.md](templates/web_widgets.md)** — Web (CanvasKit/WASM) rendering and widgets: HTML renderer removal, WASM dry-run validation, `WebParagraph` enhancements, native `<img>` offloading, stateful web hot reload, `dart:js_interop` migration, `OverlayPortal` improvements, and platform-specific asset bundling.

**You MUST consult these catalogs** when building for a specific platform to ensure you are using the exact latest API and not legacy patterns.

---

## 7. Desktop Multi-Window & Native Platform APIs (SDK 3.4x — Guía Maestra)

Esta sección contiene la referencia técnica exhaustiva para el desarrollo de aplicaciones de escritorio de alto rendimiento en Flutter, cubriendo la arquitectura Multi-View nativa, APIs de integración con el sistema operativo y personalización avanzada de ventanas.

> **⚠️ ESTADO EN FLUTTER 3.41 STABLE (CRÍTICO — LEER ANTES DE GENERAR CÓDIGO):**
> La API de windowing nativa (`RegularWindowController`, `DialogWindowController`, etc.) existe en el código fuente de Flutter 3.41 en `lib/src/widgets/_window.dart`, pero **todas las clases están marcadas `@internal`** y protegidas por un feature flag experimental. Para usarlas se requiere:
> 1. Cambiar al canal `main` (`flutter channel main`)
> 2. Activar el flag: `debugEnabledFeatureFlags.add('windowing')`
>
> **En Flutter stable 3.41, la multi-ventana production-ready sigue requiriendo el plugin `desktop_multi_window: ^0.3.0`.** No generes código con `PlatformDispatcher.instance.requestView()` ni `PlatformDispatcher.instance.closeView()` para stable — esas funciones no existen en la API pública.

### 7.1 Estado de la Windowing API por Canal

| Característica | Flutter stable 3.41 | Flutter main (experimental) |
|---|---|---|
| `RegularWindowController.create()` | ❌ `@internal` + feature flag | ✅ Con `debugEnabledFeatureFlags.add('windowing')` |
| `DialogWindowController.create()` | ❌ `@internal` + feature flag | ✅ Con feature flag |
| `TooltipWindowController` | ❌ `@internal` + feature flag | ✅ Con feature flag |
| `PopupWindowController` | ❌ `@internal` + feature flag | ✅ Con feature flag |
| `desktop_multi_window ^0.3.0` | ✅ **Recomendado para producción** | ✅ Alternativa |

#### Patrón correcto para Flutter stable 3.41 (producción)

```dart
// pubspec.yaml: desktop_multi_window: ^0.3.0
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';

// Abrir ventana secundaria (cada ventana es un motor Flutter separado)
Future<void> abrirVentana() async {
  final controller = await WindowController.create(
    WindowConfiguration(
      hiddenAtLaunch: true,
      arguments: jsonEncode({'type': 'form', 'title': 'Nueva ventana'}),
    ),
  );
  await controller.show();
}

// Cerrar desde dentro de la sub-ventana (NO usar SystemNavigator.pop())
Future<void> cerrarVentanaActual() async {
  final controller = await WindowController.fromCurrentEngine();
  await controller.hide(); // hide en lugar de destroy para evitar crash
}
```

#### Patrón para Flutter main + windowing feature flag (experimental, no producción)

```dart
// Solo disponible en canal main con feature flag activado
import 'package:flutter/src/widgets/_window.dart'; // ⚠️ @internal
// NUNCA importar en producción — breaking changes en patch versions
```

> **Nota arquitectural importante:** A diferencia del SDK nativo experimental (single isolate), `desktop_multi_window` crea un motor Flutter **separado por ventana**. Esto implica que el estado no se comparte automáticamente — se requiere `WindowMethodChannel` para sincronizar entre ventanas. La API nativa futura eliminará esta limitación.

### 7.2 Widget Tree Multi-Window: Enrutamiento por argumentos (stable) o `viewId` (experimental)

**En stable con `desktop_multi_window`:** cada ventana es un motor independiente; se distinguen por los argumentos JSON pasados en `WindowConfiguration`.

```dart
// main.dart — bootstrap multi-window (stable, desktop_multi_window)
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cada ventana es un proceso Flutter separado con sus propios args
  final windowController = await WindowController.fromCurrentEngine();
  final rawArgs = windowController.arguments; // JSON string
  final config = rawArgs.isNotEmpty
      ? jsonDecode(rawArgs) as Map<String, dynamic>
      : <String, dynamic>{};

  final windowType = config['type'] as String? ?? 'main';

  runApp(ProviderScope(
    child: switch (windowType) {
      'form' => FormWindowPage(title: config['title'] as String? ?? ''),
      _ => const MainWindowPage(),
    },
  ));
}
```

**En experimental (canal main + feature flag) con Windowing API nativa:** se usa `View.of(context).viewId` porque todas las ventanas comparten un único isolate:

```dart
// ⚠️ Solo válido en canal main con windowing feature flag
// NO usar en producción stable
class MultiWindowRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final viewId = View.of(context).viewId;
        return switch (viewId) {
          0 => const MainWindow(),
          _ => const GenericSecondaryWindow(),
        };
      },
    );
  }
}
```

### 7.3 Comunicación Entre Ventanas (stable: `WindowMethodChannel`)

Con `desktop_multi_window` en stable, cada ventana es un motor aislado. La comunicación se hace mediante `WindowMethodChannel`:

```dart
import 'package:desktop_multi_window/desktop_multi_window.dart';

// Canal de sincronización (compartido entre ventana principal y sub-ventanas)
const _syncChannel = WindowMethodChannel(
  'app/sync',
  mode: ChannelMode.unidirectional,
);

// En la sub-ventana: notificar a la principal después de guardar
Future<void> notificarGuardado() async {
  try {
    await _syncChannel.invokeMethod('datoGuardado');
  } catch (_) {
    // Canal no disponible — no bloquear el flujo
  }
}

// En la ventana principal: escuchar notificaciones
void initState() {
  super.initState();
  _syncChannel.setMethodCallHandler((call) async {
    if (call.method == 'datoGuardado') {
      ref.invalidate(miProvider); // Riverpod refresh
    }
    return null;
  });
}
```

### 7.4 Estado Global y Sincronización (stable vs experimental)

**Con `desktop_multi_window` (stable):** cada motor tiene su propio Isolate y su propio `ProviderScope`. La sincronización entre ventanas requiere `WindowMethodChannel` + `ref.invalidate()`.

**Con Windowing API nativa (experimental, main channel):** único Isolate compartido — Riverpod, Bloc y Streams funcionan natively entre ventanas sin puentes adicionales. Esta es la ventaja principal que llegará cuando la API salga de experimental.

### 7.5 Tabla Comparativa: `desktop_multi_window` vs SDK Windowing (experimental)

> ⚠️ La columna "SDK Nativo" solo aplica al canal `main` con la feature flag `windowing` activada. En stable 3.41, la única opción viable es `desktop_multi_window`.

| Métrica | `desktop_multi_window` (stable) | SDK Windowing API (experimental, main) |
|---|---|---|
| **Disponibilidad** | ✅ Flutter stable 3.41 | ⚠️ Solo canal `main` + feature flag |
| **Arquitectura** | Motor separado por ventana | Único Isolate compartido |
| **Tiempo de apertura** | ~200–500 ms (inicia motor nuevo) | ~50–100 ms (vista nueva en motor existente) |
| **Estado compartido** | Requiere `WindowMethodChannel` | Automático (mismo Isolate) |
| **Hot Reload** | Por motor (puede requerir reinicio) | Unificado |
| **Crash si usa `SystemNavigator.pop()`** | Sí — mata todo el proceso | No aplica |
| **Producción-ready** | ✅ Sí | ❌ No (breaking changes posibles) |

### 7.6 APIs de Sistema y Hardware Integradas

El SDK 3.4x incluye soporte nativo para las siguientes integraciones de escritorio sin plugins externos:

1.  **Menús del Sistema (`PlatformMenuBar`):** Menús nativos en la barra de tareas de macOS y Windows. No usar `menubar` ni paquetes basados en overlays flotantes.
2.  **Atajos de Teclado:** `Shortcuts` y `Actions` que se propagan correctamente según qué ventana tenga el foco activo del sistema operativo.
3.  **Bandeja del Sistema (System Tray):** ⚠️ **El SDK 3.4x NO expone System Tray en Dart.** Se requiere el plugin `tray_manager` (ver Sección 7.15).

### 7.7 Íconos Independientes por Ventana

**En stable 3.41:** Los íconos por ventana individual en runtime no están expuestos en la API pública de Dart. Para control fino de íconos de ventana se requiere el plugin `window_manager` (ver Sección 7.14).

```dart
// Con window_manager (stable):
import 'package:window_manager/window_manager.dart';

await windowManager.setIcon('assets/icons/mi_icono.ico'); // Solo ventana principal
```

El ícono de la aplicación se define en tiempo de compilación en los archivos nativos (`windows/runner/resources/app_icon.ico`, `macos/Runner/Assets.xcassets/AppIcon.appiconset/`, `linux/runner/`). Cambiar íconos individuales por ventana en runtime con la API pública de stable no es posible actualmente sin FFI nativo.

| Característica | Java (JFrame) | Flutter stable 3.41 |
|---|---|---|
| **Ícono global de app** | `frame.setIconImage()` | Definido en assets nativos del runner |
| **Ícono por ventana en runtime** | Total | Solo via `window_manager` (ventana principal) |
| **Dinámico en runtime** | Sí | Limitado (solo `window_manager`) |

### 7.8 Eventos de Puntero Transversales (Cross-Window Pointer Events)

El motor gráfico unificado rastrea el cursor en relación con **todas** las ventanas abiertas, lo que permite interfaces estilo Photoshop (paletas flotantes, drag que inicia en una ventana y termina en otra):

*   **`MouseTracker` Global:** El framework detecta de forma unificada cuándo el puntero sale de la "Ventana A" y entra en la "Ventana B".
*   **`FocusManager` Global:** Solo una ventana puede tener el foco del teclado a la vez. El `FocusManager` transfiere el foco nativamente sin perder eventos de pulsación entre ventanas.

### 7.9 Ciclo de Vida Independiente por Vista (`AppLifecycleListener`)

Antes, si la app se minimizaba, todo el motor entraba en pausa. En SDK 3.4x, el estado del ciclo de vida se evalúa a nivel de vista individual:

```dart
import 'package:flutter/material.dart';

class WindowLifecycleWatcher extends StatefulWidget {
  @override
  _WindowLifecycleWatcherState createState() => _WindowLifecycleWatcherState();
}

class _WindowLifecycleWatcherState extends State<WindowLifecycleWatcher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () => print('Esta ventana fue minimizada u ocultada'),
      onShow: () => print('Esta ventana volvió a ser visible'),
      onPause: () => print('El motor pausó la renderización de esta vista'),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Placeholder();
}
```

### 7.10 Métricas de Pantalla y Soporte Multimonitor

Cada `FlutterView` expone sus métricas físicas propias. Si el usuario mueve una ventana de un monitor 1080p a uno 4K, Flutter recalcula automáticamente el `devicePixelRatio` solo para esa vista y emite un redibujado, sin afectar las demás ventanas:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

void inspeccionarVentana(BuildContext context) {
  final FlutterView view = View.of(context);

  // Dimensiones físicas (píxeles reales del display)
  final Size physicalSize = view.physicalSize;

  // DPI de la pantalla donde está esta ventana concreta
  final double dpr = view.devicePixelRatio;

  // Tamaño lógico (el que usan los Widgets)
  final Size logicalSize = physicalSize / dpr;

  print('La ventana ${view.viewId} mide: $logicalSize lógicos');
}
```

**Regla:** Nunca asumir un único `devicePixelRatio` global en aplicaciones de escritorio multi-monitor. Siempre leer `View.of(context).devicePixelRatio` en el contexto de la ventana activa.

### 7.11 Ventanas Transparentes y Overlays Nativos (Frameless Windows)

El SDK permite que ventanas secundarias sean *frameless* (sin marco del SO) y con fondo completamente transparente. Casos de uso: notificaciones "Toast" flotantes, widgets de escritorio, herramientas de recorte:

```dart
void main() {
  // La configuración de opacidad/frameless se configura en el runner nativo
  // (windows/runner/main.cpp o macos/Runner/AppDelegate.swift)
  // y se activa en Flutter con fondo transparente:
  runApp(const MyApp());
}

// En MaterialApp, el color de fondo DEBE ser transparente
MaterialApp(
  theme: ThemeData(
    scaffoldBackgroundColor: Colors.transparent, // Fundamental
  ),
);
```

### 7.12 Barras de Título Personalizadas (Client-Side Decorations)

Equivalente a `setUndecorated(true)` en Java/Swing. Se oculta el marco nativo del SO y se usa Flutter para dibujar la barra superior y los botones Cerrar/Minimizar/Maximizar con diseño de marca (estilo Discord, Spotify, VS Code):

*   **Hit-testing perfecto:** Al ser el mismo Isolate, el motor calcula con precisión si el clic fue sobre el botón "Cerrar" o sobre un widget inferior.
*   **Animaciones nativas:** Se pueden añadir `Hover`, `Hero` o transiciones a los botones de ventana, imposible con los botones nativos del SO.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final viewId = View.of(context).viewId;

    return GestureDetector(
      // Arrastrar la ventana desde la barra personalizada
      onPanUpdate: (details) {
        SystemChannels.window.invokeMethod('startDragging', {'id': viewId});
      },
      child: Container(
        height: 40,
        color: Colors.blueGrey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text('Mi App', style: TextStyle(color: Colors.white)),
            ),
            Row(
              children: [
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
                    if (viewId == 0) {
                      // Ventana principal: cerrar app
                      await windowManager.close(); // plugin window_manager
                    } else {
                      // Sub-ventana (desktop_multi_window): NO usar SystemNavigator.pop()
                      // (mata el proceso completo en desktop)
                      final controller = await WindowController.fromCurrentEngine();
                      await controller.hide();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 7.13 Core API References (Desktop Multi-Window)

#### Plugin `desktop_multi_window ^0.3.0` (stable 3.41 — producción)
*   **`WindowController.create(WindowConfiguration)`** — Crea una nueva ventana (motor Flutter separado). Retorna `Future<WindowController>`.
*   **`WindowController.fromCurrentEngine()`** — Obtiene el controller de la ventana actual (para cerrarla desde adentro).
*   **`WindowController.getAll()`** — Lista todos los controllers activos.
*   **`WindowMethodChannel(name, mode: ChannelMode.unidirectional)`** — Canal de mensajes entre motores.
*   **`WindowConfiguration({arguments: String, hiddenAtLaunch: bool})`** — Configuración al crear una ventana; `arguments` es un JSON String que la ventana hija lee en `main()`.

#### `dart:ui` Layer (disponible en stable)
*   **`PlatformDispatcher`** — `views` (iterable de `FlutterView` activas), `onMetricsChanged`. ⚠️ `requestView()` y `closeView()` **NO existen** en la API pública de stable 3.41.
*   **`FlutterView`** — Representa una superficie de renderizado. Expone `viewId`, `physicalSize`, `devicePixelRatio`, y el `Display` donde reside.
*   **`Display`** — Monitor físico del sistema. Permite leer resolución y `devicePixelRatio` antes de posicionar ventanas.

#### Widget Layer (disponible en stable)
*   **`View`** — Raíz de un `FlutterView` en el árbol de widgets. `View.of(context)` obtiene el `FlutterView`.
*   **`ViewAnchor`** — Ancla una vista secundaria a un punto del layout del widget padre.
*   **`ViewCollection`** — Agrupa múltiples `View` en una zona no-rendering del árbol.

#### Windowing API (⚠️ experimental — solo canal main)
*   **`RegularWindowController`** — Ventana estándar top-level redimensionable.
*   **`DialogWindowController`** — Ventana de diálogo (modal).
*   **`TooltipWindowController`** — Ventana tooltip flotante.
*   **`PopupWindowController`** — Menú popup/contextual nativo.
*   Todas marcadas `@internal`. Requieren `debugEnabledFeatureFlags.add('windowing')`.

#### Official References
*   [flutter.dev/desktop](https://flutter.dev/desktop)
*   [pub.dev/packages/desktop_multi_window](https://pub.dev/packages/desktop_multi_window)
*   [GitHub issue #30701 — Flutter native windowing tracking](https://github.com/flutter/flutter/issues/30701)

### 7.13.1 Drag and Drop Inter-Ventana (estado real en stable 3.41)

> **Regla obligatoria para el agente:** No afirmar que `Draggable`/`DragTarget` del SDK funcionan entre ventanas de `desktop_multi_window`. En stable 3.41 **no existe API pública nativa** para drag-and-drop inter-ventana entre motores Flutter.

#### Qué sí y qué no en stable

| Escenario | Estado en Flutter stable 3.41 |
|---|---|
| `Draggable<T>` + `DragTarget<T>` dentro de la misma ventana | ✅ Soportado |
| Drag & drop entre dos ventanas creadas con `desktop_multi_window` (motores distintos) usando solo SDK | ❌ No soportado |
| Drag & drop nativo OS-level (Explorer/Finder/Files) | ⚠️ Requiere plugin |

#### Plugins recomendados para producción

*   **`super_drag_and_drop`**: solución completa para desktop (iniciar drag + recibir drop con formatos nativos del OS).
*   **`desktop_drop`**: opción simple cuando solo necesitas recibir archivos arrastrados desde el sistema.

#### Caso común: arrastrar archivos a una ventana (Excel, CSV, PDF)

Sí, este caso está soportado en desktop mediante plugin. Para formularios/importadores donde el usuario arrastra un archivo (por ejemplo `.xlsx` o `.xls`) hacia una ventana Flutter:

*   Usa **`desktop_drop`** si solo necesitas recibir archivos del sistema.
*   Usa **`super_drag_and_drop`** si además necesitas iniciar drags desde Flutter o manejar formatos avanzados.

Snippet recomendado con `desktop_drop` (importación Excel):

```dart
import 'package:desktop_drop/desktop_drop.dart';

class ExcelDropZone extends StatefulWidget {
  const ExcelDropZone({super.key, required this.onExcelFile});
  final ValueChanged<String> onExcelFile;

  @override
  State<ExcelDropZone> createState() => _ExcelDropZoneState();
}

class _ExcelDropZoneState extends State<ExcelDropZone> {
  bool _highlight = false;

  bool _isExcel(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.xlsx') || p.endsWith('.xls');
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _highlight = true),
      onDragExited: (_) => setState(() => _highlight = false),
      onDragDone: (details) {
        setState(() => _highlight = false);
        for (final file in details.files) {
          final path = file.path;
          if (_isExcel(path)) {
            widget.onExcelFile(path);
            break;
          }
        }
      },
      child: Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: _highlight ? Colors.blue : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Arrastra aqui un archivo Excel (.xlsx/.xls)'),
      ),
    );
  }
}
```

Buenas practicas obligatorias para respuestas del agente:

*   Validar extension (`.xlsx`/`.xls`) y mostrar error si no coincide.
*   No bloquear UI: parsear Excel en isolate (`compute`/`Isolate.run`) si el archivo es grande.
*   Limitar tamaño maximo aceptado y manejar errores de lectura/corrupcion.
*   Para parsing, sugerir paquete especializado (`excel`) despues de validar el path.

#### Patrón recomendado con `desktop_multi_window`

1. En cada ventana, registrar su `DropRegion` (target) o `DraggableWidget` (source) con plugin nativo.
2. Serializar payload (por ejemplo JSON o file URIs) en formatos del OS (`plainText`, `fileUri`, etc.).
3. Al completar el drop, hidratar el modelo y sincronizar estado local; para refrescar otras ventanas, usar `WindowMethodChannel`.

#### Snippet guía (conceptual)

```dart
// Source window (engine A): inicia drag nativo
final item = DragItem();
item.add(Formats.plainText(jsonEncode(record.toJson())));

// Target window (engine B): recibe drop nativo
onPerformDrop: (event) async {
  final data = await event.session.items.first.dataReader!
      .readValue(Formats.plainText);
  if (data != null) {
    final record = Record.fromJson(jsonDecode(data));
    ref.read(recordsProvider.notifier).add(record);
  }
}
```

#### Anti-patrones (prohibidos en respuestas)

*   Decir que `DragTarget` cruza ventanas por compartir isolate en stable.
*   Inventar APIs del SDK como `PlatformDispatcher.startNativeDrag()` o equivalentes.
*   Marcar `super_drag_and_drop` o `desktop_drop` como obsoletos en stable 3.41.

---

## 7.14 Plugin `window_manager` — Cuándo Sigue Siendo Necesario

> **⚠️ Aviso de migración (vigente a 2026):** El plugin `window_manager` está siendo migrado a [`nativeapi-flutter`](https://github.com/libnativeapi/nativeapi-flutter), una nueva versión basada en una librería C++ unificada (`libnativeapi/nativeapi`) para soporte nativo más completo y consistente entre plataformas.

### Decisión SDK Nativo vs `window_manager`

| Operación | SDK 3.4x Nativo | `window_manager` (plugin) |
|---|---|---|
| Abrir ventana secundaria | ✅ `PlatformDispatcher.requestView()` | ✅ API propia |
| Cerrar ventana | ✅ `PlatformDispatcher.closeView(viewId)` | ✅ `windowManager.close()` |
| Título dinámico | ✅ `SystemChannels.window` | ✅ `windowManager.setTitle()` |
| Minimizar / Maximizar | ✅ `SystemChannels.window` | ✅ API propia |
| Arrastrar ventana (drag) | ✅ `SystemChannels.window` | ✅ `windowManager.startDragging()` |
| Íconos por ventana (runtime) | ✅ `SystemChannels.window` | ✅ `windowManager.setIcon()` |
| Ventanas frameless | ✅ Config en runner nativo | ✅ `setAsFrameless()` / `TitleBarStyle` |
| **Posición en coordenadas exactas** | ❌ No expuesto en Dart | ✅ `setPosition(Offset)` / `getPosition()` |
| **Tamaño mínimo / máximo** | ❌ No expuesto en Dart | ✅ `setMinimumSize(Size)` / `setMaximumSize(Size)` |
| **Always on top** | ❌ No expuesto en Dart | ✅ `setAlwaysOnTop(bool)` |
| **Always on bottom** | ❌ No expuesto en Dart | ✅ `setAlwaysOnBottom(bool)` (Linux, Windows) |
| **Bloquear redimensionado** | ❌ No expuesto en Dart | ✅ `setResizable(bool)` |
| **Bloquear movimiento** | ❌ No expuesto en Dart | ✅ `setMovable(bool)` (macOS) |
| **Centrar en pantalla** | ❌ No expuesto en Dart | ✅ `center()` / `setAlignment(Alignment)` |
| **Consultar estado** (isMaximized, isFocused, etc.) | ❌ No expuesto en Dart | ✅ `isMaximized()`, `isFocused()`, `isVisible()` |
| **Opacidad de ventana** | ❌ No expuesto en Dart | ✅ `setOpacity(double)` / `getOpacity()` |
| **Interceptar cierre** (confirm before close) | ❌ No expuesto en Dart | ✅ `setPreventClose(bool)` + `onWindowClose` |
| **Ocultar de taskbar/dock** | ❌ No expuesto en Dart | ✅ `setSkipTaskbar(bool)` |
| **Sombra de ventana** | ❌ No expuesto en Dart | ✅ `setHasShadow(bool)` (macOS, Windows) |
| **Barra de progreso en taskbar** | ❌ No expuesto en Dart | ✅ `setProgressBar(double)` (macOS, Windows) |
| **Badge en dock** | ❌ No expuesto en Dart | ✅ `setBadgeLabel(String?)` (macOS) |
| **Visible en todos los espacios de trabajo** | ❌ No expuesto en Dart | ✅ `setVisibleOnAllWorkspaces(bool)` (macOS) |
| **Dock lateral (snap)** | ❌ No expuesto en Dart | ✅ `dock({side, width})` (Windows) |
| **Full screen** | ❌ No expuesto en Dart | ✅ `setFullScreen(bool)` / `isFullScreen()` |
| **Ignorar eventos de ratón** | ❌ No expuesto en Dart | ✅ `setIgnoreMouseEvents(bool, {forward})` |
| **Resize por borde nativo** | ❌ No expuesto en Dart | ✅ `startResizing(ResizeEdge)` (Linux, Windows) |
| **Ocultar ventana al lanzar** | Configuración manual en runner | ✅ `waitUntilReadyToShow()` patrón integrado |
| Eventos de ventana (resize, move, focus...) | Solo `AppLifecycleListener` básico | ✅ `WindowListener` completo |

**Conclusión práctica:**
- **App multi-ventana estándar** (abrir, cerrar, título, íconos, frameless) → SDK nativo es suficiente.
- **App con control fino de posición, tamaño, opacidad, always-on-top, interceptar cierre, o lectura de estado** → `window_manager` sigue siendo necesario.

### Inicialización (obligatoria)

```dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized(); // Siempre primer paso

  WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Para custom title bar
  );

  // Ocultar ventana hasta que Flutter esté listo (evita flash sin estilo)
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
```

### API Completa por Categorías

#### Posición y Tamaño
```dart
// Posición
await windowManager.getPosition(); // → Offset
await windowManager.setPosition(const Offset(100, 200), animate: true);
await windowManager.center(); // Centrar en pantalla activa
await windowManager.setAlignment(Alignment.center, animate: true);

// Tamaño
await windowManager.getSize(); // → Size
await windowManager.setSize(const Size(1280, 720), animate: true);
await windowManager.setMinimumSize(const Size(800, 600));
await windowManager.setMaximumSize(const Size(1920, 1080));
await windowManager.setAspectRatio(16 / 9);

// Bounds combinados
await windowManager.getBounds(); // → Rect
await windowManager.setBounds(const Rect.fromLTWH(100, 100, 800, 600));
```

#### Estado de Ventana
```dart
// Visibilidad
await windowManager.isVisible(); // → bool
await windowManager.show();
await windowManager.hide();

// Foco
await windowManager.isFocused(); // → bool (macOS, Windows)
await windowManager.focus();
await windowManager.blur(); // macOS, Windows

// Maximizar / Minimizar / Full Screen
await windowManager.isMaximized();         // → bool
await windowManager.maximize();
await windowManager.unmaximize();
await windowManager.isMinimized();         // → bool
await windowManager.minimize();
await windowManager.restore();
await windowManager.isFullScreen();        // → bool
await windowManager.setFullScreen(true);
```

#### Restricciones de Interacción del Usuario
```dart
await windowManager.isResizable();         // → bool
await windowManager.setResizable(false);   // Bloquear redimensionado
await windowManager.isMovable();           // → bool (macOS)
await windowManager.setMovable(false);     // Bloquear movimiento (macOS)
await windowManager.isMinimizable();       // → bool (macOS, Windows)
await windowManager.setMinimizable(false);
await windowManager.isMaximizable();       // → bool (macOS, Windows)
await windowManager.setMaximizable(false);
await windowManager.setClosable(false);    // Deshabilitar botón cerrar (macOS, Windows)
```

#### Apariencia
```dart
await windowManager.setTitle('Mi App');
await windowManager.getTitle();
await windowManager.setTitleBarStyle(
  TitleBarStyle.hidden,
  windowButtonVisibility: false, // Ocultar semáforo macOS
);
await windowManager.getTitleBarHeight();
await windowManager.setAsFrameless(); // Igual que TitleBarStyle.hidden
await windowManager.setBackgroundColor(Colors.transparent);
await windowManager.getOpacity();         // → double
await windowManager.setOpacity(0.95);
await windowManager.setBrightness(Brightness.dark);
await windowManager.hasShadow();          // → bool (macOS, Windows)
await windowManager.setHasShadow(false);  // macOS, Windows
```

#### Z-Order y Visibilidad en Sistema
```dart
await windowManager.isAlwaysOnTop();           // → bool
await windowManager.setAlwaysOnTop(true);      // Flotante sobre todo
await windowManager.isAlwaysOnBottom();         // → bool
await windowManager.setAlwaysOnBottom(true);    // Linux, Windows
await windowManager.isSkipTaskbar();            // → bool
await windowManager.setSkipTaskbar(true);       // Ocultar de taskbar/dock
await windowManager.setVisibleOnAllWorkspaces(  // macOS
  true,
  visibleOnFullScreen: true,
);
```

#### Taskbar / Dock Enhancements
```dart
await windowManager.setProgressBar(0.75);       // Barra de progreso en taskbar (macOS, Windows)
await windowManager.setBadgeLabel('99+');       // Badge en icono dock (macOS)
await windowManager.setIcon('assets/icon.ico'); // Cambiar ícono (Windows)
await windowManager.getId(); // Native window ID: HWND en Windows, window number en macOS
```

#### Cerrar e Interceptar Cierre
```dart
await windowManager.setPreventClose(true);  // Interceptar señal nativa de cierre
await windowManager.isPreventClose();       // → bool
await windowManager.close();               // Intentar cerrar (respeta setPreventClose)
await windowManager.destroy();             // Forzar cierre sin diálogo
```

#### Acciones Avanzadas
```dart
await windowManager.startDragging();             // Arrastrar desde widget custom
await windowManager.startResizing(ResizeEdge.bottomRight); // Linux, Windows
await windowManager.setIgnoreMouseEvents(true, forward: true); // Click-through
await windowManager.popUpWindowMenu();           // Menú contextual nativo de ventana

// Docking (solo Windows)
await windowManager.dock(side: DockSide.left, width: 400);
await windowManager.undock();
await windowManager.isDocked(); // → DockSide?

// Linux keyboard grab
await windowManager.grabKeyboard();
await windowManager.ungrabKeyboard();
```

### Escuchar Eventos con `WindowListener`

```dart
class MyPage extends StatefulWidget { ... }

class _MyPageState extends State<MyPage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // Todos los callbacks disponibles:
  @override void onWindowClose() {}
  @override void onWindowFocus() { setState(() {}); } // Importante: llamar setState
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
  @override void onWindowDocked() {}    // Windows
  @override void onWindowUndocked() {}  // Windows
  @override void onWindowEvent(String eventName) {} // Todos los eventos
}
```

### Patrón: Confirmar Antes de Cerrar

```dart
void _init() async {
  await windowManager.setPreventClose(true);
}

@override
void onWindowClose() async {
  if (await windowManager.isPreventClose()) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar la aplicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar')),
        ],
      ),
    );
    if (confirmed == true) await windowManager.destroy();
  }
}
```

---

## 7.15 Plugin `tray_manager` — System Tray Nativo (Necesario)

> **Corrección crítica:** Contrario a lo que podría inferirse, el **SDK 3.4x NO expone System Tray** a través de ninguna API Dart nativa (`dart:ui`, `SystemChannels`, ni `PlatformDispatcher`). `tray_manager` **sigue siendo imprescindible** para cualquier funcionalidad de bandeja del sistema.

> **⚠️ Migration Notice (2026):** `tray_manager` también se está migrando a [`nativeapi-flutter`](https://github.com/libnativeapi/nativeapi-flutter).

### Platform Support

| Feature | Linux | macOS | Windows |
|---|---|---|---|
| `setIcon` | ✅ | ✅ | ✅ |
| `setContextMenu` | ✅ | ✅ | ✅ |
| `destroy` | ✅ | ✅ | ✅ |
| `setToolTip` | ➖ | ✅ | ✅ |
| `popUpContextMenu` | ➖ | ✅ | ✅ |
| `getBounds` | ➖ | ✅ | ✅ |
| `setIconPosition` | ➖ | ✅ | ➖ |

### Instalación

```yaml
dependencies:
  tray_manager: ^0.5.2
```

**Linux — dependencia del sistema obligatoria:**
```bash
sudo apt-get install libayatana-appindicator3-dev
# o bien:
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

> **Linux/GNOME:** En entornos GNOME puede requerirse la extensión [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) para que el ícono aparezca en la bandeja.

### Uso Base — Ícono + Menú Contextual

```dart
import 'package:flutter/material.dart' hide MenuItem;
import 'package:tray_manager/tray_manager.dart';

Future<void> initTray() async {
  // El formato del ícono varía por plataforma
  await trayManager.setIcon(
    Platform.isWindows
        ? 'images/tray_icon.ico'  // Windows requiere .ico
        : 'images/tray_icon.png', // macOS y Linux usan .png
  );

  await trayManager.setToolTip('Mi Aplicación'); // macOS y Windows

  final menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: 'Mostrar ventana',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Salir',
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}
```

### Escuchar Eventos con `TrayListener`

```dart
class _MyState extends State<MyWidget> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    initTray();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    // Clic izquierdo en el ícono → mostrar/restaurar ventana
    trayManager.popUpContextMenu(); // o windowManager.show()
  }

  @override
  void onTrayIconRightMouseDown() {
    // Clic derecho → generalmente el SO ya muestra el menú
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
      case 'exit_app':
        windowManager.destroy();
    }
  }
}
```

### API Completa

```dart
// Ícono
await trayManager.setIcon('images/tray_icon.png');
await trayManager.setIconPosition(TrayIconPositionMode.auto); // macOS

// Tooltip (macOS, Windows)
await trayManager.setToolTip('Mi App v2.0');

// Menú
await trayManager.setContextMenu(menu);
await trayManager.popUpContextMenu(); // Mostrar menú programáticamente (macOS, Windows)

// Geometría
final Rect? bounds = await trayManager.getBounds(); // macOS, Windows

// Destruir ícono de bandeja
await trayManager.destroy();
```

### Patrón Completo: Minimize to Tray

Combinando `window_manager` + `tray_manager` para el patrón clásico de "minimizar a la bandeja":

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // No hay ensureInitialized() en trayManager
  runApp(const MyApp());
}

class _AppState extends State<MyApp> with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.setPreventClose(true); // Interceptar cierre
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
        Platform.isWindows ? 'images/app.ico' : 'images/app.png');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Mostrar'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Salir'),
    ]));
  }

  // Clic en ícono de bandeja → restaurar ventana
  @override
  void onTrayIconMouseDown() => windowManager.show();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    if (item.key == 'show') windowManager.show();
    if (item.key == 'quit') windowManager.destroy();
  }

  // Interceptar botón cerrar → minimizar a bandeja en lugar de cerrar
  @override
  void onWindowClose() async {
    await windowManager.hide(); // Ocultar ventana (no destruir)
    // El ícono de bandeja permanece activo
  }
}
```

### Known Issues

- **Transparencia en Linux:** Un ícono de tray (.png) que es completamente transparente o de 1x1 pixel no solo será invisible, sino **inclickable**, impidiendo que aparezca el menú.
- **Closures en menú (Linux):** NUNCA uses la propiedad `onClick: () {}` dentro de un `MenuItem` si apuntas a Linux/AppIndicator; la propagación C++ a Dart falla al usar cierres anónimos (bindings perdidos). Emplea SIEMPRE el método sobrescrito `onTrayMenuItemClick(MenuItem)` de la clase `TrayListener`.
- **`app_links` conflict:** Si usas `app_links`, debe ser `>= 6.3.3`. Versiones anteriores bloquean la propagación de eventos e impiden que se disparen los clicks del menú de bandeja.
- **GNOME (Linux):** El ícono puede no mostrarse sin la extensión [AppIndicator](https://extensions.gnome.org/extension/615/appindicator-support/).

### Patrón Real: Resolución de Ícono en Windows (Ruta Absoluta en Disco)

En Windows, `tray_manager` **no acepta rutas de assets de Flutter** (`'assets/icon.png'`). Requiere una **ruta absoluta del disco** apuntando al `.ico`. La ruta varía entre modo debug (`flutter run`) y release compilado. Este helper resuelve ambos casos:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

String resolveTrayIconPath() {
  if (Platform.isWindows) {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = [
      p.join(exeDir, 'resources', 'app_icon.ico'),                                    // Release
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'), // Debug
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),                 // Alternativo
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
  }
  return 'assets/tray_icon.png'; // macOS y Linux usan rutas de asset normal
}

// Uso en main():
await trayManager.setIcon(resolveTrayIconPath());
```

### Patrón Real: Diferencias de Eventos de Menú por Plataforma

En las versiones modernas, AppIndicator (Linux) y macOS procesan el menú contextual nativo. Llamar a rutinas adicionales manualmente causará conflictos.

```dart
  /// Windows puede requerir que forcemos el menú
  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows || Platform.isMacOS) {
      trayManager.popUpContextMenu();
    }
  }

  /// LINUX: NUNCA usar popUpContextMenu, el sistema lo despliega automáticamente de forma nativa.
  @override
  void onTrayIconRightMouseUp() {}
```

### Patrón Real: Restaurar Ventana desde Bandeja (Workaround Wayland)

En Linux con Wayland, `windowManager.show()` por sí solo puede fallar al traer la ventana al frente. Solución probada en producción:

```dart
@override
void onTrayIconMouseDown() async {
  if (!await windowManager.isFocused()) {
    if (await windowManager.isMinimized()) await windowManager.restore();
    if (Platform.isLinux) await windowManager.hide(); // Workaround Wayland: hide primero
    await windowManager.show();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await Future.delayed(const Duration(milliseconds: 300));
    await windowManager.setAlwaysOnTop(false); // Quitar always-on-top tras el foco
  }
}
```

---

## 7.16 Plugin `desktop_multi_window` — ✅ REQUERIDO en Stable 3.41

> **Estado real (stable 3.41):** `desktop_multi_window: ^0.3.0` es la solución **recomendada y funcional** para multi-ventana en Flutter desktop stable. La alternativa nativa del SDK existe pero está marcada `@internal` y solo se puede usar en el canal `main` con feature flag experimental.
>
> **Futuro (cuando salga de experimental):** `RegularWindowController` y sus hermanos del SDK nativo reemplazarán al plugin. Se podrá migrar cuando la Windowing API llegue a stable sin breaking changes.

### Guía de uso correcto (stable 3.41)

| Operación | `desktop_multi_window` (estable) |
|---|---|
| Abrir ventana | `WindowController.create(WindowConfiguration(...))` |
| Cerrar sub-ventana (desde adentro) | `(await WindowController.fromCurrentEngine()).hide()` |
| **⚠️ NUNCA usar para cerrar** | `SystemNavigator.pop()` — mata el proceso completo en desktop |
| Listar ventanas activas | `WindowController.getAll()` |
| Comunicar entre ventanas | `WindowMethodChannel('canal', mode: ChannelMode.unidirectional)` |
| Pasar datos al lanzar | `WindowConfiguration(arguments: jsonEncode({...}))` |
| Leer args en la sub-ventana | `WindowController.fromCurrentEngine().arguments` |

### Manejo del botón de cierre nativo ("X") en Sub-ventanas (Prevención de Crash)

Al abrir ventanas secundarias con `desktop_multi_window` y usar `window_manager` simultáneamente, existe un problema crítico (ej. bug `#40033` en Flutter Linux). Si el usuario cierra la sub-ventana pulsando el botón nativo ("X") del SO, el sistema operativo enviará una señal de destrucción global (`delete-event`) y matará toda la aplicación principal.

Para solucionarlo de forma segura, DEBES:
1. Validar que la sub-ventana tenga acceso a sus plugins mediante el registro nativo en C++/Swift (ver *Registro nativo requerido* un poco más abajo).
2. Interceptar físicamente la acción "X" desde el contexto de la nueva ventana en Dart.
   ```dart
   // Al inicializar la UI de la ventana secundaria:
   await windowManager.ensureInitialized();
   await windowManager.setPreventClose(true); // Obligatorio: previene que SO mate el thread
   ```
3. Utilizar un `WindowListener` (`window_manager`) para reaccionar a la intención de cierre, y simplemente invocar el método `hide()` del plugin `multi_window`:
   ```dart
   @override
   void onWindowClose() async {
     try {
       final controller = await WindowController.fromCurrentEngine();
       await controller.hide(); // Destruye visualmente el wrapper aislado
     } catch (_) {}
   }
   ```

### Registro nativo requerido (por plataforma)

Cada ventana nueva crea un motor Flutter independiente. Los plugins deben registrarse también en el nuevo motor mediante un callback nativo:

**Linux** (`linux/runner/my_application.cc`):
```cpp
#include "desktop_multi_window/desktop_multi_window_plugin.h"
desktop_multi_window_plugin_set_window_created_callback(
    [](FlPluginRegistry* registry) {
      fl_register_plugins(registry);
    });
```

**Windows** (`windows/runner/flutter_window.cpp`):
```cpp
#include "desktop_multi_window/desktop_multi_window_plugin.h"
DesktopMultiWindowSetWindowCreatedCallback([](void* controller) {
  auto* fvc = reinterpret_cast<flutter::FlutterViewController*>(controller);
  RegisterPlugins(fvc->engine());
});
```

**macOS** (`macos/Runner/MainFlutterWindow.swift`):
```swift
import desktop_multi_window
FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
  RegisterGeneratedPlugins(registry: controller)
}
```

---

## 7.17 `MenuBar` Nativo + Atajos de Teclado (SDK — Sin Plugin)

Flutter Desktop incluye nativamente `MenuBar`, `MenuItemButton`, `SubmenuButton` y `MenuAcceleratorLabel`. **No se requiere ningún plugin.** El patrón correcto combina `CallbackShortcuts` + `Focus` envolviendo todo el `Scaffold.body`.

**Regla crítica:** El `shortcut` en la propiedad de `MenuItemButton` solo activa el atajo si el usuario **tiene el menú abierto**. `CallbackShortcuts` + `Focus(autofocus: true)` son **obligatorios** para que los atajos funcionen desde cualquier parte de la app.

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
        autofocus: true, // Sin esto, los shortcuts no se capturan al inicio
        child: Column(
          children: [
            MenuBar(
              children: [
                SubmenuButton(
                  // '&' antes de la letra define el acelerador (Alt+F abre este menú)
                  child: const MenuAcceleratorLabel('&File'),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add, size: 16),
                      onPressed: _openNewDialog,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                      // '\t' genera el espaciado visual nativo del atajo a la derecha
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
                SubmenuButton(
                  child: const MenuAcceleratorLabel('&View'),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => setState(() => _view = ViewState.users),
                      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
                      child: const MenuAcceleratorLabel('&Users\tCtrl+1'),
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

**Conceptos clave:**
- **`MenuAcceleratorLabel('&File')`:** El `&` convierte la letra siguiente en acelerador `Alt+F`. Funciona dentro del menú abierto con Alt.
- **`'\tCtrl+N'`:** El `\t` produce el espaciado visual nativo entre el label y el atajo a la derecha.
- **`CallbackShortcuts` + `Focus(autofocus: true)`:** Obligatorio para atajos globales sin que el usuario abra el menú.
- **`RawMenuAnchor`:** Para menús completamente personalizados sin estilo por defecto (Flutter 3.32+).

---

## 7.18 Plugin `local_notifier` — Notificaciones del Sistema Desktop

Para despachar notificaciones de escritorio nativas (Centro de Notificaciones de Windows, macOS y libnotify en Linux).

```yaml
dependencies:
  local_notifier: ^0.1.5
```

```dart
import 'package:local_notifier/local_notifier.dart';

// En main() — obligatorio antes de mostrar notificaciones
await localNotifier.setup(appName: 'My App');

// Notificación simple
final notification = LocalNotification(
  title: 'My App',
  body: 'Operación completada.',
);
await notification.show();

// Con botones de acción
final actionNotif = LocalNotification(
  title: 'New Message',
  body: 'Tienes un nuevo mensaje.',
  actions: [
    LocalNotificationAction(type: 'button', text: 'Open'),
    LocalNotificationAction(type: 'button', text: 'Dismiss'),
  ],
);
actionNotif.onClickAction = (actionIndex) {
  if (actionIndex == 0) windowManager.show();
};
await actionNotif.show();
```

---

## 7.19 Base de Datos Desktop: `sqflite_common_ffi` + `path_provider`

En Flutter Desktop **no se puede usar `sqflite` directamente** (está enlazado a wrappers Java/ObjC de mobile). Se usa `sqflite_common_ffi` que enlaza SQLite mediante FFI a bibliotecas C nativas del sistema.

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
    // Paso CRÍTICO: inicializar FFI antes de cualquier operación de base de datos
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }
}
```

**Directorios disponibles con `path_provider` en Desktop:**

| Método | Windows | macOS | Linux |
|---|---|---|---|
| `getApplicationDocumentsDirectory()` | `Documents\AppName` | `~/Documents` | `~/Documents` |
| `getApplicationSupportDirectory()` | `AppData\Roaming\AppName` | `~/Library/Application Support/AppName` | `~/.local/share/AppName` |
| `getTemporaryDirectory()` | `%TEMP%` | `/tmp` | `/tmp` |
| `getDownloadsDirectory()` | `Downloads` | `~/Downloads` | `~/Downloads` |

---

## 7.20 Estado Global y Temas Dinámicos: `flutter_riverpod` + `shared_preferences`

Patrón para gestionar tema (Claro/Oscuro/Sistema) y color de acento con persistencia entre sesiones:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.3.3
```

```dart
class ThemeSettings {
  final ThemeMode mode;
  final Color accentColor;
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.accentColor = const Color(0xFF1565C0),
  });
  ThemeSettings copyWith({ThemeMode? mode, Color? accentColor}) => ThemeSettings(
    mode: mode ?? this.mode,
    accentColor: accentColor ?? this.accentColor,
  );
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    _load();
    return const ThemeSettings();
  }

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

// Consumo en MaterialApp:
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
```

---

## 7.21 Generación de PDF e Impresión Nativa: `pdf` + `printing`

Dos plugins complementarios del mismo autor (DavBfr):
- **`pdf`** — Construye documentos PDF usando una API de widgets *idéntica* a Flutter (`pw.Column`, `pw.Text`, `pw.Table`, etc.) pero que renderiza en vectores PDF, no en pantalla.
- **`printing`** — Puente hacia los spoolers de impresoras nativos de Windows, macOS y Linux. También permite guardar el PDF como archivo, previsualizar antes de imprimir, y compartir.

```yaml
dependencies:
  pdf: ^3.11.1
  printing: ^5.13.2
```

### Generar un documento PDF

Todos los widgets de `pdf` usan el prefijo `pw` para distinguirlos de los widgets de Flutter:

```dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintService {
  /// Genera los bytes del PDF. Se puede pasar a `Printing.layoutPdf` o guardar
  /// en disco con `File.writeAsBytes()`.
  static Future<Uint8List> generatePdf(List<Map<String, dynamic>> rows) async {
    final pdf = pw.Document(
      title: 'Reporte',
      creator: 'My App',
    );

    // pw.MultiPage maneja la paginación automáticamente
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte de Usuarios',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headers: ['ID', 'Nombre', 'F. Nacimiento', 'Teléfono'],
            data: rows.map((r) => [
              r['id'].toString(),
              r['name'],
              r['dob'],
              r['phone'],
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
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );

    return pdf.save(); // Devuelve Uint8List con los bytes del PDF
  }
}
```

### Imprimir / Previsualizar / Guardar en disco

```dart
import 'package:printing/printing.dart';

// Abrir diálogo nativo de impresora del SO
await Printing.layoutPdf(
  onLayout: (format) => PrintService.generatePdf(rows),
);

// Previsualizar antes de imprimir (abre una ventana de previsualización)
await Printing.layoutPdf(
  onLayout: (format) => PrintService.generatePdf(rows),
  name: 'Reporte de Usuarios',
);

// Guardar PDF en disco directamente (sin diálogo de impresora)
final bytes = await PrintService.generatePdf(rows);
final outputFile = File(p.join((await getDownloadsDirectory())!.path, 'reporte.pdf'));
await outputFile.writeAsBytes(bytes);

// Compartir / abrir con visor externo
await Printing.sharePdf(
  bytes: bytes,
  filename: 'reporte.pdf',
);
```

### API clave de `pw` (widgets análogos a Flutter)

| Widget `pw` | Equivalente Flutter | Notas |
|---|---|---|
| `pw.Document()` | — | Contenedor raíz del PDF |
| `pw.Page` / `pw.MultiPage` | — | `MultiPage` pagina automáticamente |
| `pw.Text(s, style: pw.TextStyle(...))` | `Text` | No acepta `TextStyle` de Flutter |
| `pw.Column` / `pw.Row` / `pw.Stack` | Equivalentes exactos | Mismo modelo de layout |
| `pw.Container` / `pw.SizedBox` | Equivalentes exactos | — |
| `pw.Image(MemoryImage(bytes))` | `Image.memory` | Requiere `Uint8List` |
| `pw.Table.fromTextArray(...)` | `DataTable` | Genera tablas con cabeceras y celdas |
| `pw.Header` | — | Cabecera estilizada de sección |
| `pw.Divider` | `Divider` | — |
| `PdfColors.blue800` | `Colors.blue[800]` | Paleta de colores del PDF |
| `PdfPageFormat.a4` | — | Tamaño de página (también `letter`, `legal`, etc.) |

### Cargar fuentes personalizadas

```dart
final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
final ttf = pw.Font.ttf(fontData);

pdf.addPage(pw.Page(
  build: (ctx) => pw.Text('Hola', style: pw.TextStyle(font: ttf)),
));
```

---

**Final Directive:** If the code you generate misses opportunities to use `CarouselView.builder`, `popUntilWithResult`, `CupertinoSheet` drag handles, `RepeatingAnimationBuilder`, uses `SizedBox` for spacing, or prefixes an Enum unnecessarily, you have failed the 3.41 standard. For desktop apps on **Flutter stable 3.41**: generating code that calls `PlatformDispatcher.instance.requestView()` or `PlatformDispatcher.instance.closeView()` (these methods do not exist in the public stable API), using `SystemNavigator.pop()` to close a sub-window (it kills the entire process), omitting the native plugin registration callback for multi-window engines, assuming that multi-window uses a single Isolate in stable (it does not — each window is a separate engine requiring `WindowMethodChannel` for sync), assuming a single `devicePixelRatio` for multi-monitor setups, omitting `sqfliteFfiInit()` in desktop database apps, placing shortcuts only in `MenuItemButton.shortcut` without `CallbackShortcuts`, or skipping `resolveTrayIconPath()` for Windows tray icons also constitutes a failure of the 3.41 standard. For multi-window in stable, use `desktop_multi_window: ^0.3.0`. The native Windowing API (`RegularWindowController`, etc.) is experimental and only available on the `main` channel. Write perfect modern Dart natively tailored to the platform.
