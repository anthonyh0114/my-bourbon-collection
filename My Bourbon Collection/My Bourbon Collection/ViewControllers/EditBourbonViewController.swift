import UIKit
import PhotosUI
import ImageIO
import CoreLocation
import MapKit

protocol EditBourbonViewControllerDelegate: AnyObject {
    func editBourbonViewControllerDidUpdateBourbon(_ controller: EditBourbonViewController)
}

class EditBourbonViewController: AddBourbonViewController {
    weak var editDelegate: EditBourbonViewControllerDelegate?
    private let bourbon: Bourbon
    private var editImageButton: UIButton?
    
    init(bourbon: Bourbon) {
        self.bourbon = bourbon
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Bourbon"
        
        // Hide fields for tastings and infinity entries
        let isTasting = bourbon.size == "Tasting"
        let isInfinity = bourbon.size == "Infinity"
        
        if isTasting || isInfinity {
            dateOpenedLabel.isHidden = true
            dateOpenedPicker.isHidden = true
            dateEmptiedLabel.isHidden = true
            dateEmptiedPicker.isHidden = true
            fillLevelLabel.isHidden = true
            fillLevelSlider.isHidden = true
            emptyLabel.isHidden = true
            fullLabel.isHidden = true
            
            // Adjust rating control position to be right after purchase date picker
            ratingSegmentedControl.removeFromSuperview()
            contentView.addSubview(ratingSegmentedControl)
            
            NSLayoutConstraint.activate([
                ratingSegmentedControl.topAnchor.constraint(equalTo: purchaseDatePicker.bottomAnchor, constant: 16),
                ratingSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                ratingSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                ratingSegmentedControl.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            // Adjust notes position to be right after rating control
            notesTextView.removeFromSuperview()
            contentView.addSubview(notesTextView)
            
            NSLayoutConstraint.activate([
                notesTextView.topAnchor.constraint(equalTo: ratingSegmentedControl.bottomAnchor, constant: 16),
                notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                notesTextView.heightAnchor.constraint(equalToConstant: 100),
                notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        }
        
        // Ensure image view is properly configured
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        populateFields()
        setupLocationServices()
    }
    
    private func populateFields() {
        // Load existing image if available
        let imageFilename = bourbon.imageFilename
        if !imageFilename.isEmpty {
            if let image = ImageService.shared.loadImage(filename: imageFilename) {
                selectedImage = image
                imageView.image = image
            } else {
                imageView.image = UIImage(named: "placeholder")
            }
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
        
        // Populate other fields
        nameTextField.text = bourbon.name
        proofTextField.text = String(bourbon.proof)
        ageTextField.text = bourbon.age.isEmpty ? "" : bourbon.age
        purchaseLocationTextField.text = bourbon.purchaseLocation
        flavorProfileTextField.text = bourbon.flavorProfile
        notesTextView.text = bourbon.notes
        priceTextField.text = bourbon.price > 0 ? String(format: "%.2f", bourbon.price) : ""
        sizeTextField.text = bourbon.size
        purchaseDatePicker.date = bourbon.purchaseDate
        dateOpenedPicker.date = bourbon.dateOpened ?? Date()
        selectedDateOpened = bourbon.dateOpened
        selectedRating = bourbon.rating
        ratingSegmentedControl.selectedSegmentIndex = bourbon.rating
        fillLevelSlider.value = Float(bourbon.fillLevel)
        updateFillLevelLabel()
    }
    
    private func setupLocationServices() {
        // Add location button to purchase location field
                let locationButton = UIButton(type: .system)
                locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.addTarget(self, action: #selector(showLocationSelection), for: .touchUpInside)
        purchaseLocationTextField.rightView = locationButton
        purchaseLocationTextField.rightViewMode = .always
    }
    
    override func setupNavigationBar() {
        title = "Edit Bourbon"
        
        // Save button
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveBourbon))
        navigationItem.rightBarButtonItem = saveButton
        
        // Cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc override func saveBourbon() {
        // Validate required fields
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showErrorAlert(message: "Please enter a name for the bourbon")
            return
        }
        
        guard let proofText = proofTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !proofText.isEmpty,
              let proof = Double(proofText) else {
            showErrorAlert(message: "Please enter a valid proof")
            return
        }
        
        // Validate proof limits
        guard proof >= 80.0 && proof <= 160.0 else {
            showErrorAlert(message: "Proof must be between 80.0 and 160.0")
            return
        }
        
        // Disable save button while processing
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let purchaseLocation = purchaseLocationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let flavorProfile = flavorProfileTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let price = Double(priceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0.0
        let size = sizeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        var imageFilename = bourbon.imageFilename
        
        // If a new image was selected, save it
        if let newImage = selectedImage {
            imageFilename = "bourbon_\(UUID().uuidString).jpg"
            if !BourbonDatabase.shared.saveImage(newImage, filename: imageFilename) {
                navigationItem.rightBarButtonItem?.isEnabled = true
                showErrorAlert(message: "Failed to save image")
                return
            }
        }
        
        // Get current location if available
        var purchaseLocationLatitude: Double?
        var purchaseLocationLongitude: Double?
        
        if let location = LocationService.shared.currentLocation {
            purchaseLocationLatitude = location.coordinate.latitude
            purchaseLocationLongitude = location.coordinate.longitude
        } else {
            purchaseLocationLatitude = bourbon.purchaseLocationLatitude
            purchaseLocationLongitude = bourbon.purchaseLocationLongitude
        }
        
        print("EditBourbonViewController: Creating updated bourbon object")
        let updatedBourbon = Bourbon(
            id: bourbon.id,
            name: name,
            proof: proof,
            age: ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            purchaseDate: purchaseDatePicker.date,
            purchaseLocation: purchaseLocation,
            purchaseLocationLatitude: purchaseLocationLatitude,
            purchaseLocationLongitude: purchaseLocationLongitude,
            flavorProfile: flavorProfile,
            notes: notes,
            price: price,
            size: size,
            imageFilename: imageFilename,
            rating: selectedRating,
            fillLevel: bourbon.size == "Tasting" || bourbon.size == "Infinity" ? 0 : Int(fillLevelSlider.value),
            dateOpened: bourbon.size == "Tasting" || bourbon.size == "Infinity" ? nil : selectedDateOpened,
            dateEmptied: bourbon.size == "Tasting" || bourbon.size == "Infinity" ? nil : selectedDateEmptied
        )
        
        // Update database
        if BourbonDatabase.shared.updateBourbon(updatedBourbon) {
            // Notify delegate
            editDelegate?.editBourbonViewControllerDidUpdateBourbon(self)
            // Dismiss view controller
            dismiss(animated: true)
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            showErrorAlert(message: "Failed to update bourbon. Please try again.")
        }
    }
} 