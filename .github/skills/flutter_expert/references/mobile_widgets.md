# 📱 Mobile Platform — Widget & API Updates (Flutter 3.27 → 3.41)

This document catalogs **every** new widget, updated widget, new property, and API change relevant to **iOS (Cupertino)** and **Android (Material)** mobile targets introduced from Flutter 3.27 through 3.41.

---

## Cupertino (iOS) Widgets

### CupertinoButton (3.27)
- **New `CupertinoButtonSize` enum**: Provides iOS 15+ button sizing presets (small, medium, large).
- **New `CupertinoButton.tinted` constructor**: Creates buttons with translucent, tinted backgrounds matching the iOS system style.
- **`onLongPress` handler**: Added for long-press gesture detection on Cupertino buttons.
- **Keyboard shortcut support**: Cupertino buttons can now be triggered by physical keyboard shortcuts.

### CupertinoCheckbox (3.27)
- **High-fidelity visual updates**: Improved size, color, stroke width, and press interaction animations.
- **New properties**: `mouseCursor`, `semanticLabel`, `fillColor`.
- **Deprecated**: `inactiveColor` (was previously unusable, now formally deprecated).

### CupertinoRadio (3.27 / 3.35)
- **3.27**: High-fidelity visual updates matching iOS native radio buttons. New properties: `mouseCursor`, `semanticLabel`, `thumbImage`, `fillColor`.
- **3.35**: Complete redesign to boost accessibility. VoiceOver and dynamic type integration improved.

### CupertinoSwitch (3.27)
- **Enhanced customization**: Support for mouse cursors, semantic labels, thumb images, and fill colors added to match Material counterpart parity.

### CupertinoSlidingSegmentedControl (3.27 / 3.38)
- **3.27**: Enhanced thumb radius, padding, separator height, shadows, and scale alignment. Added support for **disabling individual segments** and **proportional layouts** based on segment content widths.
- **3.38**: Added **Momentary mode** — a variant where segments act as discrete triggers rather than persistent selection indicators. Used when no segment should "stick" selected.

### CupertinoNavigationBar (3.27 / 3.29)
- **3.27**: Background remains **fully transparent** until content scrolls beneath the bar. Smooth state transitions between expanded (matching background) and collapsed (customizable color) states.
- **3.29**: Added support for a **`bottom` widget** (e.g., a search field or segmented control beneath the title area).
- **3.29**: New `CupertinoNavigationBar.large` constructor for a static, persistent large title.

### CupertinoSliverNavigationBar (3.27 / 3.29 / 3.35)
- **3.27**: Same transparent background behavior as `CupertinoNavigationBar`. Background box is removed when the large title is extended.
- **3.29**: Added **`bottom` widget** with a `bottomMode` property to configure whether it resizes or persists during scrolling. Added **snapping behavior** between expanded and collapsed states when partially scrolled.
- **3.35**: Correctly respects **accessible text scaling**. Improved VoiceOver tab activation. Back label avoids clipping during transitions.

### CupertinoPicker & CupertinoDatePicker (3.27 / 3.35)
- **3.27**: Both pickers now **scroll to tapped items** instead of requiring manual drag.
- **3.35**: **Haptic feedback** integrated into `CupertinoPicker` interactions.

### CupertinoTimerPicker (3.35)
- Updated with new visual refinements and consistent behavior with `CupertinoDatePicker`.

### CupertinoSlider (3.35)
- **Haptic feedback** integrated during thumb drag interactions, providing native-feel tactile response.

### CupertinoAlertDialog (3.27 / 3.29 / 3.32)
- **3.27**: Now supports **tap-slide gesture** (iOS style of sliding finger across buttons).
- **3.29**: Visual update in **dark mode** to more closely match native iOS appearance.
- **3.32**: Updated to use the new `RSuperellipse` (squircle) shape.

### CupertinoActionSheet (3.27 / 3.32)
- **3.27**: High-fidelity updates including adjusted padding, adaptive font sizes across system text size settings, and **haptic feedback** when sliding over buttons.
- **3.32**: Updated to use `RSuperellipse` shape.

