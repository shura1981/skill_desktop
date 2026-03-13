# 🌐 Web Platform — Widget & API Updates (Flutter 3.27 → 3.41)

This document catalogs **every** new widget, updated widget, rendering change, and API update relevant to **Flutter for Web** (CanvasKit / WebAssembly) introduced from Flutter 3.27 through 3.41.

---

## Web Rendering Engine Evolution

### HTML Renderer Removal (3.29)
- The HTML renderer has been **officially removed** from Flutter. All web rendering now uses **CanvasKit** (backed by WebAssembly).
- This means all Flutter web apps are GPU-accelerated by default.
- Apps previously using `--web-renderer html` must migrate.

### WebAssembly (WASM) Improvements
- **3.27**: All Flutter team plugins and packages are now **WebAssembly compatible**.
- **3.29**: WASM support improved with enhanced rendering speed and responsiveness for graphics-intensive web applications.
- **3.35**: `dart:js_interop` is the required interop mechanism. `dart:js` is deprecated. The runtime now does a WASM dry-run even when compiling to JS to ensure strict compatibility.
- **3.41**: Static images are **offloaded to native `<img>` elements** to save WASM decoder memory and improve performance.

### CanvasKit Refinements
- Continued rendering improvements across 3.29 → 3.41 for smoother animations, sharper text, and improved frame rates on web.

---

## Web-Specific Widget & API Updates

### WebParagraph (3.41)
- **Major enhancement.** `WebParagraph` now supports:
  - Full text placeholder support
  - Deep text decorations (underline, overline, line-through with custom colors)
  - More text styling options that previously didn't exist in the WASM target
  - Improved web text rendering parity with native platforms

### SelectableRegion — Web Context Menu (3.41)
- `SelectableRegion` no longer shows the Flutter-rendered context menu when the **web browser's native context menu is enabled**. Prevents duplicate menu display.

### Image Handling — Web (3.29 / 3.41)
- **3.29**: Enhanced web image handling with more developer control over how images are displayed. CORS-related issues addressed.
- **3.41**: **Static images offloaded to native `<img>` elements.** This:
  - Reduces WASM decoder memory usage
  - Allows browser-native image caching
  - Improves initial page load performance

### Image.network Cache Fix (3.41)
- `Image.network` now correctly uses the browser cache **even when custom headers are specified**.

### Text Input — System Context Menu on Web (3.32)
- The system text selection context menu is now properly surfaced on web, providing native copy/paste/select-all behavior.

### Autocomplete — OverlayPortal Migration (3.32)
- `Autocomplete` widget's options have been ported to `OverlayPortal` on web, improving performance and fixing z-index and clipping bugs.

### Selectable Text — Web Performance (3.32)
- Selectable text has received **bug fixes and performance improvements** specifically targeting web rendering.

---

## Web Development Workflow

### Hot Reload for Web — Stateful (3.32 / 3.35 / 3.38)
- **3.32**: Experimental hot reload for web introduced (`flutter run --web-experimental-hot-reload`).
- **3.35**: **Stateful hot reload enabled by default** for web applications. State is preserved across hot reloads during development.
- **3.38**: Multi-browser hot reload support. New `web_dev_config.yaml` file for consistent web server configuration. Proxy forwarding support added.

### Platform-Specific Asset Bundling (3.41)
- Developers can now specify assets **per platform** in `pubspec.yaml`. This prevents unnecessary mobile/desktop assets from being bundled in the web build, reducing download size.

### `dart:js_interop` Migration (3.35 → 3.41)
- **Mandatory**: `dart:js` is deprecated and will be removed. All JavaScript interop must use `dart:js_interop`.
- The compiler now performs a **WASM dry-run** even for JS targets to validate strict memory compatibility.

---

## Web-Relevant Cross-Platform Widgets

### CarouselView.builder (3.41)
- Memory-efficient carousel for large/infinite data sets. Critical for web where memory footprint matters for WASM performance.

### RepeatingAnimationBuilder (3.41)
- Eliminates `AnimationController` boilerplate for looping animations. Reduces both code size and cognitive overhead on web where bytecode size matters.

