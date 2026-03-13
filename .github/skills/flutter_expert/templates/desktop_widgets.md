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

## Desktop Rendering & Performance

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
