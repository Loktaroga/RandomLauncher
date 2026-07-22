import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 受控设备、无密码：禁止系统自动锁屏/息屏，屏幕常亮即视为“已解锁”。
        application.isIdleTimerDisabled = true
        return true
    }

    // iOS 13+ 场景生命周期：返回 Info.plist 中声明的 Scene 配置。
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 清理被丢弃的场景会话（多窗口场景用，这里保持空实现即可）。
    }
}
