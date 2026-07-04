# DragFrame 开发文档

## 1. 项目概览

DragFrame 是一个 macOS 原生菜单栏应用。用户按住配置好的修饰键并拖动鼠标左键时，应用在所有应用上方绘制一个内部透明、渐变描边、圆角的选区框。

当前产品行为：

- 默认快捷键：`Shift + Option（⇧⌥）`
- 支持重新绑定 `Option`、`Shift`、`Command` 的任意非空组合
- 不支持 `Control`，避免触发 macOS Control-click 右键菜单
- 只在快捷键触发的左键拖拽序列中接管鼠标事件，防止底层页面或文档选中文字
- 普通点击、普通拖拽、右键、滚轮和键盘输入不被拦截
- 方框内部完全透明，只绘制 6pt 渐变圆角描边
- 边框颜色支持内置预设和自定义三色渐变
- 应用常驻菜单栏，不显示 Dock 图标
- 可在设置中开启登录时自动启动
- 首次缺少输入监控权限时显示欢迎与授权引导
- 菜单栏和设置窗口显示明确运行状态：已就绪、已暂停、缺少权限或监听失败

## 2. 技术栈

- Swift
- AppKit
- SwiftUI
- CoreGraphics `CGEventTap`
- Core Animation
- XCTest
- XcodeGen

最低系统版本：macOS 13。

## 3. 目录结构

```text
DragFrame/
  App/
    AppDelegate.swift
    ApplicationMain.swift
    DragCoordinator.swift
  Overlay/
    GradientBorderView.swift
    OverlayStyle.swift
    OverlayWindowController.swift
  Services/
    GlobalEventMonitor.swift
    InputMonitoringPermission.swift
    LaunchAtLoginController.swift
    RuntimeStatus.swift
  UI/
    SettingsView.swift
    SettingsWindowController.swift
    StatusItemController.swift
    WelcomeView.swift
    WelcomeWindowController.swift
  Resources/
    Info.plist
    Assets.xcassets/

DragFrameCore/
  CoordinateConverter.swift
  DragCaptureState.swift
  DragStateMachine.swift
  ModifierShortcut.swift
  ShortcutSettings.swift

DragFrameCoreTests/
  DragFrameCoreTests.swift

project.yml
README.md
docs/
```

## 4. 核心模块

### `ModifierShortcut`

定义可配置的修饰键组合：

- `command`
- `option`
- `shift`
- `control`

其中 `supported` 只包含 `command`、`option`、`shift`。`control` 可以从系统事件中解析出来，但不能作为有效配置保存。

### `ShortcutSettings`

负责读取和保存快捷键设置：

- 存储键：`dragFrame.modifierShortcut`
- 默认值：`Shift + Option`
- 启动时会把包含 `Control` 或无效 bit 的旧配置迁移为默认值
- 设置变更通过 `onChange` 通知应用层立即生效

### `DragCaptureState`

负责判断一整段左键鼠标序列是否由 DragFrame 接管。

规则：

1. 左键按下时，如果当前修饰键包含当前配置的快捷键，则开始接管。
2. 接管期间吞掉 `mouseDown`、`mouseDragged`、`mouseUp`。
3. `mouseUp` 后接管状态重置。
4. 如果左键按下时没有触发快捷键，则整段鼠标序列都不接管。

这个状态只负责“是否吞事件”，不负责绘制方框。

### `DragStateMachine`

负责把鼠标事件转换为覆盖框输出：

- `idle`
- `pressed`
- `dragging`

规则：

- 左键按下且快捷键匹配时记录起点
- 移动超过 3pt 后开始显示方框
- 鼠标松开时隐藏方框
- 拖拽中释放必需修饰键时隐藏方框
- 允许额外按住未配置的修饰键

### `CoordinateConverter`

把 Quartz 全局坐标转换为 AppKit 全局坐标。用于兼容 macOS 屏幕坐标系差异和多显示器负坐标布局。

## 5. 应用层架构

### `AppDelegate`

应用入口和协调中心：

- 设置 `NSApp` 为 accessory 模式
- 初始化菜单栏、设置窗口、权限对象、拖拽协调器
- 每 2 秒刷新一次输入监控权限
- 首次缺少输入监控权限时显示欢迎窗口
- 权限缺失或事件监听失败时显示恢复窗口
- 通过 `RuntimeStatus` 同步菜单栏和设置窗口的用户可见状态
- 处理菜单栏回调：启用/停用、打开设置、打开系统设置、退出

### `GlobalEventMonitor`

创建全局 `CGEventTap`：

- tap 类型：`.cgSessionEventTap`
- 位置：`.tailAppendEventTap`
- 选项：`.defaultTap`
- 监听事件：
  - `.leftMouseDown`
  - `.leftMouseDragged`
  - `.leftMouseUp`
  - `.flagsChanged`

