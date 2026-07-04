# Custom Overlay Colors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add preset and custom gradient border colors to DragFrame while keeping the overlay interior fully transparent.

**Architecture:** Extend the existing AppKit overlay style layer with preset and persisted settings. Inject the settings object into the overlay controller and SwiftUI settings view so changes update preview, persistence, and live overlay rendering without touching drag-state logic.

**Tech Stack:** Swift, AppKit, SwiftUI, Combine, UserDefaults, Core Animation, XCTest, XcodeGen.

## Global Constraints

- Minimum macOS version remains macOS 13.0.
- Overlay interior remains completely transparent.
- Default visual style remains the existing vibrant orange/pink/purple gradient.
- Drag behavior, shortcut behavior, and underlying event suppression must not change.
- Do not add fill color, shadow, blur, theme marketplace, or gradient direction controls in this round.

---

## File Structure

- Modify `DragFrame/Overlay/OverlayStyle.swift`
  - Add `OverlayStylePreset`, color hex helpers, and `OverlayStyleSettings`.
- Modify `DragFrame/Overlay/GradientBorderView.swift`
  - Make style mutable and refresh gradient colors when it changes.
- Modify `DragFrame/Overlay/OverlayWindowController.swift`
  - Accept initial style and expose `update(style:)`.
- Modify `DragFrame/App/AppDelegate.swift`
  - Own `OverlayStyleSettings`, inject it, and update overlay on change.
- Modify `DragFrame/UI/SettingsWindowController.swift`
  - Inject `OverlayStyleSettings`.
- Modify `DragFrame/UI/SettingsView.swift`
  - Add preset picker, custom ColorPickers, live preview, and reset action.
- Modify `README.md`, `docs/development.md`, and `docs/roadmap.md`
  - Document custom color support and mark roadmap item as underway/done.

---

### Task 1: Add style presets and persistence

**Files:**
- Modify: `DragFrame/Overlay/OverlayStyle.swift`

**Interfaces:**
- Produces: `enum OverlayStylePreset: String, CaseIterable, Identifiable`
- Produces: `final class OverlayStyleSettings: ObservableObject`
- Produces: `func resetToDefault()`
- Produces: `var style: OverlayStyle`

- [ ] Add four built-in presets plus `custom`.
- [ ] Store preset and custom colors in `UserDefaults`.
- [ ] Save colors as `#RRGGBBAA`.
- [ ] Fall back safely on invalid stored values.

### Task 2: Make overlay style live-updatable

**Files:**
- Modify: `DragFrame/Overlay/GradientBorderView.swift`
- Modify: `DragFrame/Overlay/OverlayWindowController.swift`

**Interfaces:**
- Produces: `GradientBorderView.update(style:)`
- Produces: `OverlayWindowController.update(style:)`

- [ ] Update gradient layer colors/locations/points when style changes.
- [ ] Use current style inset when sizing the overlay panel.
- [ ] Keep `isOpaque = false`, `backgroundColor = .clear`, and no fill.

### Task 3: Wire settings through the app

**Files:**
- Modify: `DragFrame/App/AppDelegate.swift`
- Modify: `DragFrame/UI/SettingsWindowController.swift`

**Interfaces:**
- Consumes: `OverlayStyleSettings.onChange`
- Produces: app-level injection into overlay and settings.

- [ ] Create `OverlayStyleSettings` in `AppDelegate`.
- [ ] Create `OverlayWindowController(style:)` and inject into `DragCoordinator`.
- [ ] Pass settings into `SettingsWindowController`.
- [ ] Update overlay whenever settings change.

### Task 4: Build native color settings UI

**Files:**
- Modify: `DragFrame/UI/SettingsView.swift`

**Interfaces:**
- Consumes: `OverlayStyleSettings`

- [ ] Replace the static appearance summary with a preset picker.
- [ ] Show a gradient preview using current style.
- [ ] Show three ColorPickers only for custom style.
- [ ] Add “恢复默认”.
- [ ] Keep copy short and clear.

### Task 5: Verify and document

**Files:**
- Modify: `README.md`
- Modify: `docs/development.md`
- Modify: `docs/roadmap.md`

**Verification:**
- Run `xcodegen generate`.
- Run Debug tests.
- Build Release.
- Install, sign, and launch `/Applications/DragFrame.app`.
- Commit and push.

---

## Self-Review

- Spec coverage: presets, custom colors, persistence, live preview, overlay update, and docs are covered.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `OverlayStylePreset`, `OverlayStyleSettings`, `update(style:)`, and `resetToDefault()` are used consistently.
