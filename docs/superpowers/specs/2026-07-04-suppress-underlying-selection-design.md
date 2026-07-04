# DragFrame 拦截底层文本选择设计

## 背景

DragFrame 当前使用只读 `CGEventTap` 观察全局鼠标拖拽。用户按住快捷键拖动时，渐变方框能正常显示，但同一段鼠标拖拽仍会继续传给 Chrome、网页、PDF 或其他应用，导致底层内容被选中。

## 目标

1. 按住 DragFrame 快捷键并左键拖拽时，只显示 DragFrame 方框，不触发底层应用文本选择、拖拽或点击。
2. 不影响普通左键点击、普通拖拽、滚动、键盘输入和非快捷键场景。
3. 继续在鼠标松开时隐藏方框。

## 方案

- 将 `GlobalEventMonitor` 的 event tap 从 `.listenOnly` 改为 `.defaultTap`，让回调可以返回 `nil` 来阻止事件继续传给其他应用。
- 在核心层新增 `DragCaptureState`，只负责判断一段左键鼠标序列是否被 DragFrame 接管：
  - 左键按下时，如果当前修饰键包含配置的快捷键，则开始接管，并吞掉这次 `mouseDown`。
  - 接管期间吞掉所有 `mouseDragged`。
  - 左键松开时吞掉 `mouseUp` 并结束接管。
  - 如果左键按下时没有快捷键，则不接管，后续拖拽照常传给底层应用。
- `flagsChanged` 事件不吞掉。用户松开快捷键时，DragFrame 隐藏方框，但仍继续吞掉本次鼠标序列直到 `mouseUp`，避免底层应用收到没有 `mouseDown` 的半截拖拽。
- 事件 tap 仍只关注左键和修饰键变化；不会拦截键盘字符、滚轮或右键事件。

## 验证

- 单元测试覆盖 `DragCaptureState`：
  - 缺少快捷键时不接管。
  - 快捷键完整时从 `mouseDown` 到 `mouseUp` 全程接管。
  - `mouseUp` 后接管状态重置。
- Release 构建成功并安装到 `/Applications/DragFrame.app`。
- 用户按住默认 `⇧⌥` 拖动网页文本时，只出现 DragFrame 方框，网页不再出现文本选择高亮。
