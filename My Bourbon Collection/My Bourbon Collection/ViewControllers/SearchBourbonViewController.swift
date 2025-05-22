import UIKit

class SearchBourbonViewController: UIViewController {
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var bourbons: [Bourbon] = []
    private var filteredBourbons: [Bourbon] = []
    private var isSearching = false
    private var selectedRating: Int = 0
    private let ratingSegmentedControl = UISegmentedControl(items: ["All", "👎", "👌", "👍"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadBourbons()
    }
    
    private func setupNavigationBar() {
        title = "Search Bourbons"
        
        // Back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Search Bar
        searchBar.placeholder = "Search bourbons..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .systemBackground
        searchBar.showsCancelButton = true
        view.addSubview(searchBar)
        
        // Rating Segmented Control
        ratingSegmentedControl.selectedSegmentIndex = 0
        ratingSegmentedControl.addTarget(self, action: #selector(ratingChanged(_:)), for: .valueChanged)
        view.addSubview(ratingSegmentedControl)
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BourbonCell.self, forCellReuseIdentifier: "BourbonCell")
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 80
        view.addSubview(tableView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        ratingSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            ratingSegmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            ratingSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ratingSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ratingSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: ratingSegmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadBourbons() {
        bourbons = BourbonDatabase.shared.getAllBourbons()
        filterBourbons(with: searchBar.text ?? "")
    }
    
    private func filterBourbons(with searchText: String) {
        let searchText = searchText.lowercased()
        
        filteredBourbons = bourbons.filter { bourbon in
            let matchesSearch = searchText.isEmpty ||
                bourbon.name.lowercased().contains(searchText) ||
                bourbon.purchaseLocation.lowercased().contains(searchText) ||
                bourbon.flavorProfile.lowercased().contains(searchText) ||
                bourbon.notes.lowercased().contains(searchText)
            
            let matchesRating = selectedRating == 0 || bourbon.rating == selectedRating
            
            return matchesSearch && matchesRating
        }
        
        isSearching = !searchText.isEmpty || selectedRating > 0
        tableView.reloadData()
    }
    
    @objc private func ratingChanged(_ sender: UISegmentedControl) {
        selectedRating = sender.selectedSegmentIndex
        filterBourbons(with: searchBar.text ?? "")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension SearchBourbonViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterBourbons(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        selectedRating = 0
        ratingSegmentedControl.selectedSegmentIndex = 0
        isSearching = false
        filteredBourbons = []
        tableView.reloadData()
        searchBar.resignFirstResponder()
        view.endEditing(true)
    }
}

extension SearchBourbonViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredBourbons.count : bourbons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BourbonCell", for: indexPath) as! BourbonCell
        let bourbon = isSearching ? filteredBourbons[indexPath.row] : bourbons[indexPath.row]
        cell.configure(with: bourbon)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        let bourbon = isSearching ? filteredBourbons[indexPath.row] : bourbons[indexPath.row]
        let detailVC = BourbonDetailViewController(bourbon: bourbon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
} 