//
//  SceneDelegate.swift
//  My Bourbon Collection
//
//  Created by Tony Hill on 4/19/25.
//
//  Updated by Tony Hill on 5/22/25.



import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("SceneDelegate: Setting up scene")
        guard let windowScene = (scene as? UIWindowScene) else {
            print("SceneDelegate: Failed to get window scene")
            return
        }
        
        print("SceneDelegate: Creating window")
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground
        
        print("SceneDelegate: Creating SplashScreenViewController")
        let splashScreenVC = SplashScreenViewController()
        
        print("SceneDelegate: Setting root view controller")
        window.rootViewController = splashScreenVC
        
        print("SceneDelegate: Making window key and visible")
        window.makeKeyAndVisible()
        
        print("SceneDelegate: Storing window reference")
        self.window = window
        
        // Force layout update
        window.layoutIfNeeded()
        print("SceneDelegate: Window frame: \(window.frame)")
        print("SceneDelegate: Window bounds: \(window.bounds)")
        print("SceneDelegate: SplashScreenViewController view frame: \(splashScreenVC.view.frame)")
    }
} 
