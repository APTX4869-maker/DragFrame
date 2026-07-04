# Suppress Underlying Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent underlying apps from selecting or dragging content while DragFrame is drawing its global rectangle.

**Architecture:** Add a testable `DragCaptureState` in `DragFrameCore` to decide whether a mouse sequence is owned by DragFrame. Change the AppKit event tap to an active `.defaultTap` and return `nil` only for captured left-mouse events. Keep the overlay state machine separate from event suppression.

**Tech Stack:** Swift, AppKit, CoreGraphics `CGEventTap`, XCTest, macOS TCC Input Monitoring.

## Global Constraints

- macOS deployment target remains `13.0`.
- Default shortcut remains `Shift + Option`.
- Suppression only applies to left mouse down/drag/up sequences that begin with the configured shortcut held.
- `flagsChanged`, keyboard character events, right-clicks, and scroll events are not suppressed.

---

### Task 1: Core Capture State

**Files:**
- Create: `DragFrameCore/DragCaptureState.swift`
- Modify: `DragFrameCoreTests/DragFrameCoreTests.swift`

**Interfaces:**
- Produces: `public struct DragCaptureState`
- Produces: `public private(set) var isCapturingMouseSequence: Bool`
- Produces: `public mutating func mouseDown(modifiers: ModifierShortcut, requiredModifiers: ModifierShortcut) -> Bool`
- Produces: `public func mouseDragged() -> Bool`
- Produces: `public mutating func mouseUp() -> Bool`
- Produces: `public mutating func cancel()`

- [ ] Write tests for no-capture, capture, drag suppression, and reset on mouse up.
- [ ] Implement `DragCaptureState`.
- [ ] Run `xcodebuild ... test CODE_SIGNING_ALLOWED=NO`.

### Task 2: Active Event Tap

**Files:**
- Modify: `DragFrame/Services/GlobalEventMonitor.swift`
- Modify: `DragFrame/App/DragCoordinator.swift`

**Interfaces:**
- Consumes: `DragCaptureState`
- Changes: `GlobalEventMonitorDelegate.globalEventMonitor(_:received:) -> Bool`

- [ ] Change the event tap option from `.listenOnly` to `.defaultTap`.
- [ ] Make `GlobalEventMonitor.receive` return whether the current event should be suppressed.
- [ ] Make the callback return `nil` only when the delegate says to suppress.
- [ ] In `DragCoordinator`, use `DragCaptureState` to suppress only captured left mouse sequences.
- [ ] Keep modifier changes pass-through while still cancelling the overlay when the shortcut is released.

### Task 3: Build, Install, Verify

**Files:**
- Modify only build output and `/Applications/DragFrame.app`

**Commands:**
- Run unit tests.
- Build Release.
- Replace `/Applications/DragFrame.app`.
- Sign with the Apple Development identity.
- Launch DragFrame and test `⇧⌥` dragging over selectable text.

**Expected result:** DragFrame shows its rectangle while the underlying page no longer selects text.
