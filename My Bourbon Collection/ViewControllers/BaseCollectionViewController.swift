import UIKit
import CoreLocation

class BaseCollectionViewController: UIViewController {
    // MARK: - UI Elements
    let tableView = UITableView()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    let headerImageView = UIImageView()
    let titleLabel = UILabel()
    let addButton = UIButton(type: .system)
    let sortButton = UIButton(type: .system)
    let searchButton = UIButton(type: .system)
    let layoutToggleButton = UIButton(type: .system)
    let buttonStackView = UIStackView()
    let welcomeView = UIView()
    let welcomeLabel = UILabel()
    let welcomeSubLabel = UILabel()
    
    // MARK: - Properties
    var isGridView = false
    var currentGridScale: CGFloat = 1.0
    private let minGridScale: CGFloat = 0.5
    private let maxGridScale: CGFloat = 2.0
    private var pinchGesture: UIPinchGestureRecognizer?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupPinchGesture()
        loadData()
        
        // Add observer for database changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCollectionDidChange),
            name: .bourbonCollectionDidChange,
            object: nil
        )
    }
    
    // MARK: - Setup Methods
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Header Image
        if let headerImage = UIImage(named: "bourbon_header.jpg") {
            headerImageView.image = headerImage
        } else {
            headerImageView.backgroundColor = .systemGray6
        }
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.backgroundColor = .systemGray6
        view.addSubview(headerImageView)
        
        // Title Label
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear
        
        // Add shadow to title
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowOpacity = 0.5
        titleLabel.layer.shadowRadius = 2
        
        view.addSubview(titleLabel)
        
        // Welcome View
        welcomeView.backgroundColor = .systemBackground
        welcomeView.isHidden = true
        view.addSubview(welcomeView)
        
        // Welcome Label
        welcomeLabel.text = "Welcome to Your Bourbon Journey"
        welcomeLabel.font = .systemFont(ofSize: 24, weight: .bold)
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0
        welcomeView.addSubview(welcomeLabel)
        
        // Welcome Sub Label
        welcomeSubLabel.text = "Inspired by Col Wood's passion for bourbon, start your collection by adding your first item. Track your favorites, discover new ones, and build your perfect collection."
        welcomeSubLabel.font = .systemFont(ofSize: 16)
        welcomeSubLabel.textAlignment = .center
        welcomeSubLabel.numberOfLines = 0
        welcomeSubLabel.textColor = .secondaryLabel
        welcomeView.addSubview(welcomeSubLabel)
        
        // Configure button stack view
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fill
        buttonStackView.spacing = 16
        view.addSubview(buttonStackView)
        
        // Create container views for sort and search buttons to ensure equal width
        let sortContainer = UIView()
        let searchContainer = UIView()
        
        // Sort Button
        var sortConfig = UIButton.Configuration.plain()
        sortConfig.image = UIImage(systemName: "arrow.up.arrow.down")
        sortConfig.baseForegroundColor = .systemBlue
        sortConfig.background.backgroundColor = .systemBackground
        sortConfig.cornerStyle = .medium
        sortConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        sortButton.configuration = sortConfig
        sortButton.layer.borderWidth = 1
        sortButton.layer.borderColor = UIColor.systemBlue.cgColor
        sortButton.layer.cornerRadius = 8
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        sortButton.alpha = 1
        sortButton.isEnabled = true
        sortContainer.addSubview(sortButton)
        buttonStackView.addArrangedSubview(sortContainer)
        
        // Layout Toggle Button
        var layoutConfig = UIButton.Configuration.plain()
        layoutConfig.image = UIImage(systemName: "square.grid.2x2")
        layoutConfig.baseForegroundColor = .systemBlue
        layoutConfig.background.backgroundColor = .systemBackground
        layoutConfig.cornerStyle = .medium
        layoutConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        layoutToggleButton.configuration = layoutConfig
        layoutToggleButton.layer.borderWidth = 1
        layoutToggleButton.layer.borderColor = UIColor.systemBlue.cgColor
        layoutToggleButton.layer.cornerRadius = 8
        layoutToggleButton.addTarget(self, action: #selector(toggleLayout), for: .touchUpInside)
        layoutToggleButton.alpha = 1
        layoutToggleButton.isEnabled = true
        layoutToggleButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        layoutToggleButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        buttonStackView.addArrangedSubview(layoutToggleButton)
        
        // Search Button
        var searchConfig = UIButton.Configuration.plain()
        searchConfig.image = UIImage(systemName: "magnifyingglass")
        searchConfig.baseForegroundColor = .systemBlue
        searchConfig.background.backgroundColor = .systemBackground
        searchConfig.cornerStyle = .medium
        searchConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        searchButton.configuration = searchConfig
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = UIColor.systemBlue.cgColor
        searchButton.layer.cornerRadius = 8
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchButton.alpha = 1
        searchButton.isEnabled = true
        searchContainer.addSubview(searchButton)
        buttonStackView.addArrangedSubview(searchContainer)
        
        // Set up constraints for the container views and buttons
        sortContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Make containers equal width
            sortContainer.widthAnchor.constraint(equalTo: searchContainer.widthAnchor),
            
            // Sort button fills its container
            sortButton.topAnchor.constraint(equalTo: sortContainer.topAnchor),
            sortButton.leadingAnchor.constraint(equalTo: sortContainer.leadingAnchor),
            sortButton.trailingAnchor.constraint(equalTo: sortContainer.trailingAnchor),
            sortButton.bottomAnchor.constraint(equalTo: sortContainer.bottomAnchor),
            
            // Search button fills its container
            searchButton.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchButton.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            searchButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            searchButton.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor)
        ])
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 80
        tableView.isHidden = false
        tableView.alpha = 1.0
        view.addSubview(tableView)
        
        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.isHidden = true
        collectionView.alpha = 0
        view.addSubview(collectionView)
        
        // Add Button (FAB)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 28
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        view.addSubview(addButton)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeSubLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        layoutToggleButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -4),
            
            buttonStackView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            
            welcomeView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            welcomeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            welcomeLabel.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: welcomeView.centerYAnchor, constant: -40),
            welcomeLabel.leadingAnchor.constraint(equalTo: welcomeView.leadingAnchor, constant: 32),
            welcomeLabel.trailingAnchor.constraint(equalTo: welcomeView.trailingAnchor, constant: -32),
            
            welcomeSubLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 16),
            welcomeSubLabel.leadingAnchor.constraint(equalTo: welcomeView.leadingAnchor, constant: 32),
            welcomeSubLabel.trailingAnchor.constraint(equalTo: welcomeView.trailingAnchor, constant: -32),
            
            tableView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Add Button (FAB) constraints
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56),
            
            collectionView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupNavigationBar() {
        // Remove the cancel button from navigation bar
        navigationItem.rightBarButtonItem = nil
    }
    
    func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupPinchGesture() {
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        if let pinchGesture = pinchGesture {
            collectionView.addGestureRecognizer(pinchGesture)
        }
    }
    
    // MARK: - Actions
    @objc func addButtonTapped() {
        // To be implemented by subclasses
    }
    
    @objc func sortButtonTapped() {
        // To be implemented by subclasses
    }
    
    @objc func searchButtonTapped() {
        // To be implemented by subclasses
    }
    
    @objc func toggleLayout() {
        isGridView.toggle()
        
        // Update button icon
        var layoutConfig = layoutToggleButton.configuration
        layoutConfig?.image = UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
        layoutToggleButton.configuration = layoutConfig
        
        // Reset grid scale when switching to grid view
        if isGridView {
            currentGridScale = 1.0
        }
        
        // Animate transition
        UIView.animate(withDuration: 0.3) {
            self.tableView.alpha = self.isGridView ? 0 : 1
            self.collectionView.alpha = self.isGridView ? 1 : 0
        } completion: { _ in
            self.tableView.isHidden = self.isGridView
            self.collectionView.isHidden = !self.isGridView
        }
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard isGridView else { return }
        
        switch gesture.state {
        case .changed:
            let newScale = currentGridScale * gesture.scale
            if newScale >= minGridScale && newScale <= maxGridScale {
                currentGridScale = newScale
                collectionView.collectionViewLayout.invalidateLayout()
            }
            gesture.scale = 1.0
            
        case .ended:
            // Animate to the final scale
            UIView.animate(withDuration: 0.3) {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            
        default:
            break
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
    
    @objc func handleCollectionDidChange() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        // To be implemented by subclasses
    }
    
    // MARK: - Memory Management
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension BaseCollectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 // To be implemented by subclasses
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() // To be implemented by subclasses
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension BaseCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0 // To be implemented by subclasses
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell() // To be implemented by subclasses
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let baseWidth = (collectionView.bounds.width - 48) / 2 // 2 columns with padding
        let scaledWidth = baseWidth * currentGridScale
        return CGSize(width: scaledWidth, height: scaledWidth * 1.5) // 3:2 aspect ratio
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = 16 * currentGridScale
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacing: CGFloat) -> CGFloat {
        return 16 * currentGridScale
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacing: CGFloat) -> CGFloat {
        return 16 * currentGridScale
    }
} 