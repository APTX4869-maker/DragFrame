# DragFrame

DragFrame 是一个 macOS 原生菜单栏工具。按住快捷键并拖动鼠标左键时，它会在所有应用上方显示一个内部完全透明的渐变圆角方框；松开鼠标后方框立即消失。

当前默认快捷键是 `Shift + Option（⇧⌥）`。

## 功能特性

- 全局生效：在 macOS 桌面、浏览器、Finder、全屏应用和多显示器环境中使用。
- 菜单栏常驻：没有 Dock 图标，状态栏显示系统自适应 template 图标。
- 透明框体：框内不做填充、染色、模糊或阴影覆盖。
- 渐变边框：6pt 粗边框，18pt 圆角，支持内置颜色预设和自定义三色渐变。
- 避免底层误选中：只有在快捷键触发 DragFrame 时，应用会接管这一段左键拖拽，防止网页或文档被选中文字；普通点击、普通拖拽、滚轮、右键和键盘不受影响。
- 可配置快捷键：支持 `Option`、`Shift`、`Command` 的组合；不支持 `Control`，因为 macOS 会把 Control-click 解释为右键。
- 登录时启动：可在设置中开启“登录时自动启动 DragFrame”。
- 状态清晰：菜单栏和设置窗口会显示已就绪、已暂停、缺少权限或监听失败。
- 权限恢复提示：输入监控权限缺失或签名变化导致授权失效时，会显示设置窗口和恢复说明。

## 系统要求

- macOS 13 或更高版本
- Xcode 26 或兼容版本
- 仅在重新生成工程时需要 [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## 安装与使用

### 使用已安装应用

当前安装路径：

```sh
/Applications/DragFrame.app
```

启动：

```sh
open /Applications/DragFrame.app
```

首次使用时：

1. 打开 DragFrame。
2. 按提示进入“系统设置 → 隐私与安全性 → 输入监控”。
3. 打开 DragFrame 的输入监控权限。
4. 回到任意应用，按住 `⇧⌥` 并拖动鼠标左键。

在菜单栏中点击 DragFrame 图标，可打开设置、暂停/启用应用、修改快捷键、调整边框颜色或开启登录时自动启动。

如果系统设置里已经显示授权但应用不生效，通常是应用重新签名后 macOS 的旧授权记录不匹配。可执行：

```sh
tccutil reset ListenEvent com.vincent.dragframe
open /Applications/DragFrame.app
```

然后重新打开输入监控权限。

### 从 Xcode 运行

1. 打开 `DragFrame.xcodeproj`。
2. 选择 `DragFrame` scheme 和 `My Mac`。
3. 点击 Run。
4. 授予输入监控权限。

## 命令行构建与测试

生成工程：

```sh
xcodegen generate
```

Debug 构建：

```sh
xcodebuild \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  build CODE_SIGNING_ALLOWED=NO
```

运行测试：

```sh
xcodebuild \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  test CODE_SIGNING_ALLOWED=NO
```

Release 构建：

```sh
xcodebuild \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Release \
  -derivedDataPath .build/Release \
  build CODE_SIGNING_ALLOWED=NO
```

## 工程结构

- `DragFrame/`：macOS 应用目标，包含生命周期、全局事件监听、覆盖窗口、菜单栏和设置窗口。
- `DragFrameCore/`：纯 Swift 核心逻辑，包括快捷键模型、拖拽状态机、鼠标序列接管状态、坐标转换和设置持久化。
- `DragFrameCoreTests/`：核心逻辑单元测试。
- `DragFrame/Resources/`：Info.plist 与 AppIcon 资源。
- `docs/`：开发文档、文档索引和历史设计记录。
- `project.yml`：XcodeGen 工程定义。

更多开发细节见 [开发文档](docs/development.md)，文档导航见 [docs/index.md](docs/index.md)。
