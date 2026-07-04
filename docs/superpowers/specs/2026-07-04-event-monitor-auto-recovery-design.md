# Event Monitor Auto Recovery Design

## 背景

DragFrame 依赖 active `CGEventTap` 监听全局鼠标和修饰键事件。macOS 可能因为回调超时、用户输入保护、权限状态变化或签名变化临时禁用 event tap。当前实现会在收到 `tapDisabledByTimeout` 或 `tapDisabledByUserInput` 时尝试重新 enable，但不会重建 event tap，也没有连续失败分级。

本设计增加更稳健的事件监听自动恢复机制：先后台自愈，连续失败后再提示用户。

## 产品目标

- event tap 临时禁用时，DragFrame 优先自动恢复。
- 自动恢复成功时，不打扰用户。
- 连续恢复失败时，再进入警告状态并展示恢复说明。
- 用户暂停 DragFrame 时，不做自动恢复。
- 不改变拖拽框、快捷键、颜色、欢迎引导、登录项和底层事件吞噬规则。

## 非目标

本轮不做：

- 新权限入口或系统设置 UI。
- 崩溃日志上传。
- 后台守护进程。
- 改变 event tap 类型。
- 改变鼠标事件吞噬策略。

## 恢复策略

### 轻度恢复

当收到：

- `.tapDisabledByTimeout`
- `.tapDisabledByUserInput`

先尝试：

```swift
CGEvent.tapEnable(tap: eventTap, enable: true)
```

如果重新 enable 后 `CGEvent.tapIsEnabled(tap:) == true`，认为恢复成功。

### 中度恢复

如果轻度恢复失败，或启动时创建 event tap 失败，则延迟短暂时间后重建 event tap：

1. `stop()`
2. `start()`
3. 成功后清除错误状态

重建不在 `CGEventTap` callback 里直接执行，而是由应用层异步调度，避免在输入回调中做重工作。

### 重度失败

如果连续重建失败达到阈值，进入用户可见失败状态：

- 菜单栏显示警告
- 设置窗口显示恢复说明
- 不再无限快速重试

第一版阈值：

- `maxRestartAttempts = 3`
- `restartDelay = 0.35s`

## 架构设计

### `MonitorDisableReason`

新增禁用原因：

- `timeout`
- `userInput`

用于区分 macOS 禁用 event tap 的来源。

### `GlobalEventMonitor`

新增能力：

- `reenable() -> Bool`
- `restart() -> Bool`

收到 disabled event 时：

1. 尝试 `reenable()`
2. 将禁用原因和轻度恢复结果通知 delegate
3. 返回原事件，不吞事件

### `GlobalEventMonitorDelegate`

扩展回调：

```swift
func globalEventMonitor(
    _ monitor: GlobalEventMonitor,
    wasDisabled reason: MonitorDisableReason,
    recoveredByReenable: Bool
)
```

### `MonitorRecoveryState`

新增小状态模型，负责：

- 记录连续重启失败次数
- 判断是否达到提示阈值
- 在成功恢复后重置计数

### `DragCoordinator`

负责协调恢复：

- disabled event 到达时，先取消当前拖拽状态并隐藏 overlay
- 如果 `recoveredByReenable == true`，直接通知恢复成功
- 如果轻度恢复失败，异步调度 `monitor.restart()`
- 重启成功：通知恢复成功
- 重启失败且达到阈值：通知恢复失败
- 用户禁用 DragFrame 时取消恢复状态

### `AppDelegate` / `RuntimeStatus`

应用层只处理用户可见状态：

- 恢复成功：清除监听失败状态，状态回到已就绪
- 恢复失败：展示现有监听失败恢复说明
- 恢复过程中不弹窗，避免打扰

## 错误处理

- 无 event tap 可重新 enable：进入重建流程
- 重建失败未达阈值：保持后台恢复，不立刻弹窗
- 重建失败达到阈值：展示恢复说明
- 权限缺失：仍由现有权限状态处理，不走无限恢复

## 测试策略

### 自动测试

新增核心状态测试：

- 初始失败次数为 0
- 记录失败后次数增加
- 达到 3 次后 `shouldSurfaceFailure == true`
- 成功恢复后次数清零

现有拖拽状态机测试继续运行，确保行为不回归。

### 手动验证

- 正常启动后状态仍为已就绪。
- 拖拽框行为不变。
- 暂停 DragFrame 后不触发恢复。
- 权限缺失时仍显示权限提示。
- 如果 event tap 临时禁用，应用先尝试恢复，不立刻弹窗。

## 验收标准

- 临时禁用 event tap 时会先自动恢复。
- 连续恢复失败才显示用户可见错误。
- 恢复逻辑不会改变拖拽显示、事件吞噬、颜色设置和欢迎引导。
- 测试通过。
- README、开发文档和 roadmap 更新。
