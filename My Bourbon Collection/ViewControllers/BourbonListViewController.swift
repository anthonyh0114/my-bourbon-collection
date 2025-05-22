// Add at the top of the file, after the imports
extension Notification.Name {
    static let bourbonCollectionDidChange = Notification.Name("bourbonCollectionDidChange")
}

class BourbonListDataManager {
    private var bourbons: [Bourbon] = []
    private var currentSortOption: SortOption = .nameAscending
    private let database = BourbonDatabase.shared
    
    var count: Int {
        return bourbons.count
    }
    
    func bourbon(at index: Int) -> Bourbon? {
        guard index >= 0 && index < bourbons.count else { return nil }
        return bourbons[index]
    }
    
    func loadBourbons(completion: @escaping () -> Void) {
        print("BourbonListDataManager: Starting to load bourbons")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let loadedBourbons = self.database.getAllBourbons()
            print("BourbonListDataManager: Loaded \(loadedBourbons.count) bourbons")
            print("BourbonListDataManager: Bourbons: \(loadedBourbons.map { "\($0.name) (ID: \($0.id ?? 0))" }.joined(separator: ", "))")
            
            DispatchQueue.main.async {
                self.bourbons = loadedBourbons
                self.sortBourbons(by: self.currentSortOption)
                completion()
            }
        }
    }
    
    func sortBourbons(by option: SortOption) {
        print("BourbonListDataManager: Sorting bourbons by \(option)")
        currentSortOption = option
        
        bourbons.sort { bourbon1, bourbon2 in
            switch option {
            case .nameAscending:
                return bourbon1.name.lowercased() < bourbon2.name.lowercased()
            case .nameDescending:
                return bourbon1.name.lowercased() > bourbon2.name.lowercased()
            case .proofAscending:
                return bourbon1.proof < bourbon2.proof
            case .proofDescending:
                return bourbon1.proof > bourbon2.proof
            case .ageAscending:
                return bourbon1.age < bourbon2.age
            case .ageDescending:
                return bourbon1.age > bourbon2.age
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
        
        print("BourbonListDataManager: Sorted bourbons: \(bourbons.map { "\($0.name) (ID: \($0.id ?? 0))" }.joined(separator: ", "))")
    }
}

class BourbonListViewController: UIViewController {
    private var bourbons: [Bourbon] = []
    private let collectionView: UICollectionView
    private let headerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let sortButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let layoutToggleButton = UIButton(type: .system)
    private let buttonStackView = UIStackView()
    private let welcomeView = UIView()
    private let welcomeLabel = UILabel()
    private let welcomeSubLabel = UILabel()
    private var isGridView = false
    
    init() {
        // Create a list layout
        let layout = UICollectionViewCompositionalLayout { section, environment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(80))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .absolute(80))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                        subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 1
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            return section
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBourbonCollectionDidChange),
            name: .bourbonCollectionDidChange,
            object: nil
        )
    }
    
    @objc private func handleBourbonCollectionDidChange() {
        refreshData()
    }
    
    private func refreshData() {
        print("BourbonListViewController: Starting refresh")
        
        // Load data synchronously first
        let loadedBourbons = BourbonDatabase.shared.getAllBourbons()
        print("BourbonListViewController: Loaded \(loadedBourbons.count) bourbons")
        print("BourbonListViewController: Bourbons: \(loadedBourbons.map { "\($0.name) (ID: \($0.id ?? 0))" }.joined(separator: ", "))")
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.bourbons = loadedBourbons
            self.updateUI()
        }
    }
    
    private func updateUI() {
        print("BourbonListViewController: Updating UI with \(bourbons.count) bourbons")
        print("BourbonListViewController: Current bourbons: \(bourbons.map { "\($0.name) (ID: \($0.id ?? 0))" }.joined(separator: ", "))")
        
        // Update welcome view
        welcomeView.isHidden = !bourbons.isEmpty
        collectionView.isHidden = bourbons.isEmpty
        
        // Update buttons
        buttonStackView.alpha = bourbons.isEmpty ? 0 : 1
        sortButton.isEnabled = !bourbons.isEmpty
        searchButton.isEnabled = !bourbons.isEmpty
        layoutToggleButton.isEnabled = !bourbons.isEmpty
        
        // Reload collection view
        collectionView.reloadData()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BourbonCell.self, forCellWithReuseIdentifier: "BourbonCell")
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
    
    private func setupUI() {
        print("BourbonListViewController: Setting up UI")
        view.backgroundColor = .systemBackground
        
        // Header Image
        if let headerImage = UIImage(named: "bourbon_header.jpg") {
            headerImageView.image = headerImage
        } else {
            headerImageView.backgroundColor = .systemGray6
        }
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        view.addSubview(headerImageView)
        
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
        
        // Add Button (FAB)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 28
        addButton.addTarget(self, action: #selector(addBourbon), for: .touchUpInside)
        addButton.isEnabled = true
        addButton.isUserInteractionEnabled = true
        print("BourbonListViewController: Add button configured - enabled: \(addButton.isEnabled), userInteractionEnabled: \(addButton.isUserInteractionEnabled)")
        print("BourbonListViewController: Add button frame: \(addButton.frame), bounds: \(addButton.bounds)")
        print("BourbonListViewController: Add button is in view hierarchy: \(addButton.window != nil)")
        view.addSubview(addButton)
        print("BourbonListViewController: Added floating action button")
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeSubLabel.translatesAutoresizingMaskIntoConstraints = false
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
            
            collectionView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Add Button (FAB) constraints
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func addBourbon() {
        print("BourbonListViewController: Add button tapped")
        print("BourbonListViewController: Add button state - enabled: \(addButton.isEnabled), userInteractionEnabled: \(addButton.isUserInteractionEnabled)")
        print("BourbonListViewController: Add button frame: \(addButton.frame), bounds: \(addButton.bounds)")
        print("BourbonListViewController: Add button is in view hierarchy: \(addButton.window != nil)")
        
        let categoryVC = AddBourbonCategoryViewController()
        print("BourbonListViewController: Created AddBourbonCategoryViewController")
        let navController = UINavigationController(rootViewController: categoryVC)
        print("BourbonListViewController: Created navigation controller")
        present(navController, animated: true) {
            print("BourbonListViewController: Finished presenting AddBourbonCategoryViewController")
        }
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure popover presentation for iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sortButton
            popoverController.sourceRect = sortButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func sortBourbons(by option: SortOption) {
        bourbons.sort { bourbon1, bourbon2 in
            switch option {
            case .nameAscending:
                return bourbon1.name.lowercased() < bourbon2.name.lowercased()
            case .nameDescending:
                return bourbon1.name.lowercased() > bourbon2.name.lowercased()
            case .proofAscending:
                return bourbon1.proof < bourbon2.proof
            case .proofDescending:
                return bourbon1.proof > bourbon2.proof
            case .ageAscending:
                return bourbon1.age < bourbon2.age
            case .ageDescending:
                return bourbon1.age > bourbon2.age
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
        collectionView.reloadData()
    }
    
    @objc private func searchButtonTapped() {
        let searchVC = SearchBourbonViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension BourbonListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bourbons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BourbonCell", for: indexPath) as! BourbonCell
        let bourbon = bourbons[indexPath.item]
        cell.configure(with: bourbon)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension BourbonListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bourbon = bourbons[indexPath.item]
        let detailVC = BourbonDetailViewController(bourbon: bourbon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
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

// MARK: - AddBourbonViewControllerDelegate
extension BourbonListViewController: AddBourbonViewControllerDelegate {
    func addBourbonViewControllerDidAddBourbon(_ controller: AddBourbonViewController) {
        refreshData()
    }
}

class BourbonCell: UICollectionViewCell {
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