### CupertinoContextMenu (3.27)
- Now supports **scrolling for overflowing actions** instead of clipping them.

### CupertinoSheet / CupertinoSheetRoute (3.29 / 3.32 / 3.38 / 3.41)
- **3.29**: The `showCupertinoSheet` function is now **stable**. Features built-in drag-to-dismiss and nested navigation.
- **3.32**: Added `enableDrag` argument to `CupertinoSheetRoute` and `showCupertinoSheet` to disable drag-down-to-dismiss behavior. `MediaQuery` values added.
- **3.38**: Refreshed with a **stretch effect** that mimics native iOS rubber-banding behavior.
- **3.41**: Native-styled **`showDragHandle`** property for displaying iOS 18-style drag indicators.

### CupertinoExpansionTile (3.35)
- **New widget.** Creates expandable and collapsible list items in iOS Cupertino style.

### CupertinoListTile (3.35)
- Received visual improvements and refinements for better native iOS fidelity.

### CupertinoDynamicColor (3.38 — Deprecation)
- **Deprecated**: `red`, `green`, `blue` integer properties and `.withOpacity()` method.
- **Replacement**: Use float-based `r`, `g`, `b`, `a` properties and `.withValues(alpha:)` method.
- **Reason**: Transition to P3 wide-gamut color space support on modern iOS displays.

### CupertinoDesktopTextSelectionToolbar (3.41)
- Fix to prevent crash in certain configurations when accessing the toolbar on macOS/iPad.

### Cupertino Popups (3.29)
- Popup backgrounds now have **more vibrant background blurs**, enhancing native fidelity.

### iOS Text Selection (3.29)
- Selection handles on iOS now **swap their order when inverted**.
- Text selection magnifier border color **matches the current theme**.

### Squircles — `RSuperellipse` APIs (3.32 / 3.35)
- **3.32**: New rendering primitives — `RoundedSuperellipseBorder`, `ClipRSuperellipse`, `Canvas.drawRSuperellipse`, `Canvas.clipRSuperellipse`, `Path.addRSuperellipse`.
- **3.35**: All Cupertino widgets now internally use `RSuperellipse` shape to match Apple's native continuous-corner aesthetic.

---

## Material (Android + Cross-Platform) Widgets

### Row & Column `spacing` Parameter (3.27)
- **New `spacing` parameter** on `Row`, `Column`, and `Flex` widgets. Allows specifying pixel distance between children directly, eliminating the need for `SizedBox` or `Padding`.

### CarouselView (3.27 / 3.32 / 3.35 / 3.41)
- **3.27**: `CarouselView.weighted` constructor added, using `flexWeights` parameter for dynamic item sizing.
- **3.32**: `CarouselController` gains `animateToIndex` method for programmatic carousel page changes.
- **3.35**: Introduced as a stable Material widget for horizontal carousel layouts.
- **3.41**: `CarouselView.builder` constructor for memory-efficient, lazily-built carousels with large/infinite data sets.

### SliverFloatingHeader (3.27)
- **New widget.** A sliver header that appears on forward scroll and gracefully disappears on backward scroll.

### PinnedHeaderSliver (3.27)
- **New widget.** A sliver header that remains pinned at the top during scrolling, replacing complex `SliverPersistentHeader` delegate patterns.

### SegmentedButton (3.27)
- Can now be aligned **vertically** in addition to the default horizontal layout.

### TabBar (3.27 / 3.32)
- **3.27**: New `TabBar.indicatorAnimation` property for customizing the tab indicator's transition animation.
- **3.32**: Added `onHover` and `onFocusChange` callbacks. `animationStyle` configuration support added.

### SelectionArea (3.27)
- Now supports **Shift + Click** gesture for extending text selections on Linux, macOS, and Windows.
- New `clearSelection` method to programmatically remove active text selections.

### Card (3.27)
- `CardThemeData` normalized for consistent card theming across the application.

### Dialog (3.27 / 3.32)
- **3.27**: `DialogThemeData` introduced for streamlined dialog theming.
- **3.32**: `animationStyle` added to `showDialog` for customizable dialog entrance/exit animations.

