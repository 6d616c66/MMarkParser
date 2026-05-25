import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let streamVC = StreamViewController()
        streamVC.title = "流式"
        let streamNav = UINavigationController(rootViewController: streamVC)
        streamNav.tabBarItem = UITabBarItem(title: "流式", image: UIImage(systemName: "waveform"), tag: 0)

        let staticVC = ViewController()
        staticVC.title = "静态渲染"
        let staticNav = UINavigationController(rootViewController: staticVC)
        staticNav.tabBarItem = UITabBarItem(title: "静态渲染", image: UIImage(systemName: "doc.text"), tag: 1)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [streamNav, staticNav]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
    }
}
