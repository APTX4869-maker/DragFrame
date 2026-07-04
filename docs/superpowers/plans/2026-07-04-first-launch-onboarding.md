# First Launch Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the first-run permission alert with a native welcome and input-monitoring onboarding window.

**Architecture:** Add a focused SwiftUI welcome view hosted by an AppKit window controller. AppDelegate owns first-run presentation state and wires callbacks into existing permission recovery logic; SettingsView gets a manual “open welcome guide” action.

**Tech Stack:** Swift, AppKit, SwiftUI, Combine, CoreGraphics input monitoring APIs, XcodeGen, XCTest.

## Global Constraints

- Minimum macOS version remains macOS 13.0.
- Do not change drag behavior, shortcut behavior, event suppression, overlay colors, or login item behavior.
- Authorized users must not be auto-interrupted at launch.
- Missing-permission first launch should show the welcome window instead of the old system alert.
- Settings must allow users to reopen the welcome guide manually.

---

## File Structure

- Create `DragFrame/UI/WelcomeView.swift`
  - SwiftUI content for welcome, permission explanation, and trial instructions.
- Create `DragFrame/UI/WelcomeWindowController.swift`
  - AppKit host window for `WelcomeView`.
- Modify `DragFrame/App/AppDelegate.swift`
  - Replace old alert first-run flow with welcome window presentation.
- Modify `DragFrame/UI/SettingsWindowController.swift`
  - Pass `openWelcomeGuide`.
- Modify `DragFrame/UI/SettingsView.swift`
  - Add “打开欢迎引导” button to permissions section.
- Modify `README.md`, `docs/development.md`, `docs/roadmap.md`
  - Document onboarding behavior and mark roadmap progress.

---

### Task 1: Add welcome UI

**Files:**
- Create: `DragFrame/UI/WelcomeView.swift`
- Create: `DragFrame/UI/WelcomeWindowController.swift`

**Interfaces:**
- Produces: `struct WelcomeView: View`
- Produces: `final class WelcomeWindowController: NSWindowController`
- Consumes: `InputMonitoringPermission`, `ModifierShortcut`, `openPrivacySettings`, `dismiss`

- [ ] Create `WelcomeView` with three sections: purpose, permission, try-it.
- [ ] Use concise Chinese copy and SF Symbols.
- [ ] Show primary button as “打开输入监控设置” when unauthorized.
- [ ] Show primary button as “开始使用” when authorized.
- [ ] Create `WelcomeWindowController.present()` and `dismiss()`.

### Task 2: Wire first-launch presentation

**Files:**
- Modify: `DragFrame/App/AppDelegate.swift`

**Interfaces:**
- Produces: `private let welcomeGuideKey = "dragFrame.didShowWelcomeGuide"`
- Produces: `private func presentWelcomeGuide(markAsShown: Bool)`
- Produces: `private func presentWelcomeGuideIfNeeded() -> Bool`

- [ ] Replace alert-based `presentPermissionExplanationIfNeeded()` with welcome window logic.
- [ ] Mark welcome as shown when it is auto-presented.
- [ ] Keep existing recovery settings window for later permission failures.
- [ ] Ensure manual welcome presentation does not mark or depend on first-run key.

### Task 3: Add manual entry from settings

**Files:**
- Modify: `DragFrame/UI/SettingsWindowController.swift`
- Modify: `DragFrame/UI/SettingsView.swift`

**Interfaces:**
- Consumes: `openWelcomeGuide: () -> Void`

- [ ] Add `openWelcomeGuide` closure to both initializers.
- [ ] Add button “打开欢迎引导” in the permission section.
- [ ] Keep existing “打开系统设置” behavior.

### Task 4: Update docs and roadmap

**Files:**
- Modify: `README.md`
- Modify: `docs/development.md`
- Modify: `docs/roadmap.md`

**Requirements:**
- README mentions first-run welcome and authorization guide.
- Development docs mention `WelcomeView` and `WelcomeWindowController`.
- Roadmap marks onboarding first version complete and moves shortcut recording after it.

### Task 5: Verify, install, commit, push

**Commands:**

```bash
xcodegen generate
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/Onboarding test CODE_SIGNING_ALLOWED=NO
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Release -derivedDataPath .build/OnboardingRelease build CODE_SIGNING_ALLOWED=NO
```

Install and sign:

```bash
pkill -x DragFrame || true
rm -rf /Applications/DragFrame.app
ditto .build/OnboardingRelease/Build/Products/Release/DragFrame.app /Applications/DragFrame.app
rm -f /Applications/DragFrame.app/Contents/MacOS/DragFrame.cstemp
codesign --force --deep --options runtime --sign 'Apple Development: 19949203yxw@gmail.com (BTPXY9RQM2)' /Applications/DragFrame.app
codesign --verify --deep --strict --verbose=2 /Applications/DragFrame.app
open /Applications/DragFrame.app
```

Commit:

```bash
git add DragFrame README.md docs/development.md docs/roadmap.md docs/superpowers/plans/2026-07-04-first-launch-onboarding.md
git commit -m "feat: add first launch onboarding"
git push
```

---

## Self-Review

- Spec coverage: welcome window, permission explanation, first-run gating, settings manual entry, docs, verification, install, and push are covered.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `WelcomeView`, `WelcomeWindowController`, `presentWelcomeGuide`, and `openWelcomeGuide` are used consistently.
