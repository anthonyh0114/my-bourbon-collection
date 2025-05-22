protocol AddBourbonViewControllerDelegate: AnyObject {
    func addBourbonViewControllerDidAddBourbon(_ controller: AddBourbonViewController)
}

class AddBourbonViewController: UIViewController {
    weak var delegate: AddBourbonViewControllerDelegate?
    
    @objc func saveBourbon() {
        print("AddBourbonViewController: Starting save process")
        
        // Validate required fields
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            print("AddBourbonViewController: Name validation failed")
            showErrorAlert(message: "Please enter a name for the bourbon")
            return
        }
        print("AddBourbonViewController: Name validation passed: \(name)")
        
        guard let proofText = proofTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !proofText.isEmpty,
              let proof = Double(proofText) else {
            print("AddBourbonViewController: Proof validation failed")
            showErrorAlert(message: "Please enter a valid proof")
            return
        }
        print("AddBourbonViewController: Proof validation passed: \(proof)")
        
        // Validate proof limits
        guard proof >= 80.0 && proof <= 160.0 else {
            print("AddBourbonViewController: Proof range validation failed: \(proof)")
            showErrorAlert(message: "Proof must be between 80.0 and 160.0")
            return
        }
        
        // Optional fields with default values
        let age = Int(ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
        let purchaseLocation = purchaseLocationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let flavorProfile = flavorProfileTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Handle price - convert to 0 if empty or invalid
        let priceText = priceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
        let price = Double(priceText) ?? 0.0
        print("AddBourbonViewController: Optional fields processed - Location: \(purchaseLocation), Profile: \(flavorProfile), Price: \(price)")
        
        // Handle size - use default if none selected
        let size = selectedSize ?? ""
        
        // Handle image - use default if none selected
        let imageFilename: String
        if let image = selectedImage {
            print("AddBourbonViewController: Processing selected image")
            imageFilename = "bourbon_\(UUID().uuidString).jpg"
            if !BourbonDatabase.shared.saveImage(image, filename: imageFilename) {
                print("AddBourbonViewController: Failed to save selected image")
                showErrorAlert(message: "Failed to save image")
                return
            }
            print("AddBourbonViewController: Successfully saved selected image: \(imageFilename)")
        } else {
            print("AddBourbonViewController: Using default image")
            imageFilename = "default_bourbon.jpg"
            if let defaultImage = UIImage(named: "placeholder") {
                if !BourbonDatabase.shared.saveImage(defaultImage, filename: imageFilename) {
                    print("AddBourbonViewController: Failed to save default image")
                    showErrorAlert(message: "Failed to save default image")
                    return
                }
                print("AddBourbonViewController: Successfully saved default image")
            }
        }
        
        // Get current location if available
        var purchaseLocationLatitude: Double?
        var purchaseLocationLongitude: Double?
        
        if let location = LocationService.shared.currentLocation {
            purchaseLocationLatitude = location.coordinate.latitude
            purchaseLocationLongitude = location.coordinate.longitude
        }
        
        print("AddBourbonViewController: Creating bourbon object")
        let bourbon = Bourbon(
            name: name,
            proof: proof,
            age: age,
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
            fillLevel: Int(fillLevelSlider.value),
            dateOpened: selectedDateOpened
        )
        
        print("AddBourbonViewController: Attempting to save bourbon to database")
        let bourbonId = BourbonDatabase.shared.addBourbon(bourbon)
        
        if bourbonId > 0 {
            print("AddBourbonViewController: Successfully saved bourbon with ID: \(bourbonId)")
            
            // Notify delegate first
            print("AddBourbonViewController: Notifying delegate")
            delegate?.addBourbonViewControllerDidAddBourbon(self)
            
            // Then post notification
            print("AddBourbonViewController: Posting notification")
            NotificationCenter.default.post(name: .bourbonCollectionDidChange, object: nil)
            
            // Finally, pop back to category view
            print("AddBourbonViewController: Popping back to category view")
            navigationController?.popViewController(animated: true) {
                print("AddBourbonViewController: Pop complete")
            }
        } else {
            print("AddBourbonViewController: Failed to save bourbon")
            showErrorAlert(message: "Failed to save bourbon")
        }
    }
} 