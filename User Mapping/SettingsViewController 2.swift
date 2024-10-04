//
//  SettingsViewController 2.swift
//  User Mapping
//
//  Created by Richard Lowe on 04/10/2024.
//

import UIKit

class SettingsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var weightTextField: UITextField!

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load saved weight
        if let weight = UserDefaults.standard.value(forKey: "userWeight") as? Double {
            weightTextField.text = "\(weight)"
        }
    }

    // MARK: - Actions
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let weightText = weightTextField.text,
              let weight = Double(weightText), weight > 0 else {
            showAlert(message: "Please enter a valid weight.")
            return
        }

        // Save weight to UserDefaults
        UserDefaults.standard.set(weight, forKey: "userWeight")
        showAlert(message: "Weight saved successfully.")
    }

    // Helper method to show alerts
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Settings", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
