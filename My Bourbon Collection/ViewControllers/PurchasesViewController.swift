import UIKit

class PurchasesViewController: BaseCollectionViewController {
    private var bourbons: [Bourbon] = []
    private var currentSortOption: SortOption = .nameAscending
    
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
        title = "Purchases"
        
        // Register cells
        tableView.register(BourbonCell.self, forCellReuseIdentifier: "BourbonCell")
        collectionView.register(BourbonGridCell.self, forCellWithReuseIdentifier: "BourbonGridCell")
    }
    
    override func loadData() {
        // Show loading state
        welcomeView.isHidden = true
        tableView.isHidden = true
        collectionView.isHidden = true
        buttonStackView.alpha = 0
        
        // Load bourbons on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let bourbons = BourbonDatabase.shared.getAllBourbons().filter { $0.size != "Tasting" }
            
            // Update UI on main thread
            DispatchQueue.main.async {
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
            }
        }
    }
    
    override func addButtonTapped() {
        let categoryVC = AddBourbonCategoryViewController()
        present(UINavigationController(rootViewController: categoryVC), animated: true)
    }
    
    override func sortButtonTapped() {
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
    
    override func searchButtonTapped() {
        let searchVC = SearchBourbonViewController()
        navigationController?.pushViewController(searchVC, animated: true)
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
        
        bourbons = sortedBourbons
        tableView.reloadData()
        collectionView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PurchasesViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bourbons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BourbonCell", for: indexPath) as! BourbonCell
        let bourbon = bourbons[indexPath.row]
        cell.configure(with: bourbon)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bourbon = bourbons[indexPath.row]
        let detailVC = BourbonDetailViewController(bourbon: bourbon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
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

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension PurchasesViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bourbons.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BourbonGridCell", for: indexPath) as! BourbonGridCell
        let bourbon = bourbons[indexPath.item]
        cell.configure(with: bourbon)
        return cell
    }
    
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