回调返回值：

- 返回原事件：事件继续传给底层应用
- 返回 `nil`：事件被 DragFrame 接管，不再传给底层应用

只有 `DragCoordinator` 判定该左键序列由 DragFrame 接管时才会返回 `nil`。

### `DragCoordinator`

连接事件监听、核心状态机和覆盖窗口：

1. 收到全局鼠标/修饰键事件。
2. 用 `DragCaptureState` 判断是否吞掉底层事件。
3. 用 `DragStateMachine` 判断是否显示、更新或隐藏方框。
4. 将 Quartz 坐标转换为 AppKit 坐标。
5. 调用 `OverlayWindowController` 更新覆盖层。

### `OverlayWindowController`

管理一个透明、无边框、不激活的 `NSPanel`：

- `isOpaque = false`
- `backgroundColor = .clear`
- `ignoresMouseEvents = true`
- `level = .screenSaver`
- `collectionBehavior` 包含 `.canJoinAllSpaces` 和 `.fullScreenAuxiliary`

面板只用于显示视觉覆盖，不接收鼠标事件。

### `GradientBorderView`

使用 Core Animation 绘制边框：

- `CAGradientLayer` 提供橙黄 → 粉红 → 紫色渐变
- `CAShapeLayer` 作为 mask，只显示圆角描边
- 不绘制填充，不绘制阴影
- 描边宽度 6pt，圆角半径最多 18pt

### `OverlayStyle`

集中定义覆盖框视觉样式：

- `lineWidth = 6`
- `cornerRadius = 18`
- `contentInset = 14`
- 渐变颜色、位置和方向

当前固定边框粗细、圆角和渐变方向；颜色由 `OverlayStyleSettings` 提供。

### `OverlayStylePreset`

定义边框颜色预设：

- `vibrant`：活力渐变，默认橙黄 → 粉红 → 紫色
- `ocean`：海蓝渐变
- `aurora`：极光渐变
- `graphite`：石墨白
- `custom`：用户自定义三色渐变

### `OverlayStyleSettings`

负责覆盖框颜色配置：

- 使用 `UserDefaults` 保存当前预设
- 使用 `#RRGGBBAA` 保存自定义起始、中间、结束颜色
- 根据当前配置生成最终 `OverlayStyle`
- 通过 `onChange` 通知 `OverlayWindowController` 实时刷新

无效预设或颜色字符串会回退到默认活力渐变，不影响拖拽主功能。

### `RuntimeStatus`

统一表达应用对用户可见的运行状态：

- `ready`：已授权且输入监听正常
- `paused`：用户从菜单栏暂停了 DragFrame
- `permissionMissing`：缺少输入监控权限
- `monitorFailed`：权限看似存在，但 active event tap 启动失败

菜单栏图标、tooltip、菜单状态行和设置窗口顶部状态都从这里读取，避免出现“一个地方显示正常，另一个地方显示异常”的错位。

### `LaunchAtLoginController`

封装 macOS 原生 `ServiceManagement`：

- 使用 `SMAppService.mainApp.status` 读取登录项状态
- 使用 `register()` 开启登录时启动
- 使用 `unregister()` 关闭登录时启动
- 注册或移除失败时在设置页显示简短错误，不影响拖拽主功能

### `StatusItemController`

管理菜单栏图标和菜单：

- 正常状态：`rectangle.dashed`
- 暂停状态：`pause.rectangle`
- 异常状态：`exclamationmark.rectangle`
- 图标设置 `isTemplate = true`，由 macOS 自动适配深浅色状态栏
- 菜单包含启用开关、当前快捷键、状态提示、设置入口、系统设置入口和退出入口

### `SettingsView`

SwiftUI 设置窗口：

- 展示当前运行状态
- 选择 `Option`、`Shift`、`Command`
- 展示当前快捷键组合
- 恢复默认值
- 开启或关闭登录时自动启动
- 选择边框颜色预设
- 自定义三色渐变
- 展示当前覆盖框样式预览
- 展示输入监控权限状态
- 可重新打开欢迎引导
- 展示监听失败恢复说明

### `WelcomeWindowController`

管理首次启动欢迎窗口：

- 承载 SwiftUI `WelcomeView`
- 使用普通 `NSWindow`，不显示 Dock 图标
- 缺少输入监控权限且本机未展示过欢迎引导时，由 `AppDelegate` 自动打开
- 设置页可手动重新打开

### `WelcomeView`

展示轻量欢迎与授权引导：

- 说明 DragFrame 用途：按住快捷键并拖动鼠标左键，在任何应用上方显示透明渐变方框
- 说明输入监控用途：只读取修饰键和鼠标拖动，不保存输入内容
- 未授权时显示“打开输入监控设置”
- 已授权时显示“开始使用”和当前快捷键试用提示

