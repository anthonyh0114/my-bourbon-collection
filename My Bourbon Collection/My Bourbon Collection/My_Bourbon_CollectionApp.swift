//
//  My_Bourbon_CollectionApp.swift
//  My Bourbon Collection
//
//  Created by Tony Hill on 4/19/25.
//  Revised by Tony Hill on 4/15/25.
//

import UIKit

@main
class My_Bourbon_CollectionApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate: Application did finish launching")
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .systemBackground
        
        // Create initial view controller
        let bourbonListVC = BourbonListViewController()
        let navigationController = UINavigationController(rootViewController: bourbonListVC)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemBrown
        
        // Set root view controller
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("AppDelegate: Window setup complete")
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("AppDelegate: Configuring scene")
        let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("AppDelegate: Discarding scene sessions")
    }
}
