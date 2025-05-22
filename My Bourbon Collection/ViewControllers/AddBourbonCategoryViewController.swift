import UIKit

enum BourbonCategory: String, CaseIterable {
    case purchases = "Purchases"
    case tastings = "Tastings"
    case infinity = "Infinity"
}

class AddBourbonCategoryViewController: UIViewController {
    private let categoryLabel = UILabel()
    private let categoryPicker = UIPickerView()
    private let continueButton = UIButton(type: .system)
    private let categories = BourbonCategory.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Set initial title based on first category
        updateTitle(for: categories[0])
        print("Initial title set to: \(title ?? "nil")")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Category Label
        categoryLabel.text = "Category"
        categoryLabel.font = .systemFont(ofSize: 18, weight: .medium)
        categoryLabel.textAlignment = .left
        view.addSubview(categoryLabel)
        
        // Category Picker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        view.addSubview(categoryPicker)
        
        // Continue Button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 10
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        view.addSubview(continueButton)
        
        // Setup constraints
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryPicker.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            categoryPicker.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 20),
            categoryPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryPicker.heightAnchor.constraint(equalToConstant: 200),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateTitle(for category: BourbonCategory) {
        print("Updating title for category: \(category.rawValue)")
        switch category {
        case .purchases:
            title = "Add New Bourbon"
        case .tastings:
            title = "Add New Tasting"
        case .infinity:
            title = "Add New Bourbon" // Keep default title for now
        }
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
        print("Title updated to: \(title ?? "nil")")
    }
    
    @objc private func continueButtonTapped() {
        print("AddBourbonCategoryViewController: continueButtonTapped")
        guard let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)] else { 
            print("AddBourbonCategoryViewController: No category selected")
            return 
        }
        print("AddBourbonCategoryViewController: Selected category: \(selectedCategory.rawValue)")
        
        switch selectedCategory {
        case .purchases:
            print("AddBourbonCategoryViewController: Creating AddBourbonViewController")
            let addBourbonVC = AddBourbonViewController()
            addBourbonVC.title = "Add New Bourbon"
            navigationController?.pushViewController(addBourbonVC, animated: true)
        case .tastings:
            print("AddBourbonCategoryViewController: Creating AddTastingViewController")
            let addTastingVC = AddTastingViewController()
            print("AddBourbonCategoryViewController: Created AddTastingViewController")
            addTastingVC.title = "Add New Tasting"
            addTastingVC.delegate = self
            print("AddBourbonCategoryViewController: About to push AddTastingViewController")
            navigationController?.pushViewController(addTastingVC, animated: true)
            print("AddBourbonCategoryViewController: Pushed AddTastingViewController")
        case .infinity:
            print("AddBourbonCategoryViewController: Showing infinity alert")
            let alert = UIAlertController(
                title: "Coming Soon",
                message: "Infinity Bottle feature is under development.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension AddBourbonCategoryViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Picker did select row: \(row)")
        let selectedCategory = categories[row]
        updateTitle(for: selectedCategory)
    }
}

extension AddBourbonCategoryViewController: AddBourbonViewControllerDelegate {
    func addBourbonViewControllerDidAddBourbon(_ controller: AddBourbonViewController) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension AddBourbonCategoryViewController: AddTastingViewControllerDelegate {
    func addTastingViewControllerDidAddTasting(_ controller: AddTastingViewController) {
        navigationController?.popToRootViewController(animated: true)
    }
} 