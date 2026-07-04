# Native Product Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish DragFrame into a more mature native macOS menu bar utility with clearer runtime status, login-at-launch support, cleaner settings UI, and centralized overlay styling.

**Architecture:** Keep the existing separation between `DragFrameCore` pure logic and AppKit/SwiftUI app code. Add small App-layer service/model types for launch-at-login and overlay style; use `RuntimeStatus` as the single source for user-facing status; keep drag behavior unchanged.

**Tech Stack:** Swift, AppKit, SwiftUI, Combine, ServiceManagement `SMAppService.mainApp`, Core Animation, XCTest, XcodeGen.

## Global Constraints

- Minimum macOS version remains macOS 13.0.
- DragFrame remains an accessory/menu bar app with no Dock icon.
- Default shortcut remains `Shift + Option（⇧⌥）`.
- Overlay interior remains completely transparent.
- Underlying mouse event suppression behavior must not regress.
- Do not add screenshot, annotation, history, cloud sync, or complex theme features in this round.

---

## File Structure

- Create `DragFrame/Overlay/OverlayStyle.swift`
  - Defines the single default visual style consumed by `GradientBorderView`.
- Modify `DragFrame/Overlay/GradientBorderView.swift`
  - Consume `OverlayStyle` instead of hard-coded numbers/colors.
- Create `DragFrame/Services/LaunchAtLoginController.swift`
  - Wraps `SMAppService.mainApp` and exposes observable login item state.
- Modify `DragFrame/Services/RuntimeStatus.swift`
  - Adds a user-facing state model for ready, paused, permission missing, and monitor failed.
- Modify `DragFrame/UI/StatusItemController.swift`
  - Updates menu title, tooltip, and status items based on runtime state.
- Modify `DragFrame/UI/SettingsView.swift`
  - Reorganizes the settings page into a cleaner native preference-style layout.
- Modify `DragFrame/UI/SettingsWindowController.swift`
  - Injects the launch-at-login controller.
- Modify `DragFrame/App/AppDelegate.swift`
  - Wires launch-at-login and runtime status into the app.
- Modify `DragFrameCoreTests/DragFrameCoreTests.swift`
  - Adds non-UI unit coverage where possible.
- Modify `README.md` and `docs/development.md`
  - Documents new login item and status behavior.

---

### Task 1: Centralize overlay visual style

**Files:**
- Create: `DragFrame/Overlay/OverlayStyle.swift`
- Modify: `DragFrame/Overlay/GradientBorderView.swift`

**Interfaces:**
- Produces: `struct OverlayStyle` with `static let default`, `lineWidth`, `cornerRadius`, `contentInset`, `colors`, `locations`, `startPoint`, `endPoint`.
- Consumes: `GradientBorderView` reads `OverlayStyle.default`.

- [ ] **Step 1: Create `OverlayStyle`**

```swift
import AppKit

struct OverlayStyle {
    static let `default` = OverlayStyle(
        lineWidth: 6,
        cornerRadius: 18,
        contentInset: 14,
        colors: [
            NSColor(calibratedRed: 1.00, green: 0.68, blue: 0.10, alpha: 1),
            NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.49, alpha: 1),
            NSColor(calibratedRed: 0.43, green: 0.31, blue: 1.00, alpha: 1)
        ],
        locations: [0, 0.52, 1],
        startPoint: CGPoint(x: 0, y: 1),
        endPoint: CGPoint(x: 1, y: 0)
    )

    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let contentInset: CGFloat
    let colors: [NSColor]
    let locations: [NSNumber]
    let startPoint: CGPoint
    let endPoint: CGPoint
}
```

- [ ] **Step 2: Refactor `GradientBorderView` to consume style**

Set `static let contentInset = OverlayStyle.default.contentInset`, add `private let style: OverlayStyle`, initialize with default style, and replace hard-coded line width/radius/colors/locations/points with `style`.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/Polish build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds.

---

### Task 2: Add login-at-launch service

**Files:**
- Create: `DragFrame/Services/LaunchAtLoginController.swift`

**Interfaces:**
- Produces: `final class LaunchAtLoginController: ObservableObject`
- Produces: `@Published private(set) var isEnabled: Bool`
- Produces: `@Published private(set) var errorMessage: String?`
- Produces: `func refresh()`
- Produces: `func setEnabled(_ enabled: Bool)`

- [ ] **Step 1: Create service using `SMAppService.mainApp`**

```swift
import Combine
import Foundation
import ServiceManagement

final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            errorMessage = nil
            refresh()
        } catch {
            refresh()
            errorMessage = enabled
                ? "无法添加到登录项。请在系统设置中检查登录项权限。"
                : "无法从登录项移除。请在系统设置中手动关闭。"
        }
    }
}
```

