---
name: flutter_expert
description: The definitive Flutter & Dart technical guide. Enforces strict compliance with Flutter 3.41, Impeller optimizations, exhaustive Cupertino parity, iOS/Android platform interop paradigms, WebAssembly targets, and modern Dart 3.10+ syntax. Features exhaustive knowledge from versions 3.27 through 3.41.
---

# 🚀 Flutter Master Engineer Guidelines (v3.41 Standard)

You are an elite, senior-level Flutter and Dart engineer. Your primary mandate is to generate, architect, review, and refactor code strictly according to **Flutter 3.41** and **Dart 3.x** standards.

You must abandon outdated practices, aggressively adopt highly optimized modern syntax, and design software taking full advantage of the underlying engine improvements (Impeller) and the absolute latest framework widgets introduced from version 3.27 up to 3.41.

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
*   **Desktop Native Multi-Window (3.41):** Flutter officially supports multi-window popups, dialogs, and tooltips on Windows, macOS, and Linux natively. Do not use legacy community plugins for secondary window generation.
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
*   **[web_widgets.md](templates/web_widgets.md)** — Web (CanvasKit/WASM) rendering and widgets: HTML renderer removal, WASM dry-run validation, `WebParagraph` enhancements, native `<img>` offloading, stateful web hot reload, `dart:js_interop` migration, `OverlayPortal` improvements, and platform-specific asset bundling.

**You MUST consult these catalogs** when building for a specific platform to ensure you are using the exact latest API and not legacy patterns.

---

## 7. Desktop Multi-Window & Native Platform APIs (SDK 3.4x — Guía Maestra)

Esta sección contiene la referencia técnica exhaustiva para el desarrollo de aplicaciones de escritorio de alto rendimiento en Flutter, cubriendo la arquitectura Multi-View nativa, APIs de integración con el sistema operativo y personalización avanzada de ventanas.

### 7.1 Arquitectura Multi-View Nativa con `PlatformDispatcher`

A diferencia de los plugins heredados, el soporte nativo utiliza un **Single Isolate**. Esto significa que todas las ventanas comparten la misma instancia de la aplicación en memoria, sin serialización JSON ni canales de mensajes entre ventanas.

*   **Regla Imperativa:** Nunca usar plugins como `multi_window_manager` o `bitsdojo_window` para operaciones básicas de apertura/cierre de ventanas. El SDK 3.4x lo gestiona nativamentea través de `PlatformDispatcher`.

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

// Abrir una nueva ventana nativa
void abrirVentana() {
  PlatformDispatcher.instance.requestView();
}

// Cerrar una ventana específica por su viewId
void cerrarVentana(int viewId) {
  if (viewId != 0) { // Nunca cerrar la ventana principal (id: 0)
    PlatformDispatcher.instance.closeView(viewId);
  }
}
```

### 7.2 Widget Tree Multi-Window: Enrutamiento por `viewId`

Para que cada ventana muestre contenido distinto, utiliza `View.of(context).viewId` como discriminador en el `MaterialApp`. Este es el patrón canónico en 3.4x:

```dart
class MultiWindowRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final viewId = View.of(context).viewId;

        return switch (viewId) {
          0 => const MainWindow(),
          1 => const ToolPanelWindow(),
          2 => const PreviewWindow(),
          _ => const GenericSecondaryWindow(),
        };
      },
    );
  }
}
```

### 7.3 APIs de Ventana Avanzadas (Sin Plugins Externos)

#### Título dinámico por ventana
```dart
import 'package:flutter/services.dart';

void updateWindowTitle(BuildContext context, String title) {
  final viewId = View.of(context).viewId;
  SystemChannels.window.invokeMethod('setWindowTitle', {
    'id': viewId,
    'title': title,
  });
}
```

#### Drag and Drop nativo inter-ventana
El motor gráfico unificado permite arrastrar datos entre ventanas de la misma app con `Draggable`/`DragTarget` sin bridges adicionales:
```dart
Draggable(
  data: myData,
  feedback: Material(child: Text("Arrastrando...")),
  child: MyWidget(),
);

