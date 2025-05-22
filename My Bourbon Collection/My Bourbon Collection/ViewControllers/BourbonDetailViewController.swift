//
//  BourbonDetailViewController.swift
//  My Bourbon Collection
//
//  Created by Tony Hill on 4/19/25.
//


import UIKit

class BourbonDetailViewController: UIViewController {
    private var bourbon: Bourbon
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bourbonImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailsStackView = UIStackView()
    private let ratingLabel = UILabel()
    private let placeholderImage = UIImage(systemName: "wineglass")
    private let fillLevelSlider = UISlider()
    private let fillLevelLabel = UILabel()
    private let emptyLabel = UILabel()
    private let fullLabel = UILabel()
    private let sizeLabel = UILabel()
    
    init(bourbon: Bourbon) {
        self.bourbon = bourbon
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        deleteButton.tintColor = .systemRed
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        
        navigationItem.rightBarButtonItems = [deleteButton, editButton]
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Bourbon",
            message: "Are you sure you want to delete \(bourbon.name)? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteBourbon()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func editButtonTapped() {
        let editVC = EditBourbonViewController(bourbon: bourbon)
        editVC.editDelegate = self
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func deleteBourbon() {
        guard let bourbonId = bourbon.id else {
            showErrorAlert(message: "Invalid bourbon ID")
            return
        }
        
        print("Attempting to delete bourbon with ID: \(bourbonId)")
        if BourbonDatabase.shared.deleteBourbon(id: bourbonId) {
            print("Successfully deleted bourbon")
            navigationController?.popViewController(animated: true)
        } else {
            print("Failed to delete bourbon")
            showErrorAlert(message: "Failed to delete bourbon. Please try again.")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = bourbon.name
        
        // Scroll View
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Bourbon Image
        bourbonImageView.contentMode = .scaleAspectFit
        bourbonImageView.clipsToBounds = true
        bourbonImageView.layer.cornerRadius = 8
        bourbonImageView.backgroundColor = .systemGray6
        contentView.addSubview(bourbonImageView)
        
        // Name Label
        nameLabel.text = bourbon.name
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        contentView.addSubview(nameLabel)
        
        // Rating Label
        ratingLabel.font = .systemFont(ofSize: 20, weight: .medium)
        ratingLabel.textAlignment = .center
        contentView.addSubview(ratingLabel)
        
        // Details Stack View
        detailsStackView.axis = .vertical
        detailsStackView.spacing = 16
        detailsStackView.alignment = .leading
        contentView.addSubview(detailsStackView)
        
        // Check if this is a tasting
        let isTasting = bourbon.size == "Tasting"
        
        if isTasting {
            // Fields for tastings
            addDetailLabel(title: "Proof", value: "\(bourbon.proof)")
            addDetailLabel(title: "ABV", value: String(format: "%.1f%%", Double(bourbon.proof) / 2.0))
            if !bourbon.age.isEmpty {
                if let ageInt = Int(bourbon.age) {
                    addDetailLabel(title: "Age", value: "\(ageInt) year\(ageInt == 1 ? "" : "s")")
                } else {
                    addDetailLabel(title: "Age", value: bourbon.age)
                }
            }
            addDetailLabel(title: "Tasting Location", value: bourbon.purchaseLocation)
            addDetailLabel(title: "Flavor Profile", value: bourbon.flavorProfile)
            addDetailLabel(title: "Pour Price", value: String(format: "$%.2f", bourbon.price))
            addDetailLabel(title: "Tasting Date", value: formatDate(bourbon.purchaseDate))
            
            // Extract tasting type and flight details from notes if present
            let notesComponents = bourbon.notes.components(separatedBy: "\n\n")
            if notesComponents.count > 1 {
                for component in notesComponents {
                    if component.hasPrefix("Tasting Type:") {
                        addDetailLabel(title: "Tasting Type", value: component.replacingOccurrences(of: "Tasting Type: ", with: ""))
                    } else if component.hasPrefix("Flight Details:") {
                        addDetailLabel(title: "Flight Details", value: component.replacingOccurrences(of: "Flight Details: ", with: ""))
                    }
                }
            }
            
            // Add notes without the tasting type and flight details
            if let firstComponent = notesComponents.first {
                addDetailLabel(title: "Notes", value: firstComponent)
            }
        } else {
            // Fields for regular bourbons
        addDetailLabel(title: "Proof", value: "\(bourbon.proof)")
        addDetailLabel(title: "ABV", value: String(format: "%.1f%%", Double(bourbon.proof) / 2.0))
            if !bourbon.age.isEmpty {
                if let ageInt = Int(bourbon.age) {
                    addDetailLabel(title: "Age", value: "\(ageInt) year\(ageInt == 1 ? "" : "s")")
                } else {
                    addDetailLabel(title: "Age", value: bourbon.age)
                }
        }
        addDetailLabel(title: "Purchase Location", value: bourbon.purchaseLocation)
        addDetailLabel(title: "Flavor Profile", value: bourbon.flavorProfile)
        addDetailLabel(title: "Price", value: String(format: "$%.2f", bourbon.price))
        addDetailLabel(title: "Size", value: bourbon.size)
        addDetailLabel(title: "Purchase Date", value: formatDate(bourbon.purchaseDate))
        
        if let dateOpened = bourbon.dateOpened {
            addDetailLabel(title: "Date Opened", value: formatDate(dateOpened))
        }
        
        if let dateEmptied = bourbon.dateEmptied {
            addDetailLabel(title: "Date Emptied", value: formatDate(dateEmptied))
        }
        
        // Fill Level Section
        let fillLevelContainer = UIView()
        fillLevelContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let fillLevelTitleLabel = UILabel()
        fillLevelTitleLabel.text = "Fill Level"
        fillLevelTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        fillLevelTitleLabel.textColor = .secondaryLabel
        fillLevelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fillLevelLabel.text = getFillLevelText(bourbon.fillLevel)
        fillLevelLabel.font = .systemFont(ofSize: 16)
        fillLevelLabel.textColor = .label
        fillLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fillLevelSlider.minimumValue = 0
        fillLevelSlider.maximumValue = 100
        fillLevelSlider.value = Float(bourbon.fillLevel)
        fillLevelSlider.isEnabled = false
        fillLevelSlider.tintColor = bourbon.fillLevel <= 10 ? .systemRed : .systemBlue
        fillLevelSlider.translatesAutoresizingMaskIntoConstraints = false
        
        emptyLabel.text = "😢"
        emptyLabel.font = .systemFont(ofSize: 20)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fullLabel.text = "😊"
        fullLabel.font = .systemFont(ofSize: 20)
        fullLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fillLevelContainer.addSubview(fillLevelTitleLabel)
        fillLevelContainer.addSubview(fillLevelLabel)
        fillLevelContainer.addSubview(fillLevelSlider)
        fillLevelContainer.addSubview(emptyLabel)
        fillLevelContainer.addSubview(fullLabel)
        
        NSLayoutConstraint.activate([
            fillLevelTitleLabel.topAnchor.constraint(equalTo: fillLevelContainer.topAnchor),
            fillLevelTitleLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
            fillLevelTitleLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
            
            fillLevelLabel.topAnchor.constraint(equalTo: fillLevelTitleLabel.bottomAnchor, constant: 8),
            fillLevelLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
            fillLevelLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
            
            fillLevelSlider.topAnchor.constraint(equalTo: fillLevelLabel.bottomAnchor, constant: 8),
            fillLevelSlider.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
            fillLevelSlider.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
            
            emptyLabel.topAnchor.constraint(equalTo: fillLevelSlider.bottomAnchor, constant: 4),
            emptyLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
            
            fullLabel.topAnchor.constraint(equalTo: fillLevelSlider.bottomAnchor, constant: 4),
            fullLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
            
            fillLevelContainer.bottomAnchor.constraint(equalTo: fullLabel.bottomAnchor, constant: 8)
        ])
        
        detailsStackView.addArrangedSubview(fillLevelContainer)
        
        // Add width constraint to ensure container takes full width
        fillLevelContainer.widthAnchor.constraint(equalTo: detailsStackView.widthAnchor).isActive = true
        
        // Notes
        addDetailLabel(title: "Notes", value: bourbon.notes)
        }
        
        setupConstraints()
        loadImage()
        updateRatingLabel()
    }
    
    private func getFillLevelText(_ level: Int) -> String {
        if level == 0 {
            return "Fill Level: Empty"
        } else if level == 100 {
            return "Fill Level: Unopened"
        } else {
            return "Fill Level: \(level)%"
        }
    }
    
    private func updateRatingLabel() {
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
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        bourbonImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            bourbonImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            bourbonImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bourbonImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            bourbonImageView.heightAnchor.constraint(equalTo: bourbonImageView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: bourbonImageView.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            ratingLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            ratingLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            detailsStackView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 20),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            detailsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func addDetailLabel(title: String, value: String) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        detailsStackView.addArrangedSubview(container)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    private func loadImage() {
        if let image = loadImage(filename: bourbon.imageFilename) {
            bourbonImageView.image = image
        } else {
            bourbonImageView.image = placeholderImage
            bourbonImageView.tintColor = .systemGray3
        }
    }
    
    private func loadImage(filename: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension BourbonDetailViewController: EditBourbonViewControllerDelegate {
    func editBourbonViewControllerDidUpdateBourbon(_ controller: EditBourbonViewController) {
        // Reload the view with updated bourbon data
        if let updatedBourbon = BourbonDatabase.shared.getBourbon(id: bourbon.id!) {
            // Update the current bourbon with new data
            self.bourbon = updatedBourbon
            
            // Update UI
            title = bourbon.name
            nameLabel.text = bourbon.name
            loadImage()
            updateRatingLabel()
            
            // Clear and rebuild the details stack view
            detailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            // Rebuild all the detail labels
            addDetailLabel(title: "Proof", value: "\(bourbon.proof)")
            addDetailLabel(title: "ABV", value: String(format: "%.1f%%", Double(bourbon.proof) / 2.0))
            if !bourbon.age.isEmpty {
                if let ageInt = Int(bourbon.age) {
                    addDetailLabel(title: "Age", value: "\(ageInt) year\(ageInt == 1 ? "" : "s")")
                } else {
                    addDetailLabel(title: "Age", value: bourbon.age)
                }
            }
            addDetailLabel(title: "Purchase Location", value: bourbon.purchaseLocation)
            addDetailLabel(title: "Flavor Profile", value: bourbon.flavorProfile)
            addDetailLabel(title: "Price", value: String(format: "$%.2f", bourbon.price))
            addDetailLabel(title: "Size", value: bourbon.size)
            addDetailLabel(title: "Purchase Date", value: formatDate(bourbon.purchaseDate))
            
            if let dateOpened = bourbon.dateOpened {
                addDetailLabel(title: "Date Opened", value: formatDate(dateOpened))
            }
            
            if let dateEmptied = bourbon.dateEmptied {
                addDetailLabel(title: "Date Emptied", value: formatDate(dateEmptied))
            }
            
            // Fill Level Section
            let fillLevelContainer = UIView()
            fillLevelContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let fillLevelTitleLabel = UILabel()
            fillLevelTitleLabel.text = "Fill Level"
            fillLevelTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
            fillLevelTitleLabel.textColor = .secondaryLabel
            fillLevelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            fillLevelLabel.text = getFillLevelText(bourbon.fillLevel)
            fillLevelLabel.font = .systemFont(ofSize: 16)
            fillLevelLabel.textColor = .label
            fillLevelLabel.translatesAutoresizingMaskIntoConstraints = false
            
            fillLevelSlider.minimumValue = 0
            fillLevelSlider.maximumValue = 100
            fillLevelSlider.value = Float(bourbon.fillLevel)
            fillLevelSlider.isEnabled = false
            fillLevelSlider.tintColor = bourbon.fillLevel <= 10 ? .systemRed : .systemBlue
            fillLevelSlider.translatesAutoresizingMaskIntoConstraints = false
            
            emptyLabel.text = "😢"
            emptyLabel.font = .systemFont(ofSize: 20)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            
            fullLabel.text = "😊"
            fullLabel.font = .systemFont(ofSize: 20)
            fullLabel.translatesAutoresizingMaskIntoConstraints = false
            
            fillLevelContainer.addSubview(fillLevelTitleLabel)
            fillLevelContainer.addSubview(fillLevelLabel)
            fillLevelContainer.addSubview(fillLevelSlider)
            fillLevelContainer.addSubview(emptyLabel)
            fillLevelContainer.addSubview(fullLabel)
            
            NSLayoutConstraint.activate([
                fillLevelTitleLabel.topAnchor.constraint(equalTo: fillLevelContainer.topAnchor),
                fillLevelTitleLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
                fillLevelTitleLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
                
                fillLevelLabel.topAnchor.constraint(equalTo: fillLevelTitleLabel.bottomAnchor, constant: 8),
                fillLevelLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
                fillLevelLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
                
                fillLevelSlider.topAnchor.constraint(equalTo: fillLevelLabel.bottomAnchor, constant: 8),
                fillLevelSlider.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
                fillLevelSlider.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
                
                emptyLabel.topAnchor.constraint(equalTo: fillLevelSlider.bottomAnchor, constant: 4),
                emptyLabel.leadingAnchor.constraint(equalTo: fillLevelContainer.leadingAnchor, constant: 20),
                
                fullLabel.topAnchor.constraint(equalTo: fillLevelSlider.bottomAnchor, constant: 4),
                fullLabel.trailingAnchor.constraint(equalTo: fillLevelContainer.trailingAnchor, constant: -20),
                
                fillLevelContainer.bottomAnchor.constraint(equalTo: fullLabel.bottomAnchor, constant: 8)
            ])
            
            detailsStackView.addArrangedSubview(fillLevelContainer)
            
            // Add width constraint to ensure container takes full width
            fillLevelContainer.widthAnchor.constraint(equalTo: detailsStackView.widthAnchor).isActive = true
            
            // Notes
            addDetailLabel(title: "Notes", value: bourbon.notes)
        }
    }
} 
