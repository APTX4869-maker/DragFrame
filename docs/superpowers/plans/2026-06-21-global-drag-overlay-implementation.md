# DragFrame 实施计划

## 目标

依据已确认的设计规范，交付可在 macOS 上构建运行的原生菜单栏应用、单元测试和使用说明。

## 实施步骤

1. 使用 XcodeGen 建立 `DragFrame` 应用、`DragFrameCore` 框架和 `DragFrameCoreTests` 测试目标。
2. 在 Core 中实现修饰键模型、设置持久化、坐标转换和纯状态拖拽状态机，并用 XCTest 覆盖。
3. 在应用目标中实现全局 `CGEventTap`、事件协调器、透明 `NSPanel` 与 Core Animation 渐变描边；当前版本使用 active tap 只在快捷键框选期间接管左键拖拽。
4. 实现菜单栏控制器、输入监控权限流程和 SwiftUI 快捷键设置窗口。
5. 生成 Xcode 工程，执行 `xcodebuild build` 与 `xcodebuild test`，修复所有编译和测试问题。
6. 编写 README，检查 Git 差异并提交完整实现。

## 验证命令

```sh
xcodegen generate
xcodebuild -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug build
xcodebuild -project DragFrame.xcodeproj -scheme DragFrame -configuration Debug test
```
