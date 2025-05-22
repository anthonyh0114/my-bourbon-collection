import UIKit

class InfinityViewController: BaseCollectionViewController {
    private var infinityBottles: [Bourbon] = []
    private var currentSortOption: SortOption = .dateDescending
    
    private enum SortOption {
        case nameAscending
        case nameDescending
        case proofAscending
        case proofDescending
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
            case .dateAscending: return "Date (Oldest)"
            case .dateDescending: return "Date (Newest)"
            case .ratingAscending: return "Rating (Low to High)"
            case .ratingDescending: return "Rating (High to Low)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Infinity Bottles"
        
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
        
        // Load infinity bottles on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let infinityBottles = BourbonDatabase.shared.getAllBourbons().filter { $0.size == "Infinity" }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.infinityBottles = infinityBottles
                self.sortInfinityBottles(by: self.currentSortOption)
                
                // Show/hide welcome view based on collection status
                let isEmpty = infinityBottles.isEmpty
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
            self?.sortInfinityBottles(by: .nameAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Name (Z-A)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .nameDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Proof (Low to High)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .proofAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Proof (High to Low)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .proofDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Date (Newest)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .dateDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Date (Oldest)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .dateAscending)
        })
        
        alert.addAction(UIAlertAction(title: "Rating (High to Low)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .ratingDescending)
        })
        
        alert.addAction(UIAlertAction(title: "Rating (Low to High)", style: .default) { [weak self] _ in
            self?.sortInfinityBottles(by: .ratingAscending)
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
    
    private func sortInfinityBottles(by option: SortOption) {
        currentSortOption = option
        
        let sortedBottles = infinityBottles.sorted { bottle1, bottle2 in
            switch option {
            case .nameAscending:
                return bottle1.name < bottle2.name
            case .nameDescending:
                return bottle1.name > bottle2.name
            case .proofAscending:
                return bottle1.proof < bottle2.proof
            case .proofDescending:
                return bottle1.proof > bottle2.proof
            case .dateAscending:
                return bottle1.purchaseDate < bottle2.purchaseDate
            case .dateDescending:
                return bottle1.purchaseDate > bottle2.purchaseDate
            case .ratingAscending:
                return bottle1.rating < bottle2.rating
            case .ratingDescending:
                return bottle1.rating > bottle2.rating
            }
        }
        
        infinityBottles = sortedBottles
        tableView.reloadData()
        collectionView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension InfinityViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infinityBottles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BourbonCell", for: indexPath) as! BourbonCell
        let bottle = infinityBottles[indexPath.row]
        cell.configure(with: bottle)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bottle = infinityBottles[indexPath.row]
        let detailVC = BourbonDetailViewController(bourbon: bottle)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            let bottle = self.infinityBottles[indexPath.row]
            
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Delete Infinity Bottle",
                message: "Are you sure you want to delete '\(bottle.name)'? This action cannot be undone.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Delete from database
                if BourbonDatabase.shared.deleteBourbon(id: bottle.id ?? 0) {
                    // Remove from array
                    self.infinityBottles.remove(at: indexPath.row)
                    
                    // Delete the row with animation
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    // Update UI if collection is now empty
                    if self.infinityBottles.isEmpty {
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
                        message: "Failed to delete infinity bottle. Please try again.",
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
extension InfinityViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infinityBottles.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BourbonGridCell", for: indexPath) as! BourbonGridCell
        let bottle = infinityBottles[indexPath.item]
        cell.configure(with: bottle)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bottle = infinityBottles[indexPath.item]
        let detailVC = BourbonDetailViewController(bourbon: bottle)
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
                
                let bottle = self.infinityBottles[indexPath.item]
                
                // Show confirmation alert
                let alert = UIAlertController(
                    title: "Delete Infinity Bottle",
                    message: "Are you sure you want to delete '\(bottle.name)'? This action cannot be undone.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    // Delete from database
                    if BourbonDatabase.shared.deleteBourbon(id: bottle.id ?? 0) {
                        // Remove from array
                        self.infinityBottles.remove(at: indexPath.item)
                        
                        // Delete the item with animation
                        collectionView.deleteItems(at: [indexPath])
                        
                        // Update UI if collection is now empty
                        if self.infinityBottles.isEmpty {
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
                            message: "Failed to delete infinity bottle. Please try again.",
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