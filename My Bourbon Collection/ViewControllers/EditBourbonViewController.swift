class EditBourbonViewController: AddBourbonViewController {
    private var bourbon: Bourbon
    private var editImageButton: UIButton?
    
    init(bourbon: Bourbon) {
        self.bourbon = bourbon
        super.init(nibName: nil, bundle: nil)
        print("EditBourbonViewController: Initialized with bourbon: \(bourbon.name)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("EditBourbonViewController: viewDidLoad")
        title = "Edit Bourbon"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("EditBourbonViewController: viewDidLayoutSubviews")
        print("EditBourbonViewController: Image view frame: \(imageView.frame)")
        print("EditBourbonViewController: Image view bounds: \(imageView.bounds)")
        print("EditBourbonViewController: Image view has image: \(imageView.image != nil)")
        
        // Only add the edit button once the view has been laid out
        if editImageButton == nil {
            print("EditBourbonViewController: Setting up edit button")
            setupEditButton()
        }
    }
    
    private func setupEditButton() {
        print("EditBourbonViewController: Setting up edit button")
        
        // Make sure the image view is set up
        imageView.isUserInteractionEnabled = true
        print("EditBourbonViewController: Image view user interaction enabled: \(imageView.isUserInteractionEnabled)")
        
        // Create and configure the edit button
        let editImageButton = UIButton(type: .system)
        editImageButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editImageButton.tintColor = .systemBlue
        editImageButton.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        editImageButton.layer.cornerRadius = 16
        editImageButton.addTarget(self, action: #selector(editImageTapped), for: .touchUpInside)
        editImageButton.translatesAutoresizingMaskIntoConstraints = false
        editImageButton.isUserInteractionEnabled = true
        print("EditBourbonViewController: Created edit button")
        
        // Add the button to the image view
        imageView.addSubview(editImageButton)
        print("EditBourbonViewController: Added edit button to image view")
        
        NSLayoutConstraint.activate([
            editImageButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            editImageButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            editImageButton.widthAnchor.constraint(equalToConstant: 32),
            editImageButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        print("EditBourbonViewController: Set up edit button constraints")
        
        // Store the button reference
        self.editImageButton = editImageButton
        
        // Hide the default image picker buttons
        imagePickerButton.isHidden = true
        cameraButton.isHidden = true
        
        // Force layout update
        imageView.layoutIfNeeded()
        print("EditBourbonViewController: Edit button frame: \(editImageButton.frame)")
        print("EditBourbonViewController: Edit button is in view hierarchy: \(editImageButton.window != nil)")
    }
    
    private func populateFields() {
        print("EditBourbonViewController: Populating fields")
        // Load existing image if available
        if let imageFilename = bourbon.imageFilename {
            print("EditBourbonViewController: Loading image with filename: \(imageFilename)")
            if let image = BourbonDatabase.shared.loadImage(filename: imageFilename) {
                print("EditBourbonViewController: Successfully loaded image")
                selectedImage = image
                imageView.image = image
            } else {
                print("EditBourbonViewController: Failed to load image")
                imageView.image = UIImage(named: "placeholder")
            }
        } else {
            print("EditBourbonViewController: No image filename, using placeholder")
            imageView.image = UIImage(named: "placeholder")
        }
        
        // Populate other fields
        nameTextField.text = bourbon.name
        proofTextField.text = String(bourbon.proof)
        ageTextField.text = bourbon.age > 0 ? String(bourbon.age) : ""
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
        
        print("EditBourbonViewController: Fields populated")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("EditBourbonViewController: viewWillAppear")
        populateFields()
    }
    
    @objc private func editImageTapped() {
        let alert = UIAlertController(title: "Edit Photo", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default) { [weak self] _ in
            self?.selectImage()
        })
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.takePhoto()
        })
        
        if selectedImage != nil {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
                self?.selectedImage = nil
                self?.imageView.image = UIImage(named: "placeholder")
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure popover presentation for iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = imageView
            popoverController.sourceRect = imageView.bounds
        }
        
        present(alert, animated: true)
    }
    
    override func selectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        
        // Enable additional editing options
        picker.imageExportPreset = .compatible
        picker.videoExportPreset = .passthrough
        
        present(picker, animated: true)
    }
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // Process the image to be properly sized
            let processedImage = processImage(image)
            selectedImage = processedImage
            
            // Update image view with animation
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.imageView.image = processedImage
            }
        }
    }
    
    override func saveBourbon() {
        // ... existing validation code ...
        
        let updatedBourbon = Bourbon(
            id: bourbon.id,
            name: name,
            proof: proof,
            age: Int(ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0,
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
        
        // ... existing save code ...
    }
} 