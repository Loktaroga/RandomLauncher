import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // 用 as! 替代 guard：如果 scene 不是 UIWindowScene 会直接崩溃
        // → 控制台能看到具体错误，不再无信息黑屏。
        let windowScene = scene as! UIWindowScene

        let w = UIWindow(windowScene: windowScene)
        w.backgroundColor = .systemBlue
        w.rootViewController = ViewController()
        w.makeKeyAndVisible()
        window = w
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {}
}