- [ ] **Step 2: Build**

Run the Debug build command from Task 1.

Expected: build succeeds and `ServiceManagement` imports correctly on macOS 13+.

---

### Task 3: Make runtime status explicit

**Files:**
- Modify: `DragFrame/Services/RuntimeStatus.swift`
- Modify: `DragFrame/App/AppDelegate.swift`
- Modify: `DragFrame/UI/StatusItemController.swift`

**Interfaces:**
- Produces: `enum RuntimeState: Equatable`
- Produces: `var title: String`
- Produces: `var detail: String`
- Produces: `var symbolName: String`
- Produces: `RuntimeStatus.update(enabled:permissionGranted:monitorErrorMessage:)`

- [ ] **Step 1: Expand `RuntimeStatus`**

Add explicit state cases:

```swift
enum RuntimeState: Equatable {
    case ready
    case paused
    case permissionMissing(message: String)
    case monitorFailed(message: String)
}
```

Then expose computed `title`, `detail`, and `symbolName` for UI.

- [ ] **Step 2: Wire state updates in `AppDelegate`**

After permission refresh, enabled changes, monitor failure, and monitor started callbacks, call one helper:

```swift
private func updateRuntimePresentation() {
    runtimeStatus.update(
        enabled: statusController.isEnabled,
        permissionGranted: permission.isAuthorized,
        monitorErrorMessage: runtimeStatus.monitorErrorMessage
    )
    statusController.update(runtimeState: runtimeStatus.state)
}
```

- [ ] **Step 3: Update status item**

Replace `update(permissionGranted:)`-only presentation with `update(runtimeState:)`, while keeping existing callback behavior.

- [ ] **Step 4: Run tests/build**

Run:

```bash
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/Polish test CODE_SIGNING_ALLOWED=NO
```

Expected: tests pass.

---

### Task 4: Redesign settings window content

**Files:**
- Modify: `DragFrame/UI/SettingsView.swift`
- Modify: `DragFrame/UI/SettingsWindowController.swift`
- Modify: `DragFrame/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `LaunchAtLoginController`
- Consumes: `RuntimeStatus.state`
- Produces: a single-page settings view with Status, Shortcut, Startup, Appearance, and Permission sections.

- [ ] **Step 1: Inject launch-at-login**

Update `SettingsWindowController.init` and `SettingsView` initializer to accept:

```swift
@ObservedObject var launchAtLogin: LaunchAtLoginController
```

- [ ] **Step 2: Add native-feeling sections**

Use `Form`, `GroupBox`, concise headers, SF Symbols, and macOS checkbox toggles. Keep copy short.

- [ ] **Step 3: Add login toggle**

Bind toggle to:

```swift
Binding(
    get: { launchAtLogin.isEnabled },
    set: { launchAtLogin.setEnabled($0) }
)
```

- [ ] **Step 4: Add appearance summary**

Display the fixed style summary:

```text
6pt 渐变描边 · 18pt 圆角 · 内部透明
```

- [ ] **Step 5: Build and manually inspect**

Run the Debug build command. Open the app and confirm the settings window is clean, readable, and no larger than needed.

---

### Task 5: Update docs and verify

**Files:**
- Modify: `README.md`
- Modify: `docs/development.md`

**Interfaces:**
- Documents login-at-launch setting, runtime states, and overlay style centralization.

- [ ] **Step 1: Update user docs**

Add:

- “登录时自动启动” setting.
- Status descriptions: ready, paused, missing permission, monitor failure.

- [ ] **Step 2: Update development docs**

Add:

- `LaunchAtLoginController`
- `OverlayStyle`
- Runtime state flow.

- [ ] **Step 3: Final verification**

Run:

```bash
xcodebuild -quiet -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug -derivedDataPath .build/Polish test CODE_SIGNING_ALLOWED=NO
git status --short
```

Expected: tests pass and only intended files are modified.

- [ ] **Step 4: Commit**

```bash
git add DragFrame README.md docs/development.md docs/superpowers/plans/2026-07-04-native-product-polish.md
git commit -m "feat: polish native app experience"
```

---

## Self-Review

- Spec coverage: the plan covers first-run/status clarity, login-at-launch, settings polish, overlay style centralization, docs, and tests.
- Placeholder scan: no TBD/TODO placeholders are intentionally left in the plan.
- Type consistency: `LaunchAtLoginController`, `RuntimeState`, `RuntimeStatus`, and `OverlayStyle` names are consistent across tasks.
