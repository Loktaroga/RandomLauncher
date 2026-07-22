# RandomLauncher（TrollStore 随机拉起 App）

在指定时间段内随机选一个（或多个）时刻，自动亮屏并拉起指定 App。
面向**受控设备 + 无密码 + TrollStore 安装**场景：屏幕常亮即视为已解锁，无需用户干预。

## 工作前提
- 设备 iOS ≤ 17.0（本机 iOS 15.7 ✅，TrollStore 支持）。
- 设备已安装 TrollStore（用 TrollInstallerX / TrollHelper 安装）。
- 设备**已关闭密码**：设置 → 面容/触控 ID 与密码 → 关闭密码。这样屏幕亮起即进入系统。
- 设备保持本 App 在前台运行（受控设备本就只跑它；拉起目标 App 后，如要再次触发需回到本 App）。

## 编译方式（云 Mac CI，无需本机 Mac）
代码在 Windows 上编写，推到 GitHub 后由 GitHub Actions 的远程 Mac 编译：

1. 把本目录推送到一个 GitHub 仓库。
2. 仓库 → Actions → 选择 `Build TrollStore IPA` → `Run workflow`。
3. 跑完后在 Artifacts 下载 `RandomLauncher.ipa`。
4. 把 IPA 用 AirDrop / 文件 App 传到 iPhone，用 **TrollStore** 打开安装。

> CI 里用 `xcodegen` 由 `project.yml` 生成 Xcode 工程，用 `ldid` 按 `App.entitlements`
> 伪造签名（TrollStore 不需要 Apple 证书），最后打成 IPA。

## 本地有 Mac 时（可选）
```bash
brew install xcodegen ldid
./build.sh
# 产物：RandomLauncher.ipa
```

## 使用
打开 App 后填写 / 设置：
- **开始时间 / 结束时间**：滚轮选择，定义每天的随机窗口。
- **每天重复（开关，默认开）**：开启后，每个自然日都会在该窗口内重新随机取触发时刻，
  实现「定一个时间区间，每天这个时间区间内都重复执行」。关闭则只在当日有效。
- **拉起后回到本 App（开关，默认开）+ 停留秒数**：开启后，每次拉起目标 App 停留指定秒数（默认 5，可调），通过
  `randomlauncher://` 这个 URL Scheme 把本 App 拉回前台，保证后续每天仍能继续触发。
- **触发次数**：窗口内随机触发几次（默认 1）。
- **目标 App**：从**本机已安装 App 列表**（UIPickerView 滚轮，私有 API `LSApplicationWorkspace.allApplications` 读取）直接选，自动填入 Bundle ID；下方 Bundle ID 框也可手填覆盖。点“开始排程”后立即生效。

常用 Bundle ID 参考：
- Safari：`com.apple.MobileSafari`
- 设置：`com.apple.Preferences`
- 微信：`com.tencent.xin`
- 抖音：`com.ss.iphone.ugc.Aweme`

## 实现要点
- `Launcher.swift`：用 `DispatchSourceTimer` 每秒 `tick()`。在窗口内随机取时刻，到点调用私有
  `LSApplicationWorkspace.openApplicationWithBundleIdentifier:` 拉起目标 App。
  开启「每天重复」时，检测到**跨天**（`dayKey` 变化）会自动 `generateForDay` 重置当天随机时刻，
  从而每个时段都重复执行。开启「回到本 App」则停留用户设定的秒数（默认 5，UI 可调）后调 `randomlauncher://` 拉回自身。
  `Launcher.installedApps()` 用私有 `LSApplicationWorkspace.allApplications` 读取本机 App 列表（名称 + Bundle ID），供 UI 选择。
- `AppDelegate.swift`：设 `isIdleTimerDisabled = true`，屏幕常亮；并实现 URL Scheme 回调。
- `App.entitlements`：`com.apple.private.security.container-required=false` 等，
  使 App 能以系统级身份调用私有 API。
- `project.yml`：已注册 `randomlauncher` URL Scheme，供「回到本 App」使用。

## 已知限制 / 可增强
- **「每天重复」依赖本 App 保持活跃**：iOS 沙盒下 App 被切到后台后计时会被挂起。
  因此「拉起后回到本 App」是每天循环的关键——它把本 App 拉回前台，使秒级 `tick()` 持续运行。
  若目标 App 不支持被切走（用户一直停留），本 App 会停在后台，跨天重置暂停，需手动切回。
- 真·无人值守（完全不碰设备）在 iOS 上无法 100% 保证，这是系统限制，非代码问题。
- 若拉起失败，尝试在 `App.entitlements` 中保留 `com.apple.private.MobileContainerManager.allowed`。
- 本工程为脚手架，未在真机/Xcode 实跑验证；CI 报错可贴日志继续迭代。