### Stepper (3.27)
- Added ability to **clip step content** to prevent overflow.

### SearchBar (3.27)
- New `scrollPadding` property.

### ListTile (3.27)
- Added button semantics. New `ListTileControlAffinity` can be set globally in `ListTileTheme`.

### InputDecoration (3.27 — Deprecation / 3.35)
- **3.27**: Deprecated invalid `InputDecoration.collapsed` parameters.
- **3.35**: `maintainHintHeight` deprecated in favor of `maintainHintSize`.

### RangeSlider (3.29 / 3.35)
- **3.29**: Improved thumb alignment with divisions, thumb padding, and rounded corners.
- **3.35**: Completely redesigned to fully align with Material 3 specification.

### Progress Indicators (3.29)
- Circular and linear progress indicators revamped to adhere to the latest **Material 3** specifications.

### FadeForwardsPageTransitionsBuilder (3.29)
- **New transition builder.** This is now the official M3 page transition builder.

### Divider (3.32)
- Improved **border radii** for smoother visual appearance.

### Expansible & ExpansibleController (3.32)
- **New widget.** A flexible base for expandable/collapsible UI elements, replacing the internal role of `ExpansionTile` with support for different visual themes.
- `ExpansionTileController` is deprecated in favor of `ExpansibleController`.

### RawMenuAnchor (3.32)
- **New widget.** An unstyled menu anchor providing a foundation for highly customized menus.

### DropdownMenuFormField (3.35 / 3.41)
- **3.35**: **New widget.** Simplifies integrating Material 3 dropdown menus directly into `Form` widgets.
- **3.41**: Support for a **custom error builder**.

### NavigationRail (3.35)
- Now **scrollable** and offers more configuration options for complex navigation patterns.

### NavigationDrawer (3.35)
- Now supports **headers and footers** for greater layout flexibility.

### Badge.count (3.38)
- New **`maxCount` parameter** to automatically cap displayed notification numbers (e.g., "99+").

### ExpansionTile (3.38)
- New optional **`splashColor`** property.

### RadioListTile (3.38)
- New **`radioInnerRadius`** property for fine-grained radio button customization.

### IconButton (3.38)
- New property to specify a **states controller** for managing interaction states.

### OverlayPortal (3.38)
- **`OverlayPortal.overlayChildLayoutBuilder`** allows rendering into an arbitrary `Overlay` further up the tree.
- **Deprecated**: `OverlayPortal.targetsRootOverlay` constructor.

### Predictive Back Gestures (3.38)
- Predictive back route transitions **enabled by default** in `MaterialApp` on Android.

### SensitiveContent (3.35)
- **New widget.** Wraps content to obscure it from screen casting, recording, and screenshots on Android API 34+.

### SliverEnsureSemantics (3.35)
- **New widget.** Guarantees that screen readers can index off-screen sliver items correctly.

### SemanticsRole (3.32 / 3.35)
- **3.32**: New API for specifying semantic roles at the widget subtree level.
- **3.35**: `SemanticsLabelBuilder` added for dynamic semantic labels.

### RepeatingAnimationBuilder (3.41)
- **New widget.** Eliminates the need for `StatefulWidget` + `AnimationController` boilerplate for simple repetitive/looping animations.

### ColorFilter — Saturation (3.41)
- New built-in **saturation `ColorFilter`** via `ColorFilter.matrix` without needing complex shaders.

### Tooltip (3.41)
- New API for **manual positioning** of tooltips when defaults clip or obscure content.

### Navigator (3.41)
- **`Navigator.popUntilWithResult`**: Pop multiple routes and return a value to the destination route.

### RawAutocomplete (3.41)
- **`OptionsViewOpenDirection.mostSpace`**: Automatically positions autocomplete dropdown in the direction with the most available screen space.

### Widget Previews — `@Preview()` (3.38 / 3.41)
- **3.38**: Experimental widget previewer introduced with IDE integration.
- **3.41**: Enhanced with embedded Flutter Inspector. Support for `MultiPreviews`.

---

## iOS Platform & Engine

