import UIKit
import MapKit
import CoreLocation

protocol LocationSelectionViewControllerDelegate: AnyObject {
    func locationSelectionViewController(_ controller: LocationSelectionViewController, didSelectLocation location: LocationOption)
}

class LocationSelectionViewController: UIViewController {
    weak var delegate: LocationSelectionViewControllerDelegate?
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let manualEntryButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let noResultsLabel = UILabel()
    
    private var locations: [LocationOption] = []
    private var filteredLocations: [LocationOption] = []
    private var currentLocation: CLLocation?
    private let maxDistance: Double = 0.25 // 0.25 miles (402.336 meters)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LocationSelectionViewController: viewDidLoad")
        setupUI()
        setupNavigationBar()
        // Don't start search here - wait for viewWillAppear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("LocationSelectionViewController: viewWillAppear")
        
        // Only start search if we haven't already
        if locations.isEmpty {
            searchNearbyLocations()
        }
        
        // Ensure table view is properly configured
        if tableView.window == nil {
            print("LocationSelectionViewController: Table view not in window, deferring layout")
            return
        }
        
        print("LocationSelectionViewController: Table view frame: \(tableView.frame)")
        print("LocationSelectionViewController: Table view is hidden: \(tableView.isHidden)")
        print("LocationSelectionViewController: Number of locations: \(locations.count)")
        print("LocationSelectionViewController: Number of filtered locations: \(filteredLocations.count)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("LocationSelectionViewController: viewDidAppear")
        
        // Ensure table view is in window before any layout
        guard tableView.window != nil else {
            print("LocationSelectionViewController: Table view still not in window")
            return
        }
        
        print("LocationSelectionViewController: Table view frame: \(tableView.frame)")
        print("LocationSelectionViewController: Table view is hidden: \(tableView.isHidden)")
        print("LocationSelectionViewController: Table view window: \(String(describing: tableView.window))")
        
        // Reload table view if needed
        if !filteredLocations.isEmpty {
            tableView.reloadData()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Select Location"
        
        // Search Bar
        searchBar.placeholder = "Search locations"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Manual Entry Button
        manualEntryButton.setTitle("Enter Location Manually", for: .normal)
        manualEntryButton.addTarget(self, action: #selector(manualEntryTapped), for: .touchUpInside)
        manualEntryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(manualEntryButton)
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // No Results Label
        noResultsLabel.text = "No locations found"
        noResultsLabel.textAlignment = .center
        noResultsLabel.textColor = .secondaryLabel
        noResultsLabel.isHidden = true
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noResultsLabel)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            manualEntryButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            manualEntryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            manualEntryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: manualEntryButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func searchNearbyLocations() {
        print("LocationSelectionViewController: Starting nearby location search")
        activityIndicator.startAnimating()
        noResultsLabel.isHidden = true
        
        LocationService.shared.requestLocationAuthorization { [weak self] isAuthorized in
            guard let self = self else { return }
            print("LocationSelectionViewController: Location authorization status: \(isAuthorized)")
            
            if isAuthorized {
                LocationService.shared.getCurrentLocation { [weak self] location in
                    guard let self = self else { return }
                    print("LocationSelectionViewController: Got current location: \(String(describing: location?.coordinate))")
                    
                    if let location = location {
                        self.currentLocation = location
                        self.performLocationSearch(near: location)
                    } else {
                        print("LocationSelectionViewController: No location available")
                        self.showLocationError()
                    }
                }
            } else {
                print("LocationSelectionViewController: Location authorization denied")
                self.showLocationError()
            }
        }
    }
    
    private func performLocationSearch(near location: CLLocation) {
        print("LocationSelectionViewController: Performing location search near \(location.coordinate)")
        
        // Create a more precise search region
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 402.336, // 0.25 miles
            longitudinalMeters: 402.336  // 0.25 miles
        )
        print("LocationSelectionViewController: Search region - center: \(region.center), span: \(region.span)")
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "liquor store OR spirits shop OR wine shop OR grocery store OR supermarket OR Old Vernon Liquors"
        searchRequest.region = region
        searchRequest.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if let error = error {
                    print("LocationSelectionViewController: Search error: \(error.localizedDescription)")
                    self.showLocationError()
                    return
                }
                
                guard let response = response else {
                    print("LocationSelectionViewController: No response from search")
                    self.showLocationError()
                    return
                }
                
                print("LocationSelectionViewController: Found \(response.mapItems.count) locations")
                
                // Convert map items to location options with distances
                self.locations = response.mapItems.compactMap { item -> LocationOption? in
                    guard let itemLocation = item.placemark.location else {
                        print("LocationSelectionViewController: Skipping location - no location data")
                        return nil
                    }
                    
                    // Log the raw coordinates for debugging
                    print("LocationSelectionViewController: Processing location - \(item.name ?? "Unknown"):")
                    print("  - Raw coordinates: \(item.placemark.coordinate)")
                    print("  - Current location: \(location.coordinate)")
                    
                    let distance = itemLocation.distance(from: location)
                    let distanceInMiles = distance / 1609.34 // Convert meters to miles
                    
                    print("  - Calculated distance: \(String(format: "%.2f", distance)) meters (\(String(format: "%.2f", distanceInMiles)) miles)")
                    
                    // Only include locations within maxDistance
                    guard distanceInMiles <= self.maxDistance else {
                        print("  - Skipping: Too far (\(String(format: "%.1f", distanceInMiles)) miles)")
                        return nil
                    }
                    
                    let location = LocationOption(
                        name: item.name ?? "Unknown Location",
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude,
                        distance: distanceInMiles
                    )
                    print("  - Added location: \(location.name) (\(String(format: "%.1f", distanceInMiles)) miles)")
                    return location
                }
                
                // Sort by distance
                self.locations.sort { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
                self.filteredLocations = self.locations
                
                // If there's exactly one location within range, automatically select it
                if self.locations.count == 1 {
                    print("LocationSelectionViewController: Found exactly one location within range, auto-selecting")
                    DispatchQueue.main.async {
                        self.delegate?.locationSelectionViewController(self, didSelectLocation: self.locations[0])
                        self.dismiss(animated: true)
                        return
                    }
                }
                
                // Update UI only if view is in window
                if self.tableView.window != nil {
                    self.noResultsLabel.isHidden = !self.filteredLocations.isEmpty
                    print("LocationSelectionViewController: Reloading table view with \(self.filteredLocations.count) locations")
                    self.tableView.reloadData()
                    print("LocationSelectionViewController: Search complete - found \(self.locations.count) locations within \(self.maxDistance) miles")
                    print("LocationSelectionViewController: Table view frame after reload: \(self.tableView.frame)")
                    print("LocationSelectionViewController: Table view is hidden after reload: \(self.tableView.isHidden)")
                    print("LocationSelectionViewController: Table view window after reload: \(String(describing: self.tableView.window))")
                } else {
                    print("LocationSelectionViewController: Table view not in window, deferring reload")
                }
            }
        }
    }
    
