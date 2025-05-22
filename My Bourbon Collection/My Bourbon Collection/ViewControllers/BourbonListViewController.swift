//
//  BourbonListViewController.swift
//  My Bourbon Collection
//
//  Created by Tony Hill on 4/19/25.
//


import UIKit
import CoreLocation

class BourbonListViewController: UIViewController {
    private let tableView = UITableView()
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let headerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let sortButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let layoutToggleButton = UIButton(type: .system)
    private let helpButton = UIButton(type: .system)
    private let buttonStackView = UIStackView()
    private var bourbons: [Bourbon] = []
    private var currentSortOption: SortOption = .nameAscending
    private let welcomeView = UIView()
    private let welcomeLabel = UILabel()
    private let welcomeSubLabel = UILabel()
    private var isGridView = false
    private var currentGridScale: CGFloat = 1.0
    private let minGridScale: CGFloat = 0.5
    private let maxGridScale: CGFloat = 2.0
    private var pinchGesture: UIPinchGestureRecognizer?
    
    private enum SortOption {
        case nameAscending
        case nameDescending
        case proofAscending
        case proofDescending
        case ageAscending
        case ageDescending
        case dateAscending
        case dateDescending
        case ratingAscending
        case ratingDescending
        
        var title: String {
            switch self {
            case .nameAscending: return "Name (A-Z)"
            case .nameDescending: return "Name (Z-A)"
            case .proofAscending: return "Proof (Low to High)"
            case .proofDescending: return "Proof (High to Low)"
            case .ageAscending: return "Age (Youngest)"
            case .ageDescending: return "Age (Oldest)"
            case .dateAscending: return "Purchase Date (Oldest)"
            case .dateDescending: return "Purchase Date (Newest)"
            case .ratingAscending: return "Rating (Low to High)"
            case .ratingDescending: return "Rating (High to Low)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("BourbonListViewController: viewDidLoad")
        print("BourbonListViewController: View frame: \(view.frame)")
        print("BourbonListViewController: View bounds: \(view.bounds)")
        print("BourbonListViewController: Navigation controller: \(String(describing: navigationController))")
        
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupPinchGesture()
        loadBourbons()
        
        // Add observer for database changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBourbonCollectionDidChange),
            name: .bourbonCollectionDidChange,
            object: nil
        )
        
        // Setup help button after everything else
        setupHelpButton()
    }
    
    @objc private func handleBourbonCollectionDidChange() {
        loadBourbons()
    }
    
    private func setupNavigationBar() {
        // Remove the existing help button from navigation bar
        navigationItem.rightBarButtonItem = nil
    }
    
