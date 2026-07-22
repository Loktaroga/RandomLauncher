import Foundation
import UIKit

extension Date {
    fileprivate var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

/// 已安装 App 的简要信息。
struct InstalledApp {
    let name: String
    let bundleID: String
}

/// 负责：在 [start, end] 窗口内随机取若干时刻，到点用私有 API 拉起目标 app。
/// 支持「每天重复」与「拉起后停留一段时间再回到本 App」。
final class Launcher {

    static let shared = Launcher()

    /// 拉起目标 app 后，通过 URL Scheme 拉回本 App 所用的 Scheme（需在 Info.plist 注册）。
    static let selfScheme = "randomlauncher://"

    private var tickTimer: DispatchSourceTimer?
    private var scheduledTimes: [Date] = []
    private var scheduleDay = ""   // 当前 scheduledTimes 所属的日期（用于跨天判断）

    private var repeatDaily = false
    private var returnToSelf = false
    private var returnAfterSeconds: TimeInterval = 5
    private var start: Date = Date()
    private var end: Date = Date()
    private var count = 1
    private var bundleID = ""

    /// 开始排程。
    /// - Parameters:
    ///   - repeatDaily: 是否每天重复（跨天重置窗口内随机时刻）
    ///   - returnToSelf: 拉起目标 app 后是否自动回到本 App
    ///   - returnAfter: 拉起目标 app 后停留多少秒再回到本 App
    func schedule(start: Date, end: Date, count: Int, bundleID: String,
                  repeatDaily: Bool, returnToSelf: Bool, returnAfter: TimeInterval = 5) {
        cancel()
        self.start = start
        self.end = end
        self.count = count
        self.bundleID = bundleID
        self.repeatDaily = repeatDaily
        self.returnToSelf = returnToSelf
        self.returnAfterSeconds = max(returnAfter, 0)

        generateForDay(day: Date())
        startTicking()
    }

    /// 为指定日期生成当天窗口内的随机时刻（并丢弃已过去的时刻）。
    private func generateForDay(day: Date) {
        scheduledTimes.removeAll()
        guard end > start, count > 0 else { return }
        let span = end.timeIntervalSince(start)
        var times: [Date] = []
        for _ in 0..<count {
            let offset = TimeInterval.random(in: 0..<span)
            times.append(start.addingTimeInterval(offset))
        }
        let now = Date()
        scheduledTimes = times.filter { $0 > now }.sorted()
        scheduleDay = day.dayKey
    }

    private func startTicking() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in self?.tick() }
        timer.resume()
        tickTimer = timer
    }

    private func tick() {
        let now = Date()
        // 跨天则重置当天排程（仅「每天重复」模式）
        if repeatDaily, scheduleDay != "", now.dayKey != scheduleDay {
            generateForDay(day: now)
        }
        guard !scheduledTimes.isEmpty else { return }
        let due = scheduledTimes.filter { $0 <= now }
        guard !due.isEmpty else { return }

        for _ in due {
            _ = openApp(bundleIdentifier: bundleID)
        }
        scheduledTimes.removeAll { $0 <= now }

        if returnToSelf, returnAfterSeconds > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + returnAfterSeconds) { [weak self] in
                self?.returnToSelfApp()
            }
        }
    }

    func cancel() {
        tickTimer?.cancel()
        tickTimer = nil
        scheduledTimes.removeAll()
        scheduleDay = ""
    }

    var nextTimes: [Date] { scheduledTimes }
    var isRepeating: Bool { repeatDaily }

    /// 读取本机已安装 App 列表（私有 API，需 TrollStore entitlements）。
    /// 返回按名称排序的 (名称, bundleID)；非真机/无权限时返回空数组。
    static func installedApps() -> [InstalledApp] {
        guard let wsClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type else { return [] }
        let sel = NSSelectorFromString("defaultWorkspace")
        guard wsClass.responds(to: sel),
              let ws = wsClass.perform(sel)?.takeUnretainedValue() as? NSObject else { return [] }
        let allSel = NSSelectorFromString("allApplications")
        guard ws.responds(to: allSel),
              let raw = ws.perform(allSel)?.takeUnretainedValue() as? [NSObject] else { return [] }

        var result: [InstalledApp] = []
        for app in raw {
            let bidSel = NSSelectorFromString("bundleIdentifier")
            guard app.responds(to: bidSel),
                  let bid = app.perform(bidSel)?.takeUnretainedValue() as? String, !bid.isEmpty else { continue }
            let nameSel = NSSelectorFromString("localizedName")
            let name: String = app.responds(to: nameSel)
                ? (app.perform(nameSel)?.takeUnretainedValue() as? String ?? bid) : bid
            result.append(InstalledApp(name: name, bundleID: bid))
        }
        result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return result
    }

    /// 通过私有 LSApplicationWorkspace API 拉起其他 app。
    /// 该 API 在 iOS 上为私有，故用运行时查找，避免链接报错。
    @discardableResult
    func openApp(bundleIdentifier: String) -> Bool {
        guard let wsClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type else {
            return false
        }
        let defaultSel = NSSelectorFromString("defaultWorkspace")
        guard wsClass.responds(to: defaultSel) else { return false }
        guard let ws = wsClass.perform(defaultSel)?.takeUnretainedValue() as? NSObject else {
            return false
        }
        let openSel = NSSelectorFromString("openApplicationWithBundleID:")
        guard ws.responds(to: openSel) else { return false }
        let ret = ws.perform(openSel, with: bundleIdentifier)
        return ret != nil
    }

    /// 通过 URL Scheme 拉回本 App（需在 Info.plist 注册 randomlauncher scheme）。
    func returnToSelfApp() {
        guard let url = URL(string: Launcher.selfScheme) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
