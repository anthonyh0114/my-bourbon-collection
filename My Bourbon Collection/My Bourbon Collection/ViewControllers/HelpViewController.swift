import UIKit
import WebKit

class HelpViewController: UIViewController {
    private let webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGuide()
    }
    
    private func setupUI() {
        title = "Help & About"
        view.backgroundColor = .systemBackground
        
        // Setup web view
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }
    
    private func loadGuide() {
        activityIndicator.startAnimating()
        
        // Load the guide from the bundle
        if let guideURL = Bundle.main.url(forResource: "bourbon_collection_guide", withExtension: "html") {
            webView.loadFileURL(guideURL, allowingReadAccessTo: guideURL.deletingLastPathComponent())
        } else {
            // Fallback to loading from GitHub if not in bundle
            if let url = URL(string: "https://raw.githubusercontent.com/anthonyh0114/my-bourbon-collection/main/bourbon_collection_guide.html") {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

extension HelpViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        
        // Show error alert
        let alert = UIAlertController(
            title: "Error Loading Guide",
            message: "Unable to load the help guide. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
} 