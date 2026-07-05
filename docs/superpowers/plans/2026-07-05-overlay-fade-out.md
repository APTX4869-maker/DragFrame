# Overlay Fade Out Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the DragFrame overlay fade out smoothly when the mouse is released.

**Architecture:** Keep drag state and event handling unchanged. Implement the visual transition entirely in `OverlayWindowController` using `NSAnimationContext` and a generation token that prevents stale animation completions from hiding a newly shown overlay.

**Tech Stack:** Swift, AppKit, Core Animation timing via AppKit animation context, XCTest, XcodeGen.

## Global Constraints

- Do not change drag behavior, shortcut behavior, event suppression, overlay colors, permissions, login item behavior, or menu bar behavior.
- Overlay show and drag updates must remain immediate.
- Overlay interior remains fully transparent.
- New drag must interrupt any in-progress fade out.

---

## File Structure

- Modify `DragFrame/Overlay/OverlayWindowController.swift`
  - Add fade-out animation and stale completion protection.
- Modify `docs/roadmap.md`
  - Record the polish item as completed.

---

### Task 1: Add fade-out state

**Files:**
- Modify: `DragFrame/Overlay/OverlayWindowController.swift`

**Interfaces:**
- Produces: `private let fadeOutDuration: TimeInterval = 0.16`
- Produces: `private var animationGeneration = 0`

- [ ] Add the properties to `OverlayWindowController`.
- [ ] Increment `animationGeneration` whenever `show()` starts a fresh visible state.

### Task 2: Animate hide

**Files:**
- Modify: `DragFrame/Overlay/OverlayWindowController.swift`

**Requirements:**
- `show()` sets `panel.alphaValue = 1`.
- `hide()` animates `panel.animator().alphaValue = 0`.
- Completion only calls `orderOut(nil)` if generation still matches.
- Completion restores `alphaValue = 1`.

### Task 3: Verify and ship

**Commands:**

```bash
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/FadeOut test CODE_SIGNING_ALLOWED=NO
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Release -derivedDataPath .build/FadeOutRelease build CODE_SIGNING_ALLOWED=NO
```

Install and sign:

```bash
pkill -x DragFrame || true
rm -rf /Applications/DragFrame.app
ditto .build/FadeOutRelease/Build/Products/Release/DragFrame.app /Applications/DragFrame.app
rm -f /Applications/DragFrame.app/Contents/MacOS/DragFrame.cstemp
codesign --force --deep --options runtime --sign 'Apple Development: 19949203yxw@gmail.com (BTPXY9RQM2)' /Applications/DragFrame.app
codesign --verify --deep --strict --verbose=2 /Applications/DragFrame.app
open /Applications/DragFrame.app
```

Commit and push:

```bash
git add DragFrame/Overlay/OverlayWindowController.swift docs/roadmap.md docs/superpowers/specs/2026-07-05-overlay-fade-out-design.md docs/superpowers/plans/2026-07-05-overlay-fade-out.md
git commit -m "feat: fade out overlay on release"
git push
```

---

## Self-Review

- Spec coverage: fade-out timing, interruption, immediate show, no behavior changes, verification, install, and push are covered.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `fadeOutDuration`, `animationGeneration`, `show()`, and `hide()` are used consistently.
