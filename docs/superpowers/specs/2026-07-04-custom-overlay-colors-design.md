# Custom Overlay Colors Design

## 背景

DragFrame 的核心视觉是内部透明的渐变圆角边框。当前边框颜色固定为橙黄 → 粉红 → 紫色，视觉醒目，但不同用户可能会在不同壁纸、应用背景、演示场景中需要更适合的颜色。

本设计为 DragFrame 增加“自定义方框颜色”能力，同时保持产品克制、原生、轻量。

## 产品目标

- 用户可以快速选择少量有品味的内置边框颜色。
- 用户可以按需自定义三色渐变。
- 设置页能实时预览当前边框风格。
- 框内继续完全透明，不增加填充色。
- 拖拽行为、快捷键行为、事件接管行为不改变。

## 非目标

本轮不做：

- 边框填充色。
- 阴影、模糊、发光等复杂视觉效果。
- 主题市场、导入导出主题。
- 单独调整渐变方向。
- 单独调整边框粗细和圆角。

## 用户体验设计

设置页“外观”分组升级为颜色选择区域：

1. 显示当前边框预览。
2. 提供内置预设：
   - 活力渐变：橙黄 → 粉红 → 紫色，当前默认。
   - 海蓝渐变：蓝 → 青。
   - 极光渐变：绿 → 蓝 → 紫。
   - 石墨白：白 → 浅灰，适合深色背景。
   - 自定义。
3. 当用户选择“自定义”时，显示三个 Color Picker：
   - 起始颜色
   - 中间颜色
   - 结束颜色
4. 提供“恢复默认”按钮。

文案保持简短，强调“只影响边框，框内始终透明”。

## 交互规则

- 切换预设后立即保存并应用。
- 修改自定义颜色后立即保存并应用。
- 如果当前不是“自定义”，隐藏自定义颜色选择器。
- 选择“恢复默认”后回到活力渐变。
- 颜色设置只影响未来和正在进行的覆盖框绘制，不改变鼠标事件逻辑。

## 架构设计

### `OverlayStyle`

继续表示最终可绘制样式，包含：

- 边框宽度
- 圆角半径
- 外扩 inset
- 渐变颜色
- 渐变位置
- 渐变方向

### `OverlayStylePreset`

新增预设枚举：

- `vibrant`
- `ocean`
- `aurora`
- `graphite`
- `custom`

每个预设提供显示名称和默认颜色。

### `OverlayStyleSettings`

新增 `ObservableObject`，负责：

- 从 `UserDefaults` 读取当前预设和自定义颜色。
- 保存当前预设和自定义颜色。
- 根据当前配置生成 `OverlayStyle`。
- 通过 `onChange` 通知应用层刷新 overlay。

### `GradientBorderView`

将 `style` 从初始化后固定改为可更新。设置变化时更新 gradient layer，布局时继续只绘制描边 mask。

### `OverlayWindowController`

新增 `update(style:)`，把设置变化传递给 `GradientBorderView`。显示覆盖框时使用当前 style 的 `contentInset`。

### `AppDelegate`

持有 `OverlayStyleSettings`，注入：

- `OverlayWindowController`
- `SettingsWindowController`

当颜色设置变化时，调用 overlay 更新。

## 数据持久化

使用 `UserDefaults`：

- `dragFrame.overlayStyle.preset`
- `dragFrame.overlayStyle.customStartColor`
- `dragFrame.overlayStyle.customMiddleColor`
- `dragFrame.overlayStyle.customEndColor`

颜色以 8 位十六进制 RGBA 字符串保存，例如 `#FF3366FF`。

## 错误处理

- 无效预设 ID：回退到活力渐变并覆盖旧值。
- 无效颜色字符串：使用默认自定义颜色。
- 保存失败不阻止主功能，下一次启动仍使用可解析配置。

## 测试策略

### 自动测试

本轮颜色设置在 AppKit app target 中，核心拖拽状态机测试不受影响。执行现有 XCTest，确保拖拽行为不回归。

### 手动验证

- 设置页能切换四个内置预设。
- 选择“自定义”后，三个颜色选择器出现。
- 修改任意自定义颜色后，预览立即变化。
- 拖动时 overlay 使用当前颜色。
- 退出并重启后颜色设置保留。
- 框内仍完全透明。

## 验收标准

- 默认用户仍看到原来的活力渐变。
- 用户可从设置中选择预设颜色。
- 用户可自定义三色渐变。
- 设置页有清晰预览。
- Overlay 内部透明，不出现背景覆盖。
- 测试通过，文档更新。
