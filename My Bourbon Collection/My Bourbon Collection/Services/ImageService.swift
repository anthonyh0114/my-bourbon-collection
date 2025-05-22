import UIKit

class ImageService {
    static let shared = ImageService()
    
    private init() {}
    
    func loadImage(filename: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func saveImage(_ image: UIImage, filename: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return false
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 