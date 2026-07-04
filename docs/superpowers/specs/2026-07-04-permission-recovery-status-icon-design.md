# DragFrame 权限恢复与状态栏图标设计

## 背景

用户已经在 macOS 系统设置中给 DragFrame 授权输入监控，但应用仍无法显示拖拽方框。系统日志显示 TCC 拒绝原因是旧授权记录的 code requirement 与当前 `/Applications/DragFrame.app` 的签名不匹配。当前应用还存在一个可见性问题：状态栏按钮未点击时几乎不可见，点击后才出现深色圆点。

## 目标

1. 当输入监控权限或事件监听失败时，应用必须给用户一个可见、明确的恢复路径。
2. 菜单栏常驻图标必须在 macOS 状态栏上始终可见，并遵循系统深浅色适配。
3. 本机安装流程必须清理旧的 DragFrame 输入监控授权记录，重新签名、重新启动，让用户重新授予当前版本权限。

## 方案

### 权限与监听恢复

- 继续使用 `CGPreflightListenEventAccess()` 判断输入监控授权。
- 当 `CGEvent.tapCreate` 返回失败时，记录运行状态错误，并自动打开设置窗口。
- 设置窗口显示“授权看似存在但监听失败”的说明，引导用户关闭再重新开启 DragFrame 的输入监控权限。
- 成功建立监听后清除错误状态，菜单栏恢复就绪状态。

### 状态栏图标

- 不使用彩色 App 图标作为状态栏图标。
- 使用 SF Symbol `rectangle.dashed` / `exclamationmark.rectangle`，并设置 `isTemplate = true`。
- 由 macOS 根据状态栏背景自动渲染为白色或黑色，解决截图中未点击时不可见的问题。

### 本机安装恢复

- 使用 Apple Development 身份重新签名 `/Applications/DragFrame.app`。
- 执行 `tccutil reset ListenEvent com.vincent.dragframe` 清理旧授权绑定。
- 重启 DragFrame，让当前签名版本重新进入输入监控授权流程。

## 验证

- 单元测试全部通过。
- Release 构建成功并安装到 `/Applications/DragFrame.app`。
- `codesign --verify --deep --strict` 通过。
- 启动后如果权限未恢复，应自动显示设置窗口和菜单栏告警。
- 用户在系统设置中重新开启输入监控后，按住 `⇧⌥` 并拖动鼠标左键可显示透明内部、渐变粗边框方框。