### RawAutocomplete — `mostSpace` (3.41)
- `OptionsViewOpenDirection.mostSpace` auto-positions autocomplete dropdowns based on available viewport space — critical for web layouts where viewport dimensions vary wildly.

### Badge.count — `maxCount` (3.38)
- Natively cap notification numbers without custom logic.

### OverlayPortal Improvements (3.38)
- `OverlayPortal.overlayChildLayoutBuilder` provides precise control over floating UI elements — particularly important for web modals and dropdowns that need correct stacking context.

### Tooltip — Manual Positioning (3.41)
- Manual tooltip placement API — important for web apps with fluid/responsive layouts where default positions may clip.

### Saturation ColorFilter (3.41)
- Built-in saturation filter via `ColorFilter.matrix` — avoids shipping custom shader code to the web build.

### Navigator.popUntilWithResult (3.41)
- Pop multiple routes with a result value — common pattern in web SPA navigation flows.

### Expansible & ExpansibleController (3.32)
- Flexible expandable/collapsible panels for web dashboard UIs and settings pages.

### RawMenuAnchor (3.32)
- Unstyled menu anchor for custom web dropdown menus and command palettes.

### NavigationRail — Scrollable (3.35)
- Scrollable `NavigationRail` for web apps with extensive navigation structures.

### NavigationDrawer — Headers/Footers (3.35)
- Headers and footers in `NavigationDrawer` for richer web app sidebars.

### DropdownMenuFormField (3.35 / 3.41)
- Material 3 dropdown integrated with `Form` — useful for web forms.
- 3.41 adds custom error builder.

### Widget Previews — `@Preview()` (3.38 / 3.41)
- IDE widget previewer with embedded Flutter Inspector. Speeds up web UI iteration.

---

## Web Accessibility

### Semantics Tree — 80% Faster (3.32)
- Screen reader performance dramatically improved on web.

### SemanticsRole API (3.32 / 3.35)
- Specify semantic roles at widget subtree level for better web accessibility.

### Segmented Control Radio Role (3.41)
- Segmented controls now announce `radioGroup` role to web screen readers.

### SliverEnsureSemantics (3.35)
- Guarantees proper indexing of off-screen sliver items for web screen readers.

### Form Announcements (3.29)
- `Form` announces only the first error to screen readers — prevents overwhelming audio output on web forms.

---

## Web-Relevant Dart & Syntax Changes

### Dart 3.10 Dot Shorthands (3.38)
- `MainAxisAlignment.center` → `.center`. Reduces generated code size in web builds.

### Dart 3.8 Null-Aware Elements (3.32)
- Cleaner collection construction reduces boilerplate in web app code.

### spacing Parameter (3.27)
- `Row`, `Column`, `Flex` support `spacing` property — removes `SizedBox` spacers.

### Records & Pattern Matching (Dart 3.x)
- Use Records for multi-value returns. Use exhaustive `switch` expressions. Web-compiled code benefits from smaller output.

---

## Web Compiler & Build Changes

### Dart2JS & Dart2Wasm (3.29 → 3.41)
- Both compilers receive continuous optimizations for reduced output size and faster execution.
- WASM dry-run validation ensures all code paths are WASM-compatible even when targeting JS.

### Gradle 9 Compatibility (3.41)
- Gradle 9 deprecations resolved in the Flutter tool — though Gradle primarily affects Android, web build tooling also benefits from the unified `flutter build` pipeline improvements.

---

## Breaking Changes & Deprecations (Web)

| Version | Change | Migration |
|---------|--------|-----------|
| 3.27 | `AssetManifest.json` discontinued | Use binary asset manifest |
| 3.27 | All Flutter team packages WASM-compatible | Migrate JS interop to `dart:js_interop` |
| 3.29 | HTML renderer removed | Use CanvasKit/WASM (default) |
| 3.32 | `SystemContextMenuController.show` deprecated | Use newer menu APIs |
| 3.35 | `dart:js` deprecated | Use `dart:js_interop` |
| 3.35 | Observatory support removed | Use Dart DevTools |
| 3.38 | `OverlayPortal.targetsRootOverlay` deprecated | Use `OverlayPortalController` |
| 3.38 | `AssetManifest.json` fully removed | Binary-only manifest |
| 3.41 | Material & Cupertino decoupling begins | Libraries moving to standalone packages |