    @objc private func helpButtonTapped() {
        let helpVC = HelpViewController()
        let navController = UINavigationController(rootViewController: helpVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }
    
    private func setupUI() {
        print("BourbonListViewController: Setting up UI")
        view.backgroundColor = .systemBackground
        
        // Header Image
        if let headerImage = UIImage(named: "bourbon_header.jpg") {
            print("BourbonListViewController: Successfully loaded header image")
            headerImageView.image = headerImage
        } else {
            print("BourbonListViewController: Warning: Could not load bourbon_header.jpg")
            print("BourbonListViewController: Available images in bundle: \(Bundle.main.paths(forResourcesOfType: "jpg", inDirectory: nil))")
            headerImageView.backgroundColor = .systemGray6
        }
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.backgroundColor = .systemGray6
        view.addSubview(headerImageView)
        print("BourbonListViewController: Added header image view")
        
        // Title Label
        titleLabel.text = "My Bourbon Collection"
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
        print("BourbonListViewController: Added title label")
        
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
        welcomeSubLabel.text = "Inspired by Col Wood's passion for bourbon, start your collection by adding your first bottle. Track your favorites, discover new ones, and build your perfect collection."
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
        tableView.register(BourbonCell.self, forCellReuseIdentifier: "BourbonCell")
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 80
        tableView.isHidden = false
        tableView.alpha = 1.0
        view.addSubview(tableView)
        print("BourbonListViewController: Added table view")
        
        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BourbonGridCell.self, forCellWithReuseIdentifier: "BourbonGridCell")
        collectionView.backgroundColor = .systemBackground
        collectionView.isHidden = true
        collectionView.alpha = 0
        view.addSubview(collectionView)
        print("BourbonListViewController: Added collection view")
        
        // Add Button (FAB)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 28
        addButton.addTarget(self, action: #selector(addBourbon), for: .touchUpInside)
        view.addSubview(addButton)
        print("BourbonListViewController: Added floating action button")
        
        setupConstraints()
        print("BourbonListViewController: UI setup complete")
        
        // Force layout update
        view.layoutIfNeeded()
        print("BourbonListViewController: Final view frame: \(view.frame)")
        print("BourbonListViewController: Final view bounds: \(view.bounds)")
        print("BourbonListViewController: Final table view frame: \(tableView.frame)")
    }
    
    private func setupConstraints() {
        print("BourbonListViewController: Setting up constraints")
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
        print("BourbonListViewController: Constraints activated")
    }
    
    private func setupKeyboardHandling() {
        // Add observers for keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("BourbonListViewController: viewWillAppear")
        print("BourbonListViewController: View frame: \(view.frame)")
        print("BourbonListViewController: View bounds: \(view.bounds)")
        print("BourbonListViewController: View window: \(String(describing: view.window))")
        print("BourbonListViewController: Navigation controller: \(String(describing: navigationController))")
        
        loadBourbons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("BourbonListViewController: viewDidAppear")
        print("BourbonListViewController: View frame: \(view.frame)")
        print("BourbonListViewController: View bounds: \(view.bounds)")
        print("BourbonListViewController: View window: \(String(describing: view.window))")
        print("BourbonListViewController: Navigation controller: \(String(describing: navigationController))")
        print("BourbonListViewController: Table view frame: \(tableView.frame)")
        print("BourbonListViewController: Table view bounds: \(tableView.bounds)")
        print("BourbonListViewController: Table view visible: \(tableView.isHidden ? "No" : "Yes")")
        print("BourbonListViewController: Table view alpha: \(tableView.alpha)")
        print("BourbonListViewController: Help button frame: \(helpButton.frame)")
        print("BourbonListViewController: Help button is hidden: \(helpButton.isHidden)")
        print("BourbonListViewController: Help button alpha: \(helpButton.alpha)")
        print("BourbonListViewController: Help button superview: \(String(describing: helpButton.superview))")
        
        // Ensure help button is visible
        if helpButton.superview == nil {
            setupHelpButton()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("BourbonListViewController: viewDidLayoutSubviews")
        print("BourbonListViewController: Table view frame: \(tableView.frame)")
        print("BourbonListViewController: Table view bounds: \(tableView.bounds)")
        print("BourbonListViewController: Table view content size: \(tableView.contentSize)")
        print("BourbonListViewController: Table view is hidden: \(tableView.isHidden)")
        print("BourbonListViewController: Table view alpha: \(tableView.alpha)")
        print("BourbonListViewController: Table view background color: \(String(describing: tableView.backgroundColor))")
        print("BourbonListViewController: Help button frame: \(helpButton.frame)")
        print("BourbonListViewController: Help button is hidden: \(helpButton.isHidden)")
        print("BourbonListViewController: Help button alpha: \(helpButton.alpha)")
        print("BourbonListViewController: Help button superview: \(String(describing: helpButton.superview))")
    }
    
    private func loadBourbons() {
        print("BourbonListViewController: Starting to load bourbons")
        
        // Show loading state
        welcomeView.isHidden = true
        tableView.isHidden = true
        collectionView.isHidden = true
        buttonStackView.alpha = 0
        
        // Load bourbons on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            print("BourbonListViewController: Loading bourbons from database on background thread")
            let bourbons = BourbonDatabase.shared.getAllBourbons()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                print("BourbonListViewController: Updating UI with \(bourbons.count) bourbons")
                self.bourbons = bourbons
                self.sortBourbons(by: self.currentSortOption)
                
                // Show/hide welcome view based on collection status
                let isEmpty = bourbons.isEmpty
                self.welcomeView.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty || self.isGridView
                self.collectionView.isHidden = isEmpty || !self.isGridView
                
                // Show/hide buttons based on collection status
                UIView.animate(withDuration: 0.3) {
                    self.buttonStackView.alpha = isEmpty ? 0 : 1
                    self.sortButton.isEnabled = !isEmpty
                    self.searchButton.isEnabled = !isEmpty
                    self.layoutToggleButton.isEnabled = !isEmpty
                }
                
                // Only reload if we have data
                if !isEmpty {
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                }
                
                print("BourbonListViewController: UI update complete")
            }
        }
    }
    
