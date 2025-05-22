import UIKit
import PhotosUI
import ImageIO
import Photos
import CoreLocation
import MapKit

protocol AddTastingViewControllerDelegate: AnyObject {
    func addTastingViewControllerDidAddTasting(_ controller: AddTastingViewController)
}

enum TastingType: String, CaseIterable {
    case neat = "Neat"
    case rocks = "Rocks"
    case splash = "Splash"
    case flight = "Flight"
}

class AddTastingViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    weak var delegate: AddTastingViewControllerDelegate?
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    let imageView = UIImageView()
    let imagePickerButton = UIButton(type: .system)
    let cameraButton = UIButton(type: .system)
    let buttonStackView = UIStackView()
    let nameTextField = UITextField()
    let proofTextField = UITextField()
    let abvTextField = UITextField()
    let ageTextField = UITextField()
    let tastingLocationTextField = UITextField()
    let flavorProfileTextField = UITextField()
    let notesTextView = UITextView()
    let pourPriceTextField = UITextField()
    let tastingDatePicker = UIDatePicker()
    let tastingDateLabel = UILabel()
    let tastingTypePicker = UIPickerView()
    let tastingTypeLabel = UILabel()
    
    var selectedImage: UIImage?
    var imageFilename: String?
    
    private var locationManager = CLLocationManager()
    private var selectedLocation: LocationOption?
    private var currentLocation: CLLocation?
    private var selectedTastingType: TastingType = .neat
    
    private let nameFieldContainer = UIView()
    private let additionalDetailsContainer = UIView()
    
    private var currentNameField: UITextField?
    private var currentAdditionalDetailsField: UITextField?
    private var fieldsStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("AddTastingViewController: viewDidLoad")
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupLocationServices()
        setupTastingTypePicker()
        print("AddTastingViewController: Setup complete")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("AddTastingViewController: viewWillAppear")
        print("AddTastingViewController: nameTextField placeholder: \(String(describing: nameTextField.placeholder))")
        print("AddTastingViewController: additionalDetailsTextField isHidden: \(additionalDetailsTextField.isHidden)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("AddTastingViewController: viewDidAppear")
        print("AddTastingViewController: nameTextField placeholder: \(String(describing: nameTextField.placeholder))")
        
        // Ensure initial state is set
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectedTastingType = .neat
            self.updateFieldsForCurrentType()
            self.tastingTypePicker.selectRow(0, inComponent: 0, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("AddTastingViewController: viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("AddTastingViewController: viewDidDisappear")
    }
    
    deinit {
        print("AddTastingViewController: deinit")
    }
    
    private func setupUI() {
        print("AddTastingViewController: setupUI")
        view.backgroundColor = .systemBackground
        
        // Scroll View
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Image View and Picker Button
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Button Stack View
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        contentView.addSubview(buttonStackView)
        
        // Image Picker Button
        imagePickerButton.setTitle("Choose Photo", for: .normal)
        imagePickerButton.setImage(UIImage(systemName: "photo"), for: .normal)
        imagePickerButton.tintColor = .systemBlue
        imagePickerButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        buttonStackView.addArrangedSubview(imagePickerButton)
        
        // Camera Button
        cameraButton.setTitle("Take Photo", for: .normal)
        cameraButton.setImage(UIImage(systemName: "camera"), for: .normal)
        cameraButton.tintColor = .systemBlue
        cameraButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        buttonStackView.addArrangedSubview(cameraButton)
        
        // Tasting Type Label
        tastingTypeLabel.text = "Tasting Type"
        tastingTypeLabel.font = .systemFont(ofSize: 16)
        tastingTypeLabel.textColor = .label
        contentView.addSubview(tastingTypeLabel)
        
        // Tasting Type Picker
        tastingTypePicker.delegate = self
        tastingTypePicker.dataSource = self
        contentView.addSubview(tastingTypePicker)
        
        // Fields Stack View
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = 16
        fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fieldsStackView)
        
        // Other Text Fields
        setupTextField(proofTextField, placeholder: "Proof *", keyboardType: .decimalPad)
        setupTextField(abvTextField, placeholder: "ABV", keyboardType: .decimalPad)
        setupTextField(ageTextField, placeholder: "Age (years)", keyboardType: .numberPad)
        setupTextField(tastingLocationTextField, placeholder: "Tasting Location")
        setupTextField(flavorProfileTextField, placeholder: "Flavor Profile")
        setupTextField(pourPriceTextField, placeholder: "Pour Price", keyboardType: .decimalPad)
        
        // Tasting Date Label
        tastingDateLabel.text = "Tasting Date *"
        tastingDateLabel.font = .systemFont(ofSize: 16)
        tastingDateLabel.textColor = .label
        contentView.addSubview(tastingDateLabel)
        
        // Tasting Date Picker
        tastingDatePicker.datePickerMode = .date
        tastingDatePicker.preferredDatePickerStyle = .compact
        tastingDatePicker.addTarget(self, action: #selector(tastingDateChanged), for: .valueChanged)
        contentView.addSubview(tastingDatePicker)
        
        // Notes TextView
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        contentView.addSubview(notesTextView)
        
        setupConstraints()
        
        // Set initial state
        selectedTastingType = .neat
        updateFieldsForCurrentType()
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.keyboardType = keyboardType
        textField.delegate = self
        contentView.addSubview(textField)
        
        // Set autocapitalization for name and location fields
        if placeholder == "Name" || placeholder == "Tasting Location" {
            textField.autocapitalizationType = .words
        }
        
        // Add target for proof field to update ABV
        if textField == proofTextField {
            textField.addTarget(self, action: #selector(proofFieldChanged), for: .editingChanged)
        }
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        proofTextField.translatesAutoresizingMaskIntoConstraints = false
        abvTextField.translatesAutoresizingMaskIntoConstraints = false
        ageTextField.translatesAutoresizingMaskIntoConstraints = false
        tastingLocationTextField.translatesAutoresizingMaskIntoConstraints = false
        flavorProfileTextField.translatesAutoresizingMaskIntoConstraints = false
        pourPriceTextField.translatesAutoresizingMaskIntoConstraints = false
        tastingDateLabel.translatesAutoresizingMaskIntoConstraints = false
        tastingDatePicker.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        tastingTypePicker.translatesAutoresizingMaskIntoConstraints = false
        tastingTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            buttonStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tastingTypeLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            tastingTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            tastingTypePicker.topAnchor.constraint(equalTo: tastingTypeLabel.bottomAnchor, constant: 8),
            tastingTypePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tastingTypePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tastingTypePicker.heightAnchor.constraint(equalToConstant: 120),
            
            fieldsStackView.topAnchor.constraint(equalTo: tastingTypePicker.bottomAnchor, constant: 16),
            fieldsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fieldsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tastingDateLabel.topAnchor.constraint(equalTo: fieldsStackView.bottomAnchor, constant: 16),
            tastingDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            tastingDatePicker.topAnchor.constraint(equalTo: tastingDateLabel.bottomAnchor, constant: 8),
            tastingDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tastingDatePicker.heightAnchor.constraint(equalToConstant: 44),
            
            notesTextView.topAnchor.constraint(equalTo: tastingDatePicker.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Add Tasting"
        
        // Cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        // Save button
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTasting))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 5
        
        // Add location button to tasting location field
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.addTarget(self, action: #selector(useCurrentLocation), for: .touchUpInside)
        tastingLocationTextField.rightView = locationButton
        tastingLocationTextField.rightViewMode = .always
        
        // Request location authorization and start updating location immediately
        LocationService.shared.requestLocationAuthorization { [weak self] isAuthorized in
            print("AddTastingViewController: Location authorization status: \(isAuthorized)")
            if isAuthorized {
                LocationService.shared.getCurrentLocation { location in
                    if let location = location {
                        print("AddTastingViewController: Got current location: \(location.coordinate)")
                        self?.updateLocationField(with: location)
                    } else {
                        print("AddTastingViewController: No location available")
                    }
                }
            }
        }
    }
    
    private func setupTastingTypePicker() {
        // Implementation of setupTastingTypePicker method
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @objc private func proofFieldChanged() {
        if let proofText = proofTextField.text, let proof = Double(proofText) {
            let abv = proof / 2
            abvTextField.text = String(format: "%.1f", abv)
        } else {
            abvTextField.text = ""
        }
    }
    
    @objc private func tastingDateChanged() {
        // Update UI if needed
    }
    
    @objc private func useCurrentLocation() {
        print("AddTastingViewController: useCurrentLocation called")
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    
    @objc private func takePhoto() {
        let cameraVC = CustomCameraViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    @objc private func saveTasting() {
        print("AddTastingViewController: saveTasting called")
        // Get all field values
        let name = currentNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let additionalDetails = currentAdditionalDetailsField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("AddTastingViewController: Name: \(name), Additional Details: \(additionalDetails)")
        
        // Validate required fields
        guard !name.isEmpty else {
            print("AddTastingViewController: Name missing")
            showErrorAlert(message: "Please enter a name for the tasting")
            return
        }
        
        if selectedTastingType == .flight && additionalDetails.isEmpty {
            print("AddTastingViewController: Flight details missing")
            showErrorAlert(message: "Please enter the bourbons in your flight")
            return
        }
        
        // Get optional fields
        let proof = Double(proofTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0.0
        let age = Int(ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
        let tastingLocation = tastingLocationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let flavorProfile = flavorProfileTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pourPrice = Double(pourPriceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0.0
        print("AddTastingViewController: Fields - Proof: \(proof), Age: \(age), Location: \(tastingLocation), Price: \(pourPrice)")
        
        // Get tasting type
        let tastingType = selectedTastingType.rawValue
        print("AddTastingViewController: Tasting type: \(tastingType)")
        
        // Handle image
        print("AddTastingViewController: Handling image")
        let imageFilename: String
        if let image = selectedImage {
            print("AddTastingViewController: Saving selected image")
            let filename = "tasting_\(UUID().uuidString).jpg"
            if BourbonDatabase.shared.saveImage(image, filename: filename) {
                print("AddTastingViewController: Successfully saved image as \(filename)")
                imageFilename = filename
            } else {
                print("AddTastingViewController: Failed to save image")
                showErrorAlert(message: "Failed to save image")
                return
            }
        } else {
            print("AddTastingViewController: Using default image")
            let filename = "default_tasting.jpg"
            if let defaultImage = UIImage(named: "placeholder") {
                if BourbonDatabase.shared.saveImage(defaultImage, filename: filename) {
                    print("AddTastingViewController: Successfully saved default image")
                    imageFilename = filename
                } else {
                    print("AddTastingViewController: Failed to save default image")
                    showErrorAlert(message: "Failed to save default image")
                    return
                }
            } else {
                print("AddTastingViewController: No default image available, using filename only")
                imageFilename = "default_tasting.jpg"
            }
        }
        
        // Get current location if available
        var tastingLocationLatitude: Double?
        var tastingLocationLongitude: Double?
        
        if let location = LocationService.shared.currentLocation {
            print("AddTastingViewController: Using current location: \(location.coordinate)")
            tastingLocationLatitude = location.coordinate.latitude
            tastingLocationLongitude = location.coordinate.longitude
        } else {
            print("AddTastingViewController: No location available")
        }
        
        // Create tasting object
        print("AddTastingViewController: Creating tasting object")
        let tasting = Bourbon(
            name: name,
            proof: proof,
            age: age,
            purchaseDate: tastingDatePicker.date,
            purchaseLocation: tastingLocation,
            purchaseLocationLatitude: tastingLocationLatitude,
            purchaseLocationLongitude: tastingLocationLongitude,
            flavorProfile: flavorProfile,
            notes: notes + (additionalDetails.isEmpty ? "" : "\n\nTasting Type: \(tastingType)" + (additionalDetails.isEmpty ? "" : "\nFlight Details: \(additionalDetails)")),
            price: pourPrice,
            size: "Tasting",
            imageFilename: imageFilename,
            rating: 0,
            fillLevel: 0
        )
        
        // Save to database
        print("AddTastingViewController: Saving to database")
        let tastingId = BourbonDatabase.shared.addBourbon(tasting)
        
        if tastingId > 0 {
            print("AddTastingViewController: Successfully saved tasting with ID: \(tastingId)")
            // Notify delegate
            print("AddTastingViewController: Notifying delegate")
            delegate?.addTastingViewControllerDidAddTasting(self)
            
            // Post notification
            print("AddTastingViewController: Posting notification")
            NotificationCenter.default.post(name: .bourbonCollectionDidChange, object: nil)
            
            // Dismiss view controller
            print("AddTastingViewController: Dismissing view controller")
            dismiss(animated: true)
        } else {
            print("AddTastingViewController: Failed to save tasting")
            showErrorAlert(message: "Failed to save tasting. Please try again.")
        }
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateFieldsForCurrentType() {
        print("AddTastingViewController: Updating fields for type: \(selectedTastingType)")
        
        // Remove existing fields
        fieldsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        currentNameField = nil
        currentAdditionalDetailsField = nil
        
        // Create name field
        let nameField = UITextField()
        nameField.borderStyle = .roundedRect
        nameField.delegate = self
        nameField.autocapitalizationType = .words
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = "Name *"
        fieldsStackView.addArrangedSubview(nameField)
        currentNameField = nameField
        
        // Add additional details field for flight tastings only
        if selectedTastingType == .flight {
            let detailsField = UITextField()
            detailsField.placeholder = "Flight Details *"
            detailsField.borderStyle = .roundedRect
            detailsField.delegate = self
            detailsField.translatesAutoresizingMaskIntoConstraints = false
            fieldsStackView.addArrangedSubview(detailsField)
            currentAdditionalDetailsField = detailsField
        }
        
        // Force layout update
        view.layoutIfNeeded()
    }
    
    private func updateLocationField(with location: CLLocation) {
        LocationService.shared.processLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { [weak self] locationName in
            DispatchQueue.main.async {
                if let locationName = locationName {
                    self?.tastingLocationTextField.text = locationName
                    self?.selectedLocation = LocationOption(
                        name: locationName,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        distance: nil
                    )
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("AddTastingViewController: locationManager didUpdateLocations")
        guard let location = locations.last else { return }
        
        // Stop updating location after getting one
        locationManager.stopUpdatingLocation()
        
        // Update the location field
        updateLocationField(with: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("AddTastingViewController: locationManager didFailWithError: \(error.localizedDescription)")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("AddTastingViewController: locationManager didChangeAuthorization: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("AddTastingViewController: Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

extension AddTastingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
            
            // Save the image
            if let filename = ImageService.shared.saveImage(image) {
                imageFilename = filename
            }
        }
        
        picker.dismiss(animated: true)
    }
}

extension AddTastingViewController: CustomCameraViewControllerDelegate {
    func customCameraViewController(_ controller: CustomCameraViewController, didCaptureImage image: UIImage) {
        selectedImage = image
        imageView.image = image
        
        // Save the image
        if let filename = ImageService.shared.saveImage(image) {
            imageFilename = filename
        }
        
        controller.dismiss(animated: true)
    }
    
    func customCameraViewControllerDidCancel(_ controller: CustomCameraViewController) {
        controller.dismiss(animated: true)
    }
}

extension AddTastingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("AddTastingViewController: pickerView didSelectRow: \(row)")
        selectedTastingType = TastingType.allCases[row]
        updateFieldsForCurrentType()
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TastingType.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TastingType.allCases[row].rawValue
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
} 