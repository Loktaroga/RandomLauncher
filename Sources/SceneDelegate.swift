import UIKit

/// 标准 UIScene 生命周期接管者：负责创建 window 与根视图控制器。
/// 缺少它会直接导致系统“Scene update failed / Client process exited”而闪退。
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window

        // 受控设备、无密码：禁止系统自动锁屏/息屏，屏幕常亮即视为“已解锁”。
        UIApplication.shared.isIdleTimerDisabled = true
    }

    /// 处理 randomlauncher:// 回跳：系统已把本 App 带到前台，无需额外动作。
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // 回跳到本 App 后，Launcher 的计时逻辑仍由 AppDelegate 持有的 Launcher.shared 驱动。
    }
}