// En la ventana destino
DragTarget<MyData>(
  onAccept: (data) => procesarDataCompartida(data),
);
```

### 7.4 Estado Global Sin Sincronización (Single Isolate)

Al ser un único proceso de Dart, cualquier gestor de estado (Riverpod, Bloc, Signals) funciona **out of the box** a través de todas las ventanas:

*   **Consistencia inmediata:** Si un WebSocket recibe datos en la Ventana A, el widget de la Ventana B se actualiza al instante porque escucha el mismo `Stream`.
*   **Sin latencia:** No hay serialización JSON entre ventanas. Es paso de memoria directo (paso por referencia).
*   **Hot Reload unificado:** Un solo clic recarga todas las ventanas abiertas simultáneamente.

### 7.5 Tabla Comparativa de Rendimiento: Plugins vs SDK Nativo

| Métrica | Plugins Antiguos | Nativo SDK 3.4x |
|---|---|---|
| **Tiempo de apertura** | ~1.5 segundos | ~100 milisegundos |
| **Uso de CPU (Idle)** | 2-5% por ventana | < 0.5% global |
| **Comunicación entre ventanas** | Asíncrona (Method Channels) | Sincrónica (Memoria Directa) |
| **Hot Reload** | Manual por motor | Unificado (Un solo clic) |

### 7.6 APIs de Sistema y Hardware Integradas

El SDK 3.4x incluye soporte nativo para las siguientes integraciones de escritorio sin plugins externos:

1.  **Menús del Sistema (`PlatformMenuBar`):** Menús nativos en la barra de tareas de macOS y Windows. No usar `menubar` ni paquetes basados en overlays flotantes.
2.  **Atajos de Teclado:** `Shortcuts` y `Actions` que se propagan correctamente según qué ventana tenga el foco activo del sistema operativo.
3.  **Bandeja del Sistema (System Tray):** API nativa para minimizar la app al área de notificación sin plugins externos.

### 7.7 Íconos Independientes por Ventana (Multi-Icon Support)

Al igual que `JFrame.setIconImage()` en Java/Swing, Flutter 3.4x permite asignar un ícono distinto a cada ventana en tiempo de ejecución pasando el `viewId`.

**Contexto histórico crítico:** Antes de SDK 3.4x, el ícono de la aplicación Flutter se definía exclusivamente en tiempo de compilación, dentro de los archivos `.ico` (Windows) o `.icns` (macOS). Cambiar el ícono de una ventana individual en tiempo de ejecución era imposible sin hacks de plataforma. Con el soporte de `viewId`, el control es total y completamente dinámico.

```dart
import 'package:flutter/services.dart';

Future<void> setWindowIcon(int viewId, String assetPath) async {
  await SystemChannels.window.invokeMethod('setWindowIcon', {
    'id': viewId,
    'asset': assetPath,
  });
}

// Caso de uso: Abrir una ventana de alerta con su propio ícono
void abrirAlerta() async {
  final viewId = await PlatformDispatcher.instance.requestView();
  await setWindowIcon(viewId, 'assets/icons/warning_icon.png');
}
```

| Característica | Java (JFrame) | Flutter 3.4x |
|---|---|---|
| **Método** | `frame.setIconImage()` | `SystemChannels.window` |
| **Formato** | Image Object | Assets / ByteData |
| **Independencia por ventana** | Total | Total (via `viewId`) |
| **Dinámico en runtime** | Sí | Sí |

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
                  onPressed: () {
                    if (viewId == 0) {
                      SystemNavigator.pop();
                    } else {
                      PlatformDispatcher.instance.closeView(viewId);
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

#### `dart:ui` Layer
*   **`PlatformDispatcher`** — Punto central de control del motor. Métodos clave: `requestView()`, `closeView(int viewId)`, `views` (iterable de todas las vistas abiertas).
*   **`FlutterView`** — Representa una ventana/superficie nativa individual. Expone `viewId`, `physicalSize`, `devicePixelRatio`, y métricas del display donde reside.
*   **`Display`** — Representa un monitor físico del sistema. Permite consultar resolución, `devicePixelRatio` y si hay un monitor conectado antes de crear una vista. Útil para posicionar ventanas hijas en el monitor correcto en setups multi-monitor.

#### Widget Layer
*   **`View`** — Widget que representa la raíz de un `FlutterView` en el árbol de widgets. `View.of(context)` obtiene el `FlutterView` más cercano en el contexto.
*   **`ViewAnchor`** — Widget que permite anclar una vista secundaria (`FlutterView`) a una posición concreta dentro del árbol de widgets de la vista padre. Útil para crear ventanas hijas que se posicionan relativamente al widget que las invoca (ej. tooltips de ventana completa, popups de panel de herramientas anclados a un botón). Es la diferencia entre "abrir una ventana independiente" y "anclar una vista en un punto del layout".

#### Channel Layer
*   **`SystemChannels.window`** — Métodos disponibles vía `invokeMethod`: `setWindowTitle`, `setWindowIcon`, `minimize`, `maximize`, `startDragging`, `closeView`.

#### Official References
*   [flutter.dev/desktop](https://flutter.dev/desktop)
*   [Flutter Desktop Multi-Window Design Doc](https://flutter.dev/go/desktop-multi-window-support)

---

**Final Directive:** If the code you generate misses opportunities to use `CarouselView.builder`, `popUntilWithResult`, `CupertinoSheet` drag handles, `RepeatingAnimationBuilder`, uses `SizedBox` for spacing, or prefixes an Enum unnecessarily, you have failed the 3.41 standard. For desktop apps, failing to use `PlatformDispatcher` for multi-window, using old community window plugins, or assuming a single `devicePixelRatio` for multi-monitor setups also constitutes a failure of the 3.41 standard. Write perfect modern Dart natively tailored to the platform.