    @objc private func addBourbon() {
        let categoryVC = AddBourbonCategoryViewController()
        present(UINavigationController(rootViewController: categoryVC), animated: true)
    }
    
    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Name (A-Z)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .nameAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Name (Z-A)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .nameDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Proof (Low to High)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .proofAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Proof (High to Low)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .proofDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Age (Youngest)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .ageAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Age (Oldest)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .ageDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Purchase Date (Newest)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .dateDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Purchase Date (Oldest)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .dateAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Rating (High to Low)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .ratingDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Rating (Low to High)", style: .default) { [weak self] _ in
            self?.sortBourbons(by: .ratingAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Reset", style: .default) { [weak self] _ in
            self?.resetSort()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure popover presentation for iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sortButton
            popoverController.sourceRect = sortButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func resetSort() {
        bourbons = BourbonDatabase.shared.getAllBourbons()
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    private func sortBourbons(by option: SortOption) {
        currentSortOption = option
        
        let sortedBourbons = bourbons.sorted { bourbon1, bourbon2 in
            switch option {
            case .nameAscending:
                return bourbon1.name < bourbon2.name
            case .nameDescending:
                return bourbon1.name > bourbon2.name
            case .proofAscending:
                return bourbon1.proof < bourbon2.proof
            case .proofDescending:
                return bourbon1.proof > bourbon2.proof
            case .ageAscending:
                // Handle age sorting for both numeric and NAS values
                let age1 = bourbon1.age.lowercased()
                let age2 = bourbon2.age.lowercased()
                
                // If both are numeric, compare as numbers
                if let num1 = Int(age1), let num2 = Int(age2) {
                    return num1 < num2
                }
                
                // If only one is numeric, numeric comes first
                if let _ = Int(age1) {
                    return true
                }
                if let _ = Int(age2) {
                    return false
                }
                
                // If both are non-numeric (like NAS), sort alphabetically
                return age1 < age2
                
            case .ageDescending:
                // Handle age sorting for both numeric and NAS values
                let age1 = bourbon1.age.lowercased()
                let age2 = bourbon2.age.lowercased()
                
                // If both are numeric, compare as numbers
                if let num1 = Int(age1), let num2 = Int(age2) {
                    return num1 > num2
                }
                
                // If only one is numeric, numeric comes first
                if let _ = Int(age1) {
                    return true
                }
                if let _ = Int(age2) {
                    return false
                }
                
                // If both are non-numeric (like NAS), sort alphabetically
                return age1 > age2
                
            case .dateAscending:
                return bourbon1.purchaseDate < bourbon2.purchaseDate
            case .dateDescending:
                return bourbon1.purchaseDate > bourbon2.purchaseDate
            case .ratingAscending:
                return bourbon1.rating < bourbon2.rating
            case .ratingDescending:
                return bourbon1.rating > bourbon2.rating
            }
        }
        
        bourbons = sortedBourbons
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    @objc private func searchButtonTapped() {
        let searchVC = SearchBourbonViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    private func setupPinchGesture() {
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        if let pinchGesture = pinchGesture {
            collectionView.addGestureRecognizer(pinchGesture)
        }
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
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
    
    @objc private func toggleLayout() {
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
    
    private func setupHelpButton() {
        print("Setting up help button...")
        
        // Remove from superview if it exists
        helpButton.removeFromSuperview()
        
        // Configure the button
        helpButton.setImage(UIImage(systemName: "questionmark.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        ), for: .normal)
        helpButton.tintColor = .white
        helpButton.backgroundColor = .systemBlue
        helpButton.layer.cornerRadius = 22
        helpButton.layer.shadowColor = UIColor.black.cgColor
        helpButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        helpButton.layer.shadowOpacity = 0.3
        helpButton.layer.shadowRadius = 4
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view first
        view.addSubview(helpButton)
        
        // Set constraints immediately since we know the view hierarchy is ready
        NSLayoutConstraint.activate([
            helpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            helpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            helpButton.widthAnchor.constraint(equalToConstant: 44),
            helpButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Force layout
        helpButton.layoutIfNeeded()
        print("Help button frame: \(helpButton.frame)")
        print("Help button is hidden: \(helpButton.isHidden)")
        print("Help button alpha: \(helpButton.alpha)")
        print("Help button superview: \(String(describing: helpButton.superview))")
    }
}

extension BourbonListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bourbons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("BourbonListViewController: Creating cell for row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "BourbonCell", for: indexPath) as! BourbonCell
        let bourbon = bourbons[indexPath.row]
        print("BourbonListViewController: Configuring cell with bourbon: \(bourbon.name)")
        cell.configure(with: bourbon)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bourbon = bourbons[indexPath.row]
        let detailVC = BourbonDetailViewController(bourbon: bourbon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // Add swipe-to-delete functionality
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            let bourbon = self.bourbons[indexPath.row]
            
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Delete Bourbon",
                message: "Are you sure you want to delete '\(bourbon.name)'? This action cannot be undone.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Delete from database
                if BourbonDatabase.shared.deleteBourbon(id: bourbon.id ?? 0) {
                    // Remove from array
                    self.bourbons.remove(at: indexPath.row)
                    
                    // Delete the row with animation
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    // Update UI if collection is now empty
                    if self.bourbons.isEmpty {
                        UIView.animate(withDuration: 0.3) {
                            self.welcomeView.isHidden = false
                            self.tableView.isHidden = true
                            self.collectionView.isHidden = true
                            self.buttonStackView.alpha = 0
                        }
                    }
                    
                    completion(true)
                } else {
                    // Show error if deletion failed
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to delete bourbon. Please try again.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                    completion(false)
                }
            })
            
            self.present(alert, animated: true)
        }
        
        // Customize the delete action appearance
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = UIColor.systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension BourbonListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bourbons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BourbonGridCell", for: indexPath) as! BourbonGridCell
        let bourbon = bourbons[indexPath.item]
        cell.configure(with: bourbon)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let baseWidth = (collectionView.bounds.width - 48) / 2 // 2 columns with padding
        let scaledWidth = baseWidth * currentGridScale
        return CGSize(width: scaledWidth, height: scaledWidth * 1.4) // Reduced from 1.6 to make cells more compact
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = 16 * currentGridScale
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacing: CGFloat) -> CGFloat {
        return 12 * currentGridScale // Reduced from 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacing: CGFloat) -> CGFloat {
        return 12 * currentGridScale // Reduced from 16
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bourbon = bourbons[indexPath.item]
        let detailVC = BourbonDetailViewController(bourbon: bourbon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // Add swipe-to-delete functionality for collection view
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                guard let self = self else { return }
                
                let bourbon = self.bourbons[indexPath.item]
                
                // Show confirmation alert
                let alert = UIAlertController(
                    title: "Delete Bourbon",
                    message: "Are you sure you want to delete '\(bourbon.name)'? This action cannot be undone.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    // Delete from database
                    if BourbonDatabase.shared.deleteBourbon(id: bourbon.id ?? 0) {
                        // Remove from array
                        self.bourbons.remove(at: indexPath.item)
                        
                        // Delete the item with animation
                        collectionView.deleteItems(at: [indexPath])
                        
                        // Update UI if collection is now empty
                        if self.bourbons.isEmpty {
                            UIView.animate(withDuration: 0.3) {
                                self.welcomeView.isHidden = false
                                self.tableView.isHidden = true
                                self.collectionView.isHidden = true
                                self.buttonStackView.alpha = 0
                            }
                        }
                    } else {
                        // Show error if deletion failed
                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Failed to delete bourbon. Please try again.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                })
                
                self.present(alert, animated: true)
            }
            
            return UIMenu(children: [deleteAction])
        }
    }
}

extension BourbonListViewController: AddBourbonViewControllerDelegate {
    func addBourbonViewControllerDidAddBourbon(_ controller: AddBourbonViewController) {
        loadBourbons()
    }
}

class BourbonCell: UITableViewCell {
    static let reuseIdentifier = "BourbonCell"
    
    private let bourbonImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let ratingLabel = UILabel()
    private let placeholderImage = UIImage(named: "placeholder")
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Image View
        bourbonImageView.contentMode = .scaleAspectFill
        bourbonImageView.clipsToBounds = true
        bourbonImageView.layer.cornerRadius = 8
        bourbonImageView.backgroundColor = .systemGray6
        contentView.addSubview(bourbonImageView)
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        
        // Details Label
        detailsLabel.font = .systemFont(ofSize: 14)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 2
        contentView.addSubview(detailsLabel)
        
        // Rating Label
        ratingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        ratingLabel.textAlignment = .right
        contentView.addSubview(ratingLabel)
        
        // Constraints
        bourbonImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bourbonImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bourbonImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bourbonImageView.widthAnchor.constraint(equalToConstant: 40),
            bourbonImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: bourbonImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            ratingLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            ratingLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailsLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with bourbon: Bourbon) {
        print("BourbonCell: Configuring with bourbon: \(bourbon.name)")
        nameLabel.text = bourbon.name
        
        // Format the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: bourbon.purchaseDate)
        
        // Create the details text with just proof and purchase date
        let detailsText = "\(bourbon.proof) proof • Purchased \(dateString)"
        detailsLabel.text = detailsText
        
        // Update rating with emoji only
        let ratingText: String
        switch bourbon.rating {
        case 1:
            ratingText = "👎"
        case 2:
            ratingText = "👌"
        case 3:
            ratingText = "👍"
        default:
            ratingText = "Not Rated"
        }
        ratingLabel.text = ratingText
        
        if let image = ImageService.shared.loadImage(filename: bourbon.imageFilename) {
            print("BourbonCell: Successfully loaded image for \(bourbon.name)")
            bourbonImageView.image = image
        } else {
            print("BourbonCell: Using placeholder image for \(bourbon.name)")
            bourbonImageView.image = placeholderImage
            bourbonImageView.tintColor = .systemGray3
        }
    }
}

class BourbonGridCell: UICollectionViewCell {
    private let bourbonImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let ratingLabel = UILabel()
    private let placeholderImage = UIImage(named: "placeholder")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Image View
        bourbonImageView.contentMode = .scaleAspectFill
        bourbonImageView.clipsToBounds = true
        bourbonImageView.layer.cornerRadius = 8
        bourbonImageView.backgroundColor = .systemGray6
        contentView.addSubview(bourbonImageView)
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        
        // Details Label
        detailsLabel.font = .systemFont(ofSize: 12)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 2
        detailsLabel.textAlignment = .center
        contentView.addSubview(detailsLabel)
        
        // Rating Label
        ratingLabel.font = .systemFont(ofSize: 20)
        ratingLabel.textAlignment = .center
        contentView.addSubview(ratingLabel)
        
        // Constraints
        bourbonImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bourbonImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8), // Reduced from 12
            bourbonImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bourbonImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            bourbonImageView.heightAnchor.constraint(equalTo: bourbonImageView.widthAnchor, multiplier: 1.5),
            
            nameLabel.topAnchor.constraint(equalTo: bourbonImageView.bottomAnchor, constant: 4), // Reduced from 8
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4), // Reduced from 8
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4), // Reduced from 8
            
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2), // Reduced from 4
            detailsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4), // Reduced from 8
            detailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4), // Reduced from 8
            
