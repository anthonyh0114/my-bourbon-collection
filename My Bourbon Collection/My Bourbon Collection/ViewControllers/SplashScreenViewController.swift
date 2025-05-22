import UIKit

class SplashScreenViewController: UIViewController {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateSplashScreen()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure we're using the full screen
        view.frame = view.window?.bounds ?? view.frame
    }
    
    private func setupUI() {
        // Set the background color to #e9e1d8
        view.backgroundColor = UIColor(red: 233/255, green: 225/255, blue: 216/255, alpha: 1.0)
        
        // Ignore safe areas
        if #available(iOS 11.0, *) {
            view.insetsLayoutMarginsFromSafeArea = false
        }
        
        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "title_image")
        view.addSubview(imageView)
        
        // Title Label
        titleLabel.text = "My Bourbon Collection"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        view.addSubview(titleLabel)
        
        // Constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Use the full screen for the image view
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Center the title label at the bottom
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
        ])
    }
    
    private func animateSplashScreen() {
        // Fade in the title label
        UIView.animate(withDuration: 1.0, delay: 0.5, options: .curveEaseIn) {
            self.titleLabel.alpha = 1.0
        }
        
        // Navigate to the main screen after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            let bourbonListVC = BourbonListViewController()
            let navigationController = UINavigationController(rootViewController: bourbonListVC)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .crossDissolve
            navigationController.view.alpha = 0
            
            self.present(navigationController, animated: false) {
                UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseOut) {
                    self.view.alpha = 0.0
                    navigationController.view.alpha = 1.0
                }
            }
        }
    }
} 
