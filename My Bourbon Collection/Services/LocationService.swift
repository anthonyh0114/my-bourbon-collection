// Simulator testing location
#if targetEnvironment(simulator)
private let simulatorLocation = CLLocation(latitude: 39.0110711, longitude: -85.6361825)
#endif 

// Create a smaller region for more precise searching
let smallerRegion = MKCoordinateRegion(
    center: region.center,
    latitudinalMeters: 402.336, // 0.25 miles
    longitudinalMeters: 402.336  // 0.25 miles
)

// ... existing code ...
                    guard distanceInMiles <= 0.25 else { // Updated to 0.25 miles
                        print("LocationService: Skipping location - too far (\(String(format: "%.1f", distanceInMiles)) miles)")
                        return nil
                    }
// ... existing code ... 

private func performGeneralSearch(location: CLLocation, region: MKCoordinateRegion, completion: @escaping (String?) -> Void) {
    print("LocationService: Performing general search")
    print("LocationService: Search region center: \(region.center.latitude), \(region.center.longitude)")
    print("LocationService: Search region span: \(region.span.latitudeDelta), \(region.span.longitudeDelta)")
    
    // Create a smaller region for more precise searching
    let smallerRegion = MKCoordinateRegion(
        center: region.center,
        latitudinalMeters: 402.336, // 0.25 miles
        longitudinalMeters: 402.336  // 0.25 miles
    )
    
    // Try multiple searches with different terms, using the current location's locality
    let searchTerms = [
        "liquor store",
        "spirits shop",
        "wine shop",
        "package store",
        "beverage store"
    ]
    
    // ... existing code ...
                    let distance = itemLocation.distance(from: location)
                    let distanceInMiles = distance / 1609.34
                    
                    print("LocationService: Checking location: \(item.name ?? "Unknown")")
                    print("  - Coordinates: \(itemLocation.coordinate.latitude), \(itemLocation.coordinate.longitude)")
                    print("  - Distance: \(String(format: "%.2f", distanceInMiles)) miles")
                    
                    guard distanceInMiles <= 0.25 else { // Updated to 0.25 miles
                        print("LocationService: Skipping location - too far (\(String(format: "%.1f", distanceInMiles)) miles)")
                        return nil
                    }
    // ... existing code ... 
} 