### Swift Package Manager (SPM) (3.27 → 3.41)
- **3.27**: Migration towards SPM begins: Flutter plugins can leverage the Swift package ecosystem.
- **3.41**: **Full SPM support is stable.** CocoaPods is considered legacy.

### Impeller Rendering Engine
- **3.27**: Default renderer on modern Android. Improved Metal rendering surface on iOS — reduced frame delays, better 120Hz performance, reduced average frame rasterization time.
- **3.29**: Impeller supports all Flutter-supported Android devices (Vulkan primary, OpenGLES fallback). Skia entirely removed from iOS.
- **3.41**: Synchronous image decoding in shaders (`decodeImageFromPixelsSync`). 128-bit float high-bitrate textures. "Bounded blur" style eliminates edge-bleeding artifacts on iOS.

### Wide Gamut Color (P3) (3.27)
- Wide-gamut P3 color space support for more vibrant visuals on compatible iOS displays.

### Unified Mobile Threading (3.29)
- Dart code on Android and iOS now executes on the **application's main thread**, eliminating the separate UI thread. Platform channel communication is drastically faster.

### UIScene Lifecycle (3.38 / 3.41)
- **3.38**: Support for Apple's `UIScene` lifecycle added (requires manual migration).
- **3.41**: UIScene support **enabled by default**. Modern multi-window iOS patterns are natively supported.

### Minimum OS Versions
- **3.35**: Minimum raised to iOS 13, Android SDK 24.
- **3.32**: Minimum raised to iOS 13, macOS 10.15.

### iOS Deep Link Validation (3.27 / 3.29)
- DevTools now supports validation for iOS deep link settings alongside Android.

### Objective-C Deprecation (3.27)
- Creation of new Objective-C iOS projects deprecated. `--ios-language objc` flag slated for removal.

### Android 16KB Page Size (3.38)
- Flutter enforces 16KB page size compatibility for Android 15+ builds (NDK r28, Java 17).

### iOS Live Text Support (3.35)
- Support for iOS Live Text integration for extracting text from images and the camera feed.

---

## Accessibility (Cross-Platform)

### Semantics Tree Performance (3.32)
- Semantics tree builds approximately **80% faster**, improving performance for screen readers.

### Form Widget Announcements (3.29)
- `Form` widget announces only the **first error** when a screen reader is enabled.

### Dropdown Menu Labels (3.29)
- Dropdown menus now have correctly announced semantic labels.

### Accessibility Documentation (3.38)
- Full rewrite of the accessibility documentation.

### Segmented Control Radio Role (3.41)
- Segmented control widgets now properly apply the `radioGroup` semantic role.

---

## Breaking Changes & Deprecations (Mobile)

| Version | Change | Migration |
|---------|--------|-----------|
| 3.27 | `TextField.canRequestFocus` deprecated | Use focus node management directly |
| 3.27 | `AssetManifest.json` generation discontinued | Use binary asset manifest |
| 3.27 | Legacy Gradle apply script removed | Migrate to Kotlin DSL |
| 3.29 | HTML web renderer removed | Use CanvasKit/WASM |
| 3.29 | Script-based Flutter Gradle plugin removed | Migrate to declarative Gradle |
| 3.32 | `ThemeData.indicatorColor` replaced | Use `TabBarThemeData.indicatorColor` |
| 3.32 | `SystemContextMenuController.show` deprecated | Use newer menu APIs |
| 3.32 | `ExpansionTileController` deprecated | Use `ExpansibleController` |
| 3.32 | `RouteTransitionRecord.markForRemove` renamed | Use `markForComplete` |
| 3.35 | `DropdownButtonFormField.value` deprecated | Use `initialValue` |
| 3.35 | `Form` widget cannot be used as sliver | Wrap in `SliverToBoxAdapter` |
| 3.35 | Observatory removed | Use Dart DevTools |
| 3.38 | `CupertinoDynamicColor` `.withOpacity` deprecated | Use `.withValues(alpha:)` |
| 3.38 | `OverlayPortal.targetsRootOverlay` deprecated | Use `OverlayPortalController` pattern |
| 3.38 | `SnackBar` with action no longer auto-dismisses | Set explicit `duration` |
