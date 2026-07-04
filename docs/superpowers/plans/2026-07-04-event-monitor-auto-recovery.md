# Event Monitor Auto Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make DragFrame automatically recover from temporary global event monitor failures before surfacing user-facing errors.

**Architecture:** Extend the event monitor with explicit disable reasons, re-enable and restart operations. Add a small recovery state model in `DragFrameCore`, coordinate recovery from `DragCoordinator`, and keep user-visible error handling in `AppDelegate`/`RuntimeStatus`.

**Tech Stack:** Swift, AppKit, CoreGraphics `CGEventTap`, Foundation, XCTest, XcodeGen.

## Global Constraints

- Minimum macOS version remains macOS 13.0.
- Do not change drag behavior, shortcut behavior, event suppression, overlay colors, or login item behavior.
- User-paused DragFrame must not auto-recover.
- Temporary event tap disables should recover silently when possible.
- User-visible recovery prompts should appear only after repeated restart failures.

---

## File Structure

- Create `DragFrameCore/MonitorRecoveryState.swift`
  - Tracks consecutive restart failures and threshold decisions.
- Modify `DragFrameCoreTests/DragFrameCoreTests.swift`
  - Adds unit tests for recovery state.
- Modify `DragFrame/Services/GlobalEventMonitor.swift`
  - Adds `MonitorDisableReason`, `reenable()`, `restart()`, and richer delegate callback.
- Modify `DragFrame/App/DragCoordinator.swift`
  - Coordinates re-enable/restart recovery and callback notifications.
- Modify `DragFrame/App/AppDelegate.swift`
  - Only surfaces monitor failures after recovery threshold is reached.
- Modify `README.md`, `docs/development.md`, `docs/roadmap.md`
  - Documents auto recovery and marks roadmap progress.

---

### Task 1: Add recovery state model

**Files:**
- Create: `DragFrameCore/MonitorRecoveryState.swift`
- Modify: `DragFrameCoreTests/DragFrameCoreTests.swift`

**Interfaces:**
- Produces: `public struct MonitorRecoveryState`
- Produces: `public mutating func recordRestartFailure()`
- Produces: `public mutating func reset()`
- Produces: `public var shouldSurfaceFailure: Bool`

- [ ] Add `MonitorRecoveryState` with default `maxRestartAttempts = 3`.
- [ ] Add tests for initial state, failure counting, threshold, and reset.

### Task 2: Extend event monitor operations

**Files:**
- Modify: `DragFrame/Services/GlobalEventMonitor.swift`

**Interfaces:**
- Produces: `enum MonitorDisableReason`
- Produces: `func reenable() -> Bool`
- Produces: `func restart() -> Bool`
- Replaces: `globalEventMonitorWasDisabled(_:)`

- [ ] Map `.tapDisabledByTimeout` to `.timeout`.
- [ ] Map `.tapDisabledByUserInput` to `.userInput`.
- [ ] Attempt `reenable()` in `receive(type:event:)`.
- [ ] Notify delegate with `recoveredByReenable`.
- [ ] Keep disabled events non-suppressed.

### Task 3: Coordinate recovery

**Files:**
- Modify: `DragFrame/App/DragCoordinator.swift`

**Interfaces:**
- Produces: `var onMonitorRecovered: (() -> Void)?`
- Produces: `var onMonitorRecoveryFailed: (() -> Void)?`

- [ ] Cancel active drag state when event tap is disabled.
- [ ] If re-enable succeeds, reset recovery state and notify recovered.
- [ ] If re-enable fails, asynchronously call `monitor.restart()`.
- [ ] On restart success, reset recovery state and notify recovered.
- [ ] On restart failure, increment state and surface failure only at threshold.
- [ ] Disable recovery when `isEnabled == false`.

### Task 4: Wire app-level status

**Files:**
- Modify: `DragFrame/App/AppDelegate.swift`

**Requirements:**
- `onMonitorRecovered` clears monitor failure and updates menu/status.
- `onMonitorRecoveryFailed` reports existing `monitorStartFailureMessage` and presents recovery window.
- `onMonitorStartFailure` uses same threshold-aware failure path where appropriate.

### Task 5: Update docs, verify, install, push

**Files:**
- Modify: `README.md`
- Modify: `docs/development.md`
- Modify: `docs/roadmap.md`

**Commands:**

```bash
xcodegen generate
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/Recovery test CODE_SIGNING_ALLOWED=NO
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Release -derivedDataPath .build/RecoveryRelease build CODE_SIGNING_ALLOWED=NO
```

Install and sign:

```bash
pkill -x DragFrame || true
rm -rf /Applications/DragFrame.app
ditto .build/RecoveryRelease/Build/Products/Release/DragFrame.app /Applications/DragFrame.app
rm -f /Applications/DragFrame.app/Contents/MacOS/DragFrame.cstemp
codesign --force --deep --options runtime --sign 'Apple Development: 19949203yxw@gmail.com (BTPXY9RQM2)' /Applications/DragFrame.app
codesign --verify --deep --strict --verbose=2 /Applications/DragFrame.app
open /Applications/DragFrame.app
```

Commit and push:

```bash
git add DragFrame DragFrameCore DragFrameCoreTests README.md docs/development.md docs/roadmap.md docs/superpowers/plans/2026-07-04-event-monitor-auto-recovery.md
git commit -m "feat: recover event monitor automatically"
git push
```

---

## Self-Review

- Spec coverage: re-enable, restart, threshold failure, silent recovery, paused behavior, docs, tests, install, and push are covered.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `MonitorRecoveryState`, `MonitorDisableReason`, `reenable()`, `restart()`, `onMonitorRecovered`, and `onMonitorRecoveryFailed` are used consistently.