## 6. 权限模型

DragFrame 需要 macOS 输入监控权限来建立全局事件 tap。

相关 API：

- `CGPreflightListenEventAccess()`
- `CGRequestListenEventAccess()`

权限入口：

```text
系统设置 → 隐私与安全性 → 输入监控
```

如果应用重新构建或重新签名，macOS 可能保留旧授权记录，但拒绝当前版本。典型日志是：

```text
Failed to match existing code requirement for subject com.vincent.dragframe
```

恢复命令：

```sh
tccutil reset ListenEvent com.vincent.dragframe
open /Applications/DragFrame.app
```

然后在系统设置中重新打开 DragFrame 的输入监控权限。

## 7. 构建与测试

生成 Xcode 工程：

```sh
xcodegen generate
```

运行单元测试：

```sh
xcodebuild -quiet \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  test CODE_SIGNING_ALLOWED=NO
```

查看测试摘要：

```sh
xcrun xcresulttool get test-results summary \
  --path .build/DerivedData/Logs/Test/*.xcresult
```

Release 构建：

```sh
xcodebuild -quiet \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Release \
  -derivedDataPath .build/Release \
  build CODE_SIGNING_ALLOWED=NO
```

## 8. 本机安装与签名

将 Release 构建安装到 `/Applications`：

```sh
pkill -x DragFrame || true
rm -rf /Applications/DragFrame.app
ditto .build/Release/Build/Products/Release/DragFrame.app /Applications/DragFrame.app
```

使用本机 Apple Development 证书签名：

```sh
codesign --force --deep --options runtime \
  --sign 'Apple Development: 19949203yxw@gmail.com (BTPXY9RQM2)' \
  /Applications/DragFrame.app
```

验证签名：

```sh
codesign --verify --deep --strict --verbose=2 /Applications/DragFrame.app
codesign -dv --verbose=4 /Applications/DragFrame.app 2>&1
```

启动：

```sh
open /Applications/DragFrame.app
```

## 9. 手工验收清单

### 基础行为

- 菜单栏出现 DragFrame 图标。
- 图标在浅色/深色/蓝色状态栏上可见。
- 设置窗口能打开。
- 默认快捷键显示为 `⇧⌥`。
- 设置窗口展示运行状态、快捷键、启动、外观和权限分组。
- 设置窗口可以重新打开欢迎引导。
- 外观分组能切换颜色预设，并在选择“自定义”后显示三个颜色选择器。

### 拖拽框

- 按住 `⇧⌥` 并拖动左键，显示渐变圆角方框。
- 框内完全透明，没有灰色、紫色或其他颜色覆盖。
- 切换颜色预设或自定义颜色后，拖拽框使用新的边框颜色。
- 松开鼠标后方框消失。
- 不同拖动方向都能正常绘制。
- 跨显示器拖动时位置连续。

### 底层应用交互

- 不按快捷键时，网页文字选择、普通拖拽、窗口操作保持原样。
- 按住快捷键并拖动网页文字时，只显示 DragFrame 方框，底层网页不出现文字选择高亮。
- 右键、滚轮、键盘输入不受影响。

### 权限恢复

- 首次缺少输入监控权限时，显示欢迎窗口而不是旧系统 alert。
- 撤销输入监控权限后，菜单栏显示警告状态。
- 设置窗口展示恢复说明。
- 重新授权后，应用无需重启即可恢复监听。
- 开启“登录时自动启动 DragFrame”后，设置项保持打开；关闭后保持关闭。

## 10. 常见问题

### 授权了但仍不能用

通常是签名变化导致 TCC 旧授权不匹配。执行：

```sh
tccutil reset ListenEvent com.vincent.dragframe
open /Applications/DragFrame.app
```

然后重新打开输入监控权限。

### 菜单栏看不到图标

当前状态栏图标使用 template SF Symbol，正常会由系统自动渲染。如果仍不可见：

1. 确认运行的是最新 `/Applications/DragFrame.app`。
2. 退出并重新启动 DragFrame。
3. 确认 `StatusItemController` 中 `image?.isTemplate = true` 没有被移除。

### 拖拽时底层内容仍被选中

检查当前进程是否建立 active event tap：

```sh
pgrep -fl DragFrame
```

然后用 `CGGetEventTapList` 检查 DragFrame 对应 tap 的 `options`。`options=0` 表示 active tap；如果是只读 tap，则无法阻止底层选中。

### 修改快捷键后不生效

确认设置没有包含 `Control`，并且至少选择了一个修饰键。有效组合会立即保存到 `UserDefaults`，不需要重启应用。

## 11. 设计记录

历史设计和实施记录保存在：

- `docs/superpowers/specs/`
- `docs/superpowers/plans/`

这些文件记录了需求演进过程；当前实现以本文档和 README 为准。
