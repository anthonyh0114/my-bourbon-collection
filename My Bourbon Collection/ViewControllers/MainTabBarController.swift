import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // Purchases Tab
        let purchasesVC = PurchasesViewController()
        purchasesVC.tabBarItem = UITabBarItem(
            title: "Purchases",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )
        let purchasesNav = UINavigationController(rootViewController: purchasesVC)
        
        // Tastings Tab
        let tastingsVC = TastingsViewController()
        tastingsVC.tabBarItem = UITabBarItem(
            title: "Tastings",
            image: UIImage(systemName: "wineglass"),
            selectedImage: UIImage(systemName: "wineglass.fill")
        )
        let tastingsNav = UINavigationController(rootViewController: tastingsVC)
        
        // Infinity Tab
        let infinityVC = InfinityViewController()
        infinityVC.tabBarItem = UITabBarItem(
            title: "Infinity",
            image: UIImage(systemName: "infinity"),
            selectedImage: UIImage(systemName: "infinity.circle.fill")
        )
        let infinityNav = UINavigationController(rootViewController: infinityVC)
        
        // Settings Tab
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear.fill")
        )
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        viewControllers = [purchasesNav, tastingsNav, infinityNav, settingsNav]
    }
} 