    private func showLocationError() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.noResultsLabel.text = "Unable to find nearby locations"
            self.noResultsLabel.isHidden = false
        }
    }
    
    @objc private func manualEntryTapped() {
        let alert = UIAlertController(
            title: "Enter Location",
            message: "Type the name of the location",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Location name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let locationName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !locationName.isEmpty else { return }
            
            let location = LocationOption(
                name: locationName,
                latitude: nil,
                longitude: nil,
                distance: nil
            )
            
            self.delegate?.locationSelectionViewController(self, didSelectLocation: location)
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension LocationSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("LocationSelectionViewController: numberOfRowsInSection called - returning \(filteredLocations.count)")
        return filteredLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("LocationSelectionViewController: cellForRowAt called for index \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let location = filteredLocations[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = location.name
        
        // Safely format the distance with validation
        if let distance = location.distance, distance.isFinite {
            let formattedDistance = String(format: "%.1f", distance)
            content.secondaryText = "\(formattedDistance) miles away"
        } else {
            content.secondaryText = nil
        }
        
        // Configure text properties
        content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .secondaryLabel
        
        // Apply configuration
        cell.contentConfiguration = content
        
        // Ensure proper cell reuse
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        
        print("LocationSelectionViewController: Configured cell for location: \(location.name)")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let location = filteredLocations[indexPath.row]
        delegate?.locationSelectionViewController(self, didSelectLocation: location)
        dismiss(animated: true)
    }
}

extension LocationSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredLocations = locations
        } else {
            filteredLocations = locations.filter { location in
                location.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        noResultsLabel.isHidden = !filteredLocations.isEmpty
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
} 