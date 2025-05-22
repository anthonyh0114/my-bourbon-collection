import UIKit
import PhotosUI
import ImageIO
import Photos
import CoreLocation
import MapKit

protocol AddBourbonViewControllerDelegate: AnyObject {
    func addBourbonViewControllerDidAddBourbon(_ controller: AddBourbonViewController)
}

struct LocationOption {
    let name: String
    let latitude: Double?
    let longitude: Double?
    let distance: Double?
}

class AddBourbonViewController: UIViewController, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    weak var delegate: AddBourbonViewControllerDelegate?
    
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
    let purchaseLocationTextField = UITextField()
    let flavorProfileTextField = UITextField()
    let notesTextView = UITextView()
    let priceTextField = UITextField()
    let sizeTextField = UITextField()
    let purchaseDatePicker = UIDatePicker()
    let dateOpenedLabel = UILabel()
    let dateOpenedPicker = UIDatePicker()
    let dateEmptiedLabel = UILabel()
    let dateEmptiedPicker = UIDatePicker()
    var selectedDateOpened: Date?
    var selectedDateEmptied: Date?
    let ratingSegmentedControl = UISegmentedControl(items: ["👎", "👌", "👍"])
    var selectedRating: Int = 0
    
    let fillLevelSlider = UISlider()
    let fillLevelLabel = UILabel()
    let emptyLabel = UILabel()
    let fullLabel = UILabel()
    
    var selectedImage: UIImage?
    var imageFilename: String?
    
    private var locationManager = CLLocationManager()
    private var selectedLocation: LocationOption?
    private var currentLocation: CLLocation?
    
    let sizePicker = UIPickerView()
    let sizes = ["Shooter - 50 ml", "100 ml", "Tasting", "375 ml", "750 ml", "1500 ml", "1750 ml"]
    var selectedSize: String?
    
    let purchaseDateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupLocationServices()
        setupSizePicker()
        
        // Request location authorization and start updating location immediately
        LocationService.shared.requestLocationAuthorization { [weak self] isAuthorized in
            print("AddBourbonViewController: Location authorization status: \(isAuthorized)")
            if isAuthorized {
                LocationService.shared.getCurrentLocation { location in
                    if let location = location {
                        print("AddBourbonViewController: Got current location: \(location.coordinate)")
                        self?.updateLocationField(with: location)
                    } else {
                        print("AddBourbonViewController: No location available")
                    }
                }
            }
        }
    }
    
    func setupUI() {
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
        imagePickerButton.setImage(UIImage(systemName: "photo"), for: .normal)
        imagePickerButton.tintColor = .systemBlue
        imagePickerButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(imagePickerButton)
        
        // Camera Button
        cameraButton.setTitle("Take Photo", for: .normal)
        cameraButton.setImage(UIImage(systemName: "camera"), for: .normal)
        cameraButton.tintColor = .systemBlue
        cameraButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        buttonStackView.addArrangedSubview(cameraButton)
        
        // Text Fields
        setupTextField(nameTextField, placeholder: "Name *")
        setupTextField(proofTextField, placeholder: "Proof *", keyboardType: .decimalPad)
        setupTextField(abvTextField, placeholder: "ABV", keyboardType: .decimalPad)
        setupTextField(ageTextField, placeholder: "Age", keyboardType: .numberPad)
        setupTextField(purchaseLocationTextField, placeholder: "Purchase Location")
        setupTextField(flavorProfileTextField, placeholder: "Flavor Profile")
        setupTextField(priceTextField, placeholder: "Price", keyboardType: .decimalPad)
        
        // Size Field
        setupTextField(sizeTextField, placeholder: "Size?")
        sizeTextField.inputView = sizePicker
        sizePicker.delegate = self
        sizePicker.dataSource = self
        
        // Add a toolbar with a "Done" button to dismiss the picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        sizeTextField.inputAccessoryView = toolbar
        
        // Purchase Date Label
        purchaseDateLabel.text = "Purchase Date *"
        purchaseDateLabel.font = .systemFont(ofSize: 16)
        purchaseDateLabel.textColor = .label
        contentView.addSubview(purchaseDateLabel)
        
        // Date Opened Field
        dateOpenedLabel.text = "Date Opened"
        dateOpenedLabel.font = .systemFont(ofSize: 16)
        dateOpenedLabel.textColor = .label
        contentView.addSubview(dateOpenedLabel)
        
        dateOpenedPicker.datePickerMode = .date
        dateOpenedPicker.preferredDatePickerStyle = .compact
        dateOpenedPicker.addTarget(self, action: #selector(dateOpenedChanged), for: .valueChanged)
        contentView.addSubview(dateOpenedPicker)
        
        // Date Emptied Field
        dateEmptiedLabel.text = "Date Emptied"
        dateEmptiedLabel.font = .systemFont(ofSize: 16)
        dateEmptiedLabel.textColor = .label
        contentView.addSubview(dateEmptiedLabel)
        
        dateEmptiedPicker.datePickerMode = .date
        dateEmptiedPicker.preferredDatePickerStyle = .compact
        dateEmptiedPicker.addTarget(self, action: #selector(dateEmptiedChanged), for: .valueChanged)
        contentView.addSubview(dateEmptiedPicker)
        
        // Rating Segmented Control
        ratingSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        ratingSegmentedControl.addTarget(self, action: #selector(ratingChanged(_:)), for: .valueChanged)
        contentView.addSubview(ratingSegmentedControl)
        
        // Notes TextView
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        contentView.addSubview(notesTextView)
        
        // Date Picker
        purchaseDatePicker.datePickerMode = .date
        purchaseDatePicker.preferredDatePickerStyle = .compact
        purchaseDatePicker.addTarget(self, action: #selector(purchaseDateChanged), for: .valueChanged)
        contentView.addSubview(purchaseDatePicker)
        
        // Add a label for the date picker to show it's required
        let dateLabel = UILabel()
        dateLabel.text = "Purchase Date *"
        dateLabel.font = .systemFont(ofSize: 16)
        dateLabel.textColor = .label
        contentView.addSubview(dateLabel)
        
        // Add Fill Level Slider
        fillLevelSlider.translatesAutoresizingMaskIntoConstraints = false
        fillLevelSlider.minimumValue = 0
        fillLevelSlider.maximumValue = 100
        fillLevelSlider.value = 100
        fillLevelSlider.tintColor = .systemBlue
        fillLevelSlider.addTarget(self, action: #selector(fillLevelChanged), for: .valueChanged)
        contentView.addSubview(fillLevelSlider)
        
        // Add emoji labels for slider
        emptyLabel.text = "😢"
        emptyLabel.font = .systemFont(ofSize: 20)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emptyLabel)
        
        fullLabel.text = "😊"
        fullLabel.font = .systemFont(ofSize: 20)
        fullLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fullLabel)
        
        fillLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        fillLevelLabel.text = "Fill Level: Unopened"
        fillLevelLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(fillLevelLabel)
        
        setupConstraints()
    }
    
    func setupTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.keyboardType = keyboardType
        textField.delegate = self
        contentView.addSubview(textField)
        
        // Set autocapitalization for name and purchase location fields
        if placeholder == "Name *" || placeholder == "Purchase Location" {
            textField.autocapitalizationType = .words
        }
        
        // Add target for proof field to update ABV
        if textField == proofTextField {
            textField.addTarget(self, action: #selector(proofFieldChanged), for: .editingChanged)
        }
    }
    
    func setupNavigationBar() {
        title = "Add Bourbon"
        
        // Save button
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveBourbon))
        navigationItem.rightBarButtonItem = saveButton
        
        // Cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        proofTextField.translatesAutoresizingMaskIntoConstraints = false
        abvTextField.translatesAutoresizingMaskIntoConstraints = false
        ageTextField.translatesAutoresizingMaskIntoConstraints = false
        purchaseLocationTextField.translatesAutoresizingMaskIntoConstraints = false
        flavorProfileTextField.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        priceTextField.translatesAutoresizingMaskIntoConstraints = false
        purchaseDatePicker.translatesAutoresizingMaskIntoConstraints = false
        dateOpenedLabel.translatesAutoresizingMaskIntoConstraints = false
        dateOpenedPicker.translatesAutoresizingMaskIntoConstraints = false
        dateEmptiedLabel.translatesAutoresizingMaskIntoConstraints = false
        dateEmptiedPicker.translatesAutoresizingMaskIntoConstraints = false
        ratingSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        fillLevelSlider.translatesAutoresizingMaskIntoConstraints = false
        fillLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        fullLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeTextField.translatesAutoresizingMaskIntoConstraints = false
        purchaseDateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Image View
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0),
            
            // Button Stack View
            buttonStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // Name Text Field
            nameTextField.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Proof Text Field
            proofTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            proofTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            proofTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            proofTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // ABV Text Field
            abvTextField.topAnchor.constraint(equalTo: proofTextField.bottomAnchor, constant: 16),
            abvTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            abvTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            abvTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Age Text Field
            ageTextField.topAnchor.constraint(equalTo: abvTextField.bottomAnchor, constant: 16),
            ageTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ageTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ageTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Purchase Location Text Field
            purchaseLocationTextField.topAnchor.constraint(equalTo: ageTextField.bottomAnchor, constant: 16),
            purchaseLocationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            purchaseLocationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            purchaseLocationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Flavor Profile Text Field
            flavorProfileTextField.topAnchor.constraint(equalTo: purchaseLocationTextField.bottomAnchor, constant: 16),
            flavorProfileTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            flavorProfileTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            flavorProfileTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Price Text Field
            priceTextField.topAnchor.constraint(equalTo: flavorProfileTextField.bottomAnchor, constant: 16),
            priceTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            priceTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            priceTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Size Text Field
            sizeTextField.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 16),
            sizeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sizeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sizeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Purchase Date Label
            purchaseDateLabel.topAnchor.constraint(equalTo: sizeTextField.bottomAnchor, constant: 16),
            purchaseDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Purchase Date Picker
            purchaseDatePicker.topAnchor.constraint(equalTo: purchaseDateLabel.bottomAnchor, constant: 8),
            purchaseDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            purchaseDatePicker.heightAnchor.constraint(equalToConstant: 44),
            
            // Date Opened Label
            dateOpenedLabel.topAnchor.constraint(equalTo: purchaseDatePicker.bottomAnchor, constant: 16),
            dateOpenedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Date Opened Picker
            dateOpenedPicker.topAnchor.constraint(equalTo: dateOpenedLabel.bottomAnchor, constant: 8),
            dateOpenedPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateOpenedPicker.heightAnchor.constraint(equalToConstant: 44),
            
            // Date Emptied Label
            dateEmptiedLabel.topAnchor.constraint(equalTo: dateOpenedPicker.bottomAnchor, constant: 16),
            dateEmptiedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Date Emptied Picker
            dateEmptiedPicker.topAnchor.constraint(equalTo: dateEmptiedLabel.bottomAnchor, constant: 8),
            dateEmptiedPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateEmptiedPicker.heightAnchor.constraint(equalToConstant: 44),
            
            // Rating Segmented Control
            ratingSegmentedControl.topAnchor.constraint(equalTo: dateEmptiedPicker.bottomAnchor, constant: 16),
            ratingSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ratingSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ratingSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            // Fill Level Label
            fillLevelLabel.topAnchor.constraint(equalTo: ratingSegmentedControl.bottomAnchor, constant: 16),
            fillLevelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Fill Level Slider and Labels
            fillLevelSlider.topAnchor.constraint(equalTo: fillLevelLabel.bottomAnchor, constant: 8),
            fillLevelSlider.leadingAnchor.constraint(equalTo: emptyLabel.trailingAnchor, constant: 8),
            fillLevelSlider.trailingAnchor.constraint(equalTo: fullLabel.leadingAnchor, constant: -8),
            fillLevelSlider.heightAnchor.constraint(equalToConstant: 44),
            
            emptyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emptyLabel.centerYAnchor.constraint(equalTo: fillLevelSlider.centerYAnchor),
            
            fullLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fullLabel.centerYAnchor.constraint(equalTo: fillLevelSlider.centerYAnchor),
            
            // Notes Text View
            notesTextView.topAnchor.constraint(equalTo: fillLevelSlider.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLocationServices() {
        // Add location button to purchase location field
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.addTarget(self, action: #selector(showLocationSelection), for: .touchUpInside)
        purchaseLocationTextField.rightView = locationButton
        purchaseLocationTextField.rightViewMode = .always
    }
    
    private func setupSizePicker() {
        // Configure the size picker
        sizePicker.delegate = self
        sizePicker.dataSource = self
        
        // Set initial size if needed
        if selectedSize == nil {
            selectedSize = sizes[0] // Default to first size
            sizeTextField.text = selectedSize
        }
    }
    
    @objc func showLocationSelection() {
        let locationVC = LocationSelectionViewController()
        locationVC.delegate = self
        let navController = UINavigationController(rootViewController: locationVC)
        present(navController, animated: true)
    }
    
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func takePhoto() {
        let cameraVC = CustomCameraViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        // First fix the orientation
        let fixedImage: UIImage
        if image.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            fixedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            fixedImage = image
        }
        
        // Calculate the target size while maintaining aspect ratio
        let maxDimension: CGFloat = 2000
        let aspectRatio = fixedImage.size.width / fixedImage.size.height
        
        var newSize: CGSize
        if aspectRatio > 1 {
            // Image is wider than tall
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Image is taller than wide
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Create a new image context with the calculated size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        fixedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? fixedImage
    }
    
    private func saveImageToCustomAlbum(_ image: UIImage) {
        // Request authorization
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "Please allow access to your photo library to save photos")
                }
                return
            }
            
            // Create or get the custom album
            let albumName = "My Bourbon Collection"
            var albumAsset: PHAssetCollection?
            
            // Check if album exists
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let album = collections.firstObject {
                albumAsset = album
            } else {
                // Create new album
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                }) { success, error in
                    if success {
                        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                        albumAsset = collections.firstObject
                    } else if let error = error {
                        print("Error creating album: \(error.localizedDescription)")
                    }
                }
            }
            
            // Save the image to the album
            PHPhotoLibrary.shared().performChanges({
                let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                if let albumAsset = albumAsset,
                   let albumChangeRequest = PHAssetCollectionChangeRequest(for: albumAsset) {
                    albumChangeRequest.addAssets([createAssetRequest.placeholderForCreatedAsset!] as NSFastEnumeration)
                }
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Successfully saved image to My Bourbon Collection album")
                    } else if let error = error {
                        print("Error saving image: \(error.localizedDescription)")
                        self?.showErrorAlert(message: "Failed to save image to photo library")
                    }
                }
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
        }
    }
    
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
        let age = ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
            dateOpened: selectedDateOpened,
            dateEmptied: selectedDateEmptied
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
            
            // Finally, dismiss the view controller
            print("AddBourbonViewController: Dismissing view controller")
            dismiss(animated: true)
        } else {
            print("AddBourbonViewController: Failed to save bourbon")
            showErrorAlert(message: "Failed to save bourbon")
        }
    }
    
    @objc func cancel() {
        dismiss(animated: true)
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        if let activeField = findFirstResponder() {
            let rect = activeField.convert(activeField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func findFirstResponder() -> UIView? {
        if nameTextField.isFirstResponder { return nameTextField }
        if proofTextField.isFirstResponder { return proofTextField }
        if ageTextField.isFirstResponder { return ageTextField }
        if purchaseLocationTextField.isFirstResponder { return purchaseLocationTextField }
        if flavorProfileTextField.isFirstResponder { return flavorProfileTextField }
        if priceTextField.isFirstResponder { return priceTextField }
        if notesTextView.isFirstResponder { return notesTextView }
        return nil
    }
    
    @objc private func ratingChanged(_ sender: UISegmentedControl) {
        selectedRating = sender.selectedSegmentIndex + 1
    }
    
    @objc private func fillLevelChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        
        // Change slider color based on value
        if value <= 10 {
            fillLevelSlider.tintColor = .systemRed
        } else {
            fillLevelSlider.tintColor = .systemBlue
        }
        
        if value == 0 {
            fillLevelLabel.text = "Fill Level: Empty"
        } else if value == 100 {
            fillLevelLabel.text = "Fill Level: Unopened"
        } else {
            fillLevelLabel.text = "Fill Level: \(value)%"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateFillLevelLabel() {
        let value = Int(fillLevelSlider.value)
        
        // Change slider color based on value
        if value <= 10 {
            fillLevelSlider.tintColor = .systemRed
        } else {
            fillLevelSlider.tintColor = .systemBlue
        }
        
        if value == 0 {
            fillLevelLabel.text = "Fill Level: Empty"
        } else if value == 100 {
            fillLevelLabel.text = "Fill Level: Unopened"
        } else {
            fillLevelLabel.text = "Fill Level: \(value)%"
        }
    }
    
    @objc private func proofFieldChanged() {
        if let proofText = proofTextField.text, let proof = Double(proofText) {
            let abv = proof / 2.0
            abvTextField.text = String(format: "%.1f", abv)
        } else {
            abvTextField.text = ""
        }
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == sizePicker {
            return 1
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == sizePicker {
            return sizes.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == sizePicker {
            return sizes[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == sizePicker {
            selectedSize = sizes[row]
            sizeTextField.text = selectedSize
        }
    }
    
    @objc func doneButtonTapped() {
        sizeTextField.resignFirstResponder()
    }
    
    @objc private func dateOpenedChanged(_ sender: UIDatePicker) {
        // Ensure date opened is not before purchase date
        if sender.date < purchaseDatePicker.date {
            sender.date = purchaseDatePicker.date
            showErrorAlert(message: "Date opened cannot be before purchase date")
        }
        
        // If date emptied exists and is before new date opened, reset it
        if let dateEmptied = selectedDateEmptied, dateEmptied < sender.date {
            dateEmptiedPicker.date = sender.date
            selectedDateEmptied = sender.date
            showErrorAlert(message: "Date emptied has been adjusted to be after date opened")
        }
        
        selectedDateOpened = sender.date
    }
    
    @objc private func dateEmptiedChanged(_ sender: UIDatePicker) {
        // Ensure date emptied is not before date opened
        if let dateOpened = selectedDateOpened {
            if sender.date < dateOpened {
                sender.date = dateOpened
                showErrorAlert(message: "Date emptied cannot be before date opened")
            }
        } else {
            // If no date opened is set, use purchase date as minimum
            if sender.date < purchaseDatePicker.date {
                sender.date = purchaseDatePicker.date
                showErrorAlert(message: "Date emptied cannot be before purchase date")
            }
        }
        
        selectedDateEmptied = sender.date
    }
    
    @objc private func purchaseDateChanged(_ sender: UIDatePicker) {
        // If date opened exists and is before new purchase date, reset it
        if let dateOpened = selectedDateOpened, dateOpened < sender.date {
            dateOpenedPicker.date = sender.date
            selectedDateOpened = sender.date
            showErrorAlert(message: "Date opened has been adjusted to be after purchase date")
        }
        
        // If date emptied exists and is before new purchase date, reset it
        if let dateEmptied = selectedDateEmptied, dateEmptied < sender.date {
            dateEmptiedPicker.date = sender.date
            selectedDateEmptied = sender.date
            showErrorAlert(message: "Date emptied has been adjusted to be after purchase date")
        }
    }
    
    // Add UITextFieldDelegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow decimal point for proof and price fields
        if textField == proofTextField || textField == priceTextField {
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
    
    private func updateLocationField(with location: CLLocation) {
        LocationService.shared.processLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { [weak self] locationName in
            DispatchQueue.main.async {
                if let locationName = locationName {
                    self?.purchaseLocationTextField.text = locationName
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
}

extension AddBourbonViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension AddBourbonViewController: CustomCameraViewControllerDelegate {
    func customCameraViewController(_ controller: CustomCameraViewController, didCaptureImage image: UIImage) {
        controller.dismiss(animated: true) {
            // Process the image to be properly sized
            let processedImage = self.processImage(image)
            self.selectedImage = processedImage
            
            // Update image view with animation
            UIView.transition(with: self.imageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.imageView.image = processedImage
            }
            
            // Save to photo library
            UIImageWriteToSavedPhotosAlbum(processedImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func customCameraViewControllerDidCancel(_ controller: CustomCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
            let alert = UIAlertController(title: "Error", message: "Failed to save image to photo library", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            print("Image saved successfully to photo library")
        }
    }
}

extension AddBourbonViewController: LocationSelectionViewControllerDelegate {
    func locationSelectionViewController(_ controller: LocationSelectionViewController, didSelectLocation location: LocationOption) {
        purchaseLocationTextField.text = location.name
        selectedLocation = location
    }
} 