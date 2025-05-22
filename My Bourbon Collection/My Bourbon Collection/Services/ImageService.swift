import UIKit

class ImageService {
    static let shared = ImageService()
    
    private init() {}
    
    func loadImage(filename: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 