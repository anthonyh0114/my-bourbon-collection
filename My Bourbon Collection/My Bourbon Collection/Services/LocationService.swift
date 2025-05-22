import UIKit
import CoreLocation
import MapKit

class LocationService: NSObject {
    static let shared = LocationService()
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation? { _currentLocation }
    private var _currentLocation: CLLocation?
    private var geocoder = CLGeocoder()
    private var authorizationCompletion: ((Bool) -> Void)?
    private var locationUpdateCompletion: ((CLLocation?) -> Void)?
    private var lastScanTime: Date?
    private let minimumScanInterval: TimeInterval = 90 // Minimum 90 seconds between scans
    private var isSearching = false
    private var pendingSearchCompletion: ((String?) -> Void)?
    private var lastSearchLocation: CLLocation?
    private var lastSearchResult: String?
    private let searchResultCacheTime: TimeInterval = 30 // Cache results for 30 seconds
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update only when moved 100 meters
        print("LocationService: Initialized with accuracy: \(locationManager.desiredAccuracy), distance filter: \(locationManager.distanceFilter)")
    }
    
    func requestLocationAuthorization(completion: @escaping (Bool) -> Void) {
        print("LocationService: Requesting location authorization")
        authorizationCompletion = completion
        
        // Check current authorization status first
        let status = locationManager.authorizationStatus
        print("LocationService: Current authorization status: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationService: Already authorized")
            completion(true)
            // Start updating location immediately if authorized
            startUpdatingLocation()
        case .denied, .restricted:
            print("LocationService: Location access denied or restricted")
            completion(false)
        case .notDetermined:
            print("LocationService: Requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            print("LocationService: Unknown authorization status")
            completion(false)
        }
    }
    
    func startUpdatingLocation() {
        print("LocationService: Starting location updates")
        // Only start updating if we have authorization
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            print("LocationService: Not authorized to start location updates")
            return
        }
        
        // Clear any cached location to ensure fresh data
        _currentLocation = nil
        
        // Start updating location
        locationManager.startUpdatingLocation()
        print("LocationService: Location updates started")
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        if let location = currentLocation {
            completion(location)
            return
        }
        
        // If we don't have a location yet, start updating
        locationUpdateCompletion = completion
        locationManager.startUpdatingLocation()
    }
    
    func processLocation(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        // Create a region for searching
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 402.336, // 0.25 miles (reduced from 0.5)
            longitudinalMeters: 402.336  // 0.25 miles (reduced from 0.5)
        )
        
        print("LocationService: Starting search from coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Go straight to general search
        performGeneralSearch(location: location, region: region, completion: completion)
    }
    
    private func performGeneralSearch(location: CLLocation, region: MKCoordinateRegion, completion: @escaping (String?) -> Void) {
        print("LocationService: Performing general search")
        print("LocationService: Search region center: \(region.center.latitude), \(region.center.longitude)")
        
        // Create multiple overlapping regions to get more comprehensive results
        let regions = [
            // Center region
            MKCoordinateRegion(
                center: region.center,
                latitudinalMeters: 201.168, // 0.125 miles
                longitudinalMeters: 201.168  // 0.125 miles
            ),
            // North region
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: region.center.latitude + (region.span.latitudeDelta * 0.25),
                    longitude: region.center.longitude
                ),
                latitudinalMeters: 201.168,
                longitudinalMeters: 201.168
            ),
            // South region
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: region.center.latitude - (region.span.latitudeDelta * 0.25),
                    longitude: region.center.longitude
                ),
                latitudinalMeters: 201.168,
                longitudinalMeters: 201.168
            ),
            // East region
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude + (region.span.longitudeDelta * 0.25)
                ),
                latitudinalMeters: 201.168,
                longitudinalMeters: 201.168
            ),
            // West region
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude - (region.span.longitudeDelta * 0.25)
                ),
                latitudinalMeters: 201.168,
                longitudinalMeters: 201.168
            )
        ]
        
        // Try multiple searches with different terms
        let searchTerms = [
            "liquor store",
            "spirits shop",
            "wine shop",
            "package store",
            "beverage store",
            "restaurant",
            "bar",
            "pub",
            "tavern",
            "distillery",
            "bourbon",
            "whiskey",
            "lounge",
            "grill",
            "cafe"
        ]
        
        var allResults: [MKMapItem] = []
        var processedTerms = 0
        let totalTerms = searchTerms.count * regions.count
        
        func performSearch(withTerm term: String, inRegion searchRegion: MKCoordinateRegion) {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = term
            searchRequest.region = searchRegion
            searchRequest.resultTypes = [.pointOfInterest, .address]
            
            print("LocationService: Searching with term: \(term) in region: \(searchRegion.center.latitude), \(searchRegion.center.longitude)")
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
                guard let self = self else { return }
                
                processedTerms += 1
                
            if let error = error {
                    print("LocationService: Search error for term '\(term)': \(error.localizedDescription)")
                } else if let response = response {
                    print("LocationService: Found \(response.mapItems.count) locations for term '\(term)' in region")
                    
                    // Add new results to our collection, avoiding duplicates
                    for item in response.mapItems {
                        if !allResults.contains(where: { existingItem in
                            existingItem.name == item.name &&
                            existingItem.placemark.coordinate.latitude == item.placemark.coordinate.latitude &&
                            existingItem.placemark.coordinate.longitude == item.placemark.coordinate.longitude
                        }) {
                            allResults.append(item)
                        }
                    }
                }
                
                // If this was the last search, process all results
                if processedTerms == totalTerms {
                    self.processSearchResults(allResults: allResults, location: location, completion: completion)
                }
            }
        }
        
        // Start all searches
        for region in regions {
            for term in searchTerms {
                performSearch(withTerm: term, inRegion: region)
            }
        }
    }
    
    private func processSearchResults(allResults: [MKMapItem], location: CLLocation, completion: @escaping (String?) -> Void) {
        print("LocationService: Processing \(allResults.count) total unique locations")
        
        // Log all found locations for debugging
        for (index, item) in allResults.enumerated() {
            guard let itemLocation = item.placemark.location else {
                print("LocationService: Location \(index + 1) has no location data")
                continue
            }
            
            let distance = itemLocation.distance(from: location)
            let distanceInMiles = distance / 1609.34
            
            print("LocationService: Location \(index + 1):")
            print("  - Name: \(item.name ?? "Unknown")")
            print("  - Coordinates: \(itemLocation.coordinate.latitude), \(itemLocation.coordinate.longitude)")
            print("  - Distance: \(String(format: "%.2f", distanceInMiles)) miles")
            print("  - Address: \(item.placemark.title ?? "No address")")
            print("  - Administrative Area: \(item.placemark.administrativeArea ?? "Unknown")")
            print("  - Locality: \(item.placemark.locality ?? "Unknown")")
            print("  - SubLocality: \(item.placemark.subLocality ?? "Unknown")")
            print("  - Thoroughfare: \(item.placemark.thoroughfare ?? "Unknown")")
            print("  - SubThoroughfare: \(item.placemark.subThoroughfare ?? "Unknown")")
        }
        
        // Process and filter locations
        let sortedLocations = allResults.compactMap { item -> MKMapItem? in
            guard let itemLocation = item.placemark.location,
                  itemLocation.coordinate.latitude.isFinite,
                  itemLocation.coordinate.longitude.isFinite else {
                print("LocationService: Skipping location - invalid coordinates")
                return nil
            }
            
            let distance = itemLocation.distance(from: location)
            let distanceInMiles = distance / 1609.34
            
            print("LocationService: Checking location: \(item.name ?? "Unknown")")
            print("  - Coordinates: \(itemLocation.coordinate.latitude), \(itemLocation.coordinate.longitude)")
            print("  - Distance: \(String(format: "%.2f", distanceInMiles)) miles")
            
            guard distanceInMiles <= 0.25 else { // Within 0.25 miles
                print("LocationService: Skipping location - too far (\(String(format: "%.1f", distanceInMiles)) miles)")
                return nil
            }
            
            print("LocationService: Keeping location - within range")
            return item
        }.sorted { item1, item2 in
            guard let location1 = item1.placemark.location,
                  let location2 = item2.placemark.location else {
                return false
            }
            let distance1 = location1.distance(from: location)
            let distance2 = location2.distance(from: location)
            return distance1 < distance2
        }
        
        if let closestLocation = sortedLocations.first {
            let businessName = closestLocation.name ?? "Unknown Location"
            let venueType = determineVenueType(from: closestLocation)
            let locationName = "\(businessName) (\(venueType))"
            
                print("LocationService: Found nearby business: \(locationName)")
                completion(locationName)
            } else {
            print("LocationService: No nearby businesses found in search")
            performReverseGeocoding(location: location, completion: completion)
        }
    }
    
    private func performReverseGeocoding(location: CLLocation, completion: @escaping (String?) -> Void) {
        print("LocationService: Falling back to reverse geocoding")
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("LocationService: Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                let locationName = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")
                
                print("LocationService: Got location name from reverse geocoding: \(locationName)")
                completion(locationName)
            } else {
                print("LocationService: No placemark found")
                completion(nil)
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let yards = distance * 1.09361
        if yards < 1760 {
            return String(format: "%.0f yd", yards)
        } else {
            let miles = yards / 1760
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func determineVenueType(from mapItem: MKMapItem) -> String {
        let name = mapItem.name?.lowercased() ?? ""
        let address = mapItem.placemark.title?.lowercased() ?? ""
        
        let groceryChains = [
            "kroger", "publix", "whole foods", "trader joe's", "walmart", "target", "costco",
            "safeway", "albertsons", "wegmans", "food lion", "giant eagle", "meijer", "aldi",
            "lidl", "sprouts", "harris teeter", "stop & shop", "shoprite", "king soopers"
        ]
        
        let liquorChains = [
            "total wine", "bevmo", "abc liquor", "spec's", "binny's", "liquor barn",
            "liquor store", "spirits", "wine & spirits", "wine spirits", "liquor & wine",
            "package store", "beverage store"
        ]

        let distilleryTerms = [
            "distillery", "bourbon", "whiskey", "whisky", "spirits", "craft spirits",
            "bourbon distillery", "whiskey distillery", "whisky distillery"
        ]
        
        // Check for grocery chains first
        if groceryChains.contains(where: { name.contains($0) }) {
            return "Grocery Store"
        }
        
        // Check for distilleries
        if distilleryTerms.contains(where: { name.contains($0) }) || 
           address.contains("distillery") || address.contains("bourbon") || 
           address.contains("whiskey") || address.contains("whisky") {
            return "Distillery"
        }
        
        // Check for liquor chains
        if liquorChains.contains(where: { name.contains($0) }) || 
           name.contains("liquor") || name.contains("spirits") || 
           address.contains("liquor") || address.contains("spirits") {
            return "Liquor Store"
        }
        
        // Check for bars and restaurants with more specific categorization
        if name.contains("bar") || name.contains("tavern") || name.contains("pub") {
            if name.contains("sports") || name.contains("grill") {
                return "Sports Bar"
            } else if name.contains("cocktail") || name.contains("craft") {
                return "Cocktail Bar"
            } else {
            return "Bar"
            }
        } else if name.contains("lounge") || name.contains("speakeasy") {
            return "Lounge"
        } else if name.contains("restaurant") || name.contains("grill") || 
                  name.contains("cafe") || name.contains("bistro") || 
                  name.contains("eatery") || name.contains("kitchen") {
            if name.contains("steak") || name.contains("chop") {
                return "Steakhouse"
            } else if name.contains("italian") || name.contains("pizza") {
                return "Italian Restaurant"
            } else if name.contains("american") || name.contains("grill") {
                return "American Restaurant"
            } else {
            return "Restaurant"
            }
        } else {
            return "Venue"
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationService: Authorization status changed to: \(manager.authorizationStatus.rawValue)")
        let isAuthorized = manager.authorizationStatus == .authorizedWhenInUse || 
                          manager.authorizationStatus == .authorizedAlways
        
        if isAuthorized {
            startUpdatingLocation()
        }
        
        authorizationCompletion?(isAuthorized)
        authorizationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Validate location coordinates
        guard location.coordinate.latitude.isFinite && location.coordinate.longitude.isFinite else {
            print("LocationService: Invalid location coordinates")
            return
        }
        
        print("LocationService: Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        _currentLocation = location
        locationUpdateCompletion?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: Location manager error: \(error.localizedDescription)")
        locationUpdateCompletion?(nil)
    }
} 