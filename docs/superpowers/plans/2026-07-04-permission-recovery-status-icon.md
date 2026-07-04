# Permission Recovery and Status Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> Historical note: this plan was written before DragFrame switched from a listen-only event tap to an active event tap for suppressing underlying text selection. Current implementation details are documented in `docs/development.md`.

**Goal:** Make DragFrame visibly recover from input-monitoring failures and show a system-adaptive menu bar icon.

**Architecture:** Add a small observable runtime status object shared by the app delegate and settings view. Keep global event monitoring read-only, but report both start success and failure so the UI can clear or show recovery guidance. Use template SF Symbol status bar images so AppKit handles white/black menu bar tinting.

**Tech Stack:** Swift, AppKit, SwiftUI, CoreGraphics event taps, macOS TCC, XcodeGen/Xcode.

## Global Constraints

- macOS deployment target remains `13.0`.
- DragFrame stays a menu bar utility with `LSUIElement`.
- The final implementation uses an active event tap and suppresses only left-mouse sequences that begin with the configured shortcut held.
- Trigger shortcut remains `Shift + Option` by default.

---

### Task 1: Runtime Monitor Status

**Files:**
- Create: `DragFrame/Services/RuntimeStatus.swift`
- Modify: `DragFrame.xcodeproj/project.pbxproj`
- Modify: `project.yml`

**Interfaces:**
- Produces: `final class RuntimeStatus: ObservableObject`
- Produces: `@Published private(set) var monitorErrorMessage: String?`
- Produces: `func reportMonitorFailure(_ message: String)`
- Produces: `func clearMonitorFailure()`

- [ ] Create `RuntimeStatus` as an `ObservableObject` that stores the current monitor error message.
- [ ] Add the new file to the DragFrame app target through `project.yml` and regenerate the Xcode project with `xcodegen generate`.
- [ ] Build to verify the new file is included.

### Task 2: Surface Monitor Success and Failure

**Files:**
- Modify: `DragFrame/App/DragCoordinator.swift`
- Modify: `DragFrame/App/AppDelegate.swift`
- Modify: `DragFrame/UI/SettingsWindowController.swift`
- Modify: `DragFrame/UI/SettingsView.swift`

**Interfaces:**
- Consumes: `RuntimeStatus.reportMonitorFailure(_:)`
- Consumes: `RuntimeStatus.clearMonitorFailure()`
- Produces: `DragCoordinator.onMonitorStarted: (() -> Void)?`

- [ ] Add `onMonitorStarted` to `DragCoordinator`.
- [ ] Call `onMonitorStarted` when `GlobalEventMonitor.start()` succeeds.
- [ ] In `AppDelegate`, report a clear monitor failure message and present the settings window once per failure.
- [ ] Clear the monitor failure when monitoring starts successfully.
- [ ] Pass `RuntimeStatus` into the settings window and settings view.
- [ ] Show a warning box in settings when `monitorErrorMessage` is non-empty, with a button that opens Input Monitoring settings.

### Task 3: Template Menu Bar Icon

**Files:**
- Modify: `DragFrame/UI/StatusItemController.swift`

**Interfaces:**
- Produces: `private func statusImage(named:accessibilityDescription:) -> NSImage?`

- [ ] Centralize menu bar image creation.
- [ ] Set `image.isTemplate = true` for both normal and warning symbols.
- [ ] Keep existing menu item behavior unchanged.

### Task 4: Test, Install, Sign, Reset TCC

**Files:**
- Modify only generated build output and `/Applications/DragFrame.app`

**Commands:**
- Run unit tests with `xcodebuild`.
- Build Release.
- Replace `/Applications/DragFrame.app`.
- Sign with `Apple Development: 19949203yxw@gmail.com (BTPXY9RQM2)`.
- Verify signature with `codesign --verify --deep --strict`.
- Reset input monitoring with `tccutil reset ListenEvent com.vincent.dragframe`.
- Launch `/Applications/DragFrame.app`.

**Expected result:** DragFrame launches, the menu bar icon is visible, and the settings/recovery window appears if the current app still needs input monitoring permission.
