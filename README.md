# DragFrame

DragFrame 是一个 macOS 原生菜单栏工具。按住已配置的修饰键并拖动鼠标左键时，它会在所有应用上方显示内部完全透明的渐变圆角方框；松开鼠标后方框立即消失。

## 功能

- 默认快捷键：`Control + Option（⌃⌥）`
- 3pt 橙黄 → 粉红 → 紫色渐变描边
- 18pt 圆角和轻阴影，框内完全透明
- 不拦截或修改原应用的鼠标操作
- 支持四个拖动方向、多显示器和全屏空间
- 菜单栏中启用/停用
- 设置窗口中重新绑定修饰键组合

## 系统要求

- macOS 13 或更高版本
- Xcode 26 或兼容版本
- 仅在重新生成工程时需要 [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## 运行

1. 用 Xcode 打开 `DragFrame.xcodeproj`。
2. 选择 `DragFrame` scheme 和 `My Mac`，点击 Run。
3. 首次运行时，根据提示授予“系统设置 → 隐私与安全性 → 输入监控”权限。
4. 菜单栏出现虚线方框图标后，按住 `⌃⌥` 并拖动鼠标左键。

如果授权后没有立即生效，可从菜单栏退出 DragFrame，然后在 Xcode 中再次运行。

## 命令行构建与测试

```sh
xcodegen generate
xcodebuild \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild \
  -project DragFrame.xcodeproj \
  -scheme DragFrame \
  -configuration Debug \
  -derivedDataPath .build/DerivedData \
  test CODE_SIGNING_ALLOWED=NO
```

## 工程结构

- `DragFrameCore/`：快捷键模型、状态机、坐标转换和设置持久化
- `DragFrame/Services/`：输入监控权限与只读全局事件监听
- `DragFrame/Overlay/`：透明覆盖窗口与渐变描边
- `DragFrame/UI/`：菜单栏和 SwiftUI 设置窗口
- `DragFrameCoreTests/`：核心逻辑单元测试

产品和架构细节见 [设计规范](docs/superpowers/specs/2026-06-21-global-drag-overlay-design.md)。