            ratingLabel.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 4), // Reduced from 8
            ratingLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            ratingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8) // Reduced from 12
        ])
    }
    
    func configure(with bourbon: Bourbon) {
        nameLabel.text = bourbon.name
        
        // Format details
        var details: [String] = []
        if bourbon.proof > 0 {
            details.append("\(Int(bourbon.proof)) proof")
        }
        if !bourbon.age.isEmpty {
            details.append("\(bourbon.age) years")
        }
        if bourbon.price > 0 {
            details.append("$\(String(format: "%.2f", bourbon.price))")
        }
        detailsLabel.text = details.joined(separator: " • ")
        
        // Set rating
        let ratingEmoji: String
        switch bourbon.rating {
        case 1: ratingEmoji = "👎"
        case 2: ratingEmoji = "👌"
        case 3: ratingEmoji = "👍"
        default: ratingEmoji = "👎"
        }
        ratingLabel.text = ratingEmoji
        
        // Load image
        if let image = ImageService.shared.loadImage(filename: bourbon.imageFilename) {
            bourbonImageView.image = image
        } else {
            bourbonImageView.image = placeholderImage
            bourbonImageView.tintColor = .systemGray3
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bourbonImageView.image = nil
        nameLabel.text = nil
        detailsLabel.text = nil
        ratingLabel.text = nil
    }
} 
