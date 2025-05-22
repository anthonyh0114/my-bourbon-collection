import UIKit
import AVFoundation

protocol CustomCameraViewControllerDelegate: AnyObject {
    func customCameraViewController(_ controller: CustomCameraViewController, didCaptureImage image: UIImage)
    func customCameraViewControllerDidCancel(_ controller: CustomCameraViewController)
}

class CustomCameraViewController: UIViewController {
    weak var delegate: CustomCameraViewControllerDelegate?
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let photoOutput = AVCapturePhotoOutput()
    
    private let previewView = UIView()
    private let cropBox = UIView()
    private let guideLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermissions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Preview View
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        // Crop Box
        cropBox.backgroundColor = .clear
        cropBox.layer.borderColor = UIColor.white.cgColor
        cropBox.layer.borderWidth = 2
        cropBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropBox)
        
        // Guide Label
        guideLabel.text = "Take a photo of your bourbon bottle"
        guideLabel.textColor = .white
        guideLabel.textAlignment = .center
        guideLabel.font = .systemFont(ofSize: 16, weight: .medium)
        guideLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        guideLabel.layer.cornerRadius = 8
        guideLabel.clipsToBounds = true
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
        
        // Capture Button
        captureButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.contentVerticalAlignment = .fill
        captureButton.contentHorizontalAlignment = .fill
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)
        
        // Cancel Button
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.contentVerticalAlignment = .fill
        cancelButton.contentHorizontalAlignment = .fill
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            // Preview View
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Crop Box
            cropBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cropBox.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cropBox.widthAnchor.constraint(equalTo: view.widthAnchor),
            cropBox.heightAnchor.constraint(equalTo: cropBox.widthAnchor),
            
            // Guide Label
            guideLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            guideLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
            guideLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // Capture Button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Cancel Button
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 40),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showError(message: "Camera access is required to take photos")
                    }
                }
            }
        case .denied, .restricted:
            showError(message: "Please enable camera access in Settings")
        @unknown default:
            showError(message: "Camera access is not available")
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showError(message: "Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            // Start the capture session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
            
        } catch {
            showError(message: "Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }
    
    private func startCaptureSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    private func stopCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    @objc private func captureButtonTapped() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.customCameraViewControllerDidCancel(self)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.delegate?.customCameraViewControllerDidCancel(self!)
        })
        present(alert, animated: true)
    }
}

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            showError(message: "Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error: Could not create UIImage from photo data")
            showError(message: "Error processing photo")
            return
        }
        
        print("Successfully captured photo of size \(image.size)")
        
        // Calculate the crop rect based on the crop box frame
        let cropRect = calculateCropRect(for: image)
        if let croppedImage = cropImage(image, to: cropRect) {
            // Process the cropped image to ensure proper size and quality
            let processedImage = processImage(croppedImage)
            delegate?.customCameraViewController(self, didCaptureImage: processedImage)
        } else {
            print("Error: Failed to crop image")
            showError(message: "Error cropping photo")
        }
    }
    
    private func calculateCropRect(for image: UIImage) -> CGRect {
        guard let previewLayer = previewLayer else {
            print("Error: Preview layer is nil")
            return .zero
        }
        
        print("Image size: \(image.size)")
        print("Preview layer frame: \(previewLayer.frame)")
        print("Crop box frame: \(cropBox.frame)")
        
        // Calculate the scale between preview and image
        let scaleX = image.size.width / previewLayer.frame.width
        let scaleY = image.size.height / previewLayer.frame.height
        
        // Convert crop box frame to image coordinates
        let cropX = cropBox.frame.minX * scaleX
        let cropY = cropBox.frame.minY * scaleY
        let cropWidth = cropBox.frame.width * scaleX
        let cropHeight = cropBox.frame.height * scaleY
        
        // Calculate the center point of the crop box
        let centerX = cropX + (cropWidth / 2)
        let centerY = cropY + (cropHeight / 2)
        
        // Use the smaller dimension to ensure a square crop
        let squareSize = min(cropWidth, cropHeight)
        
        // Calculate the final square crop rect centered on the original crop box
        let finalX = centerX - (squareSize / 2)
        let finalY = centerY - (squareSize / 2)
        
        // Ensure the crop rect is within image bounds
        let boundedX = max(0, min(finalX, image.size.width - squareSize))
        let boundedY = max(0, min(finalY, image.size.height - squareSize))
        
        let finalRect = CGRect(x: boundedX, y: boundedY, width: squareSize, height: squareSize)
        print("Final crop rect: \(finalRect)")
        
        return finalRect
    }
    
    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        print("Attempting to crop image of size \(image.size) to rect \(rect)")
        
        // First fix the orientation
        let fixedImage: UIImage
        if image.imageOrientation != .up {
            print("Fixing image orientation from \(image.imageOrientation.rawValue)")
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            fixedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            fixedImage = image
        }
        
        // Now crop the image
        guard let cgImage = fixedImage.cgImage else {
            print("Error: Could not get CGImage from UIImage")
            return nil
        }
        
        // Ensure the crop rect is within bounds
        let boundedRect = CGRect(
            x: max(0, min(rect.origin.x, fixedImage.size.width - rect.width)),
            y: max(0, min(rect.origin.y, fixedImage.size.height - rect.height)),
            width: min(rect.width, fixedImage.size.width),
            height: min(rect.height, fixedImage.size.height)
        )
        
        guard let croppedCGImage = cgImage.cropping(to: boundedRect) else {
            print("Error: Could not crop CGImage to rect \(boundedRect)")
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: fixedImage.scale, orientation: .up)
        print("Successfully cropped image to size \(croppedImage.size)")
        return croppedImage
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        print("Processing image of size \(image.size)")
        
        // For bourbon bottles, we want to maintain a square aspect ratio
        let targetSize = CGSize(width: 2000, height: 2000)
        
        print("Resizing image to \(targetSize)")
        
        // Create a new image context with the target size
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        
        // Calculate the drawing rect to maintain aspect ratio
        let aspectRatio = image.size.width / image.size.height
        var drawingRect: CGRect
        
        if aspectRatio > 1 {
            // Image is wider than tall
            let height = targetSize.width / aspectRatio
            drawingRect = CGRect(x: 0, y: (targetSize.height - height) / 2,
                               width: targetSize.width, height: height)
        } else {
            // Image is taller than wide
            let width = targetSize.height * aspectRatio
            drawingRect = CGRect(x: (targetSize.width - width) / 2, y: 0,
                               width: width, height: targetSize.height)
        }
        
        image.draw(in: drawingRect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let finalImage = resizedImage {
            print("Successfully processed image to size \(finalImage.size)")
            return finalImage
        } else {
            print("Error: Failed to resize image")
            return image
        }
    }
} 