import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 受控设备、无密码：禁止系统自动锁屏/息屏，屏幕常亮即视为“已解锁”。
        application.isIdleTimerDisabled = true

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }

    /// 处理 URL Scheme 回调（如 randomlauncher://），用于「拉起后回到本 App」。
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }
}
