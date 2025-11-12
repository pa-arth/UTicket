//
//  OnboardingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 11/11/25.
//
import UIKit
import FirebaseAuth // Required for Firebase Login

// 🔑 Must conform to the PickerView protocols
class OnboardingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - UI Connections (IBOutlets)
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleSelectionTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // 🔑 Role Selection Properties
    private let rolePicker = UIPickerView()
    private let roles = ["Buyer", "Seller"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRolePicker() // 🔑 Call new setup function
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        // Example: Optional styling
        loginButton.layer.cornerRadius = 8
    }

    // 🔑 Setup the Picker View
    private func setupRolePicker() {
        rolePicker.delegate = self
        rolePicker.dataSource = self
        
        // 1. Set the PickerView as the input view for the TextField
        roleSelectionTextField.inputView = rolePicker
        
        // 2. Set an initial default value
        roleSelectionTextField.text = roles.first
        
        // 3. Add a toolbar/Done button to dismiss the picker
        addDoneToolbar()
    }
    
    // 🔑 Add a Done button above the picker for dismissal
    private func addDoneToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissPicker))
        toolbar.setItems([doneButton], animated: false)
        roleSelectionTextField.inputAccessoryView = toolbar
    }

    @objc func dismissPicker() {
        view.endEditing(true) // Dismisses the input view (the picker)
    }

    // MARK: - UIPickerViewDataSource Methods

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return roles.count
    }

    // MARK: - UIPickerViewDelegate Methods

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return roles[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Update the text field with the selected value
        roleSelectionTextField.text = roles[row]
    }

    // MARK: - Navigation Helper
    /**
     Determines the next screen based on the selected role and performs the segue.
     - Parameter email: The email of the successfully logged-in user.
     */
    private func navigateToNextScreen(email: String) {
        // Get the selected role, defaulting to an empty string if nil
        let role = roleSelectionTextField.text?.lowercased() ?? ""

        // Use starts(with:) for safer matching
        if role.starts(with: "buyer") {
            // Buyer Role: Go to the main exploration/ticket listing screen
            performSegue(withIdentifier: "showExplore", sender: nil)
        } else if role.starts(with: "seller") {
            // Seller Role: Go to the profile creation screen to finish setup
            performSegue(withIdentifier: "showProfileCreation", sender: email)
        } else {
            // This should rarely happen now that selection is forced
            print("Error: Invalid role selected for navigation.")
        }
    }

    // MARK: - Actions (IBActions)
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // 1. Basic Validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert to user to fill in all fields
            print("Validation Error: Please enter email and password.")
            return
        }

        // Optional: Disable button and show activity indicator while logging in
        loginButton.isEnabled = false

        // 2. Firebase Login Attempt
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            // Re-enable button after the attempt
            self?.loginButton.isEnabled = true

            if let error = error {
                // Handle Firebase login error (e.g., wrong password, user not found)
                print("Login failed: \(error.localizedDescription)")
                // Show an alert to the user with the error message
                return
            }

            // 3. Successful Login
            guard let userEmail = authResult?.user.email else {
                print("Error: Logged in but user email is nil.")
                return
            }
            
            // Navigate based on the selected role
            self?.navigateToNextScreen(email: userEmail)
        }
    }

    // MARK: - Segue Preparation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfileCreation",
           let email = sender as? String,
           let dest = segue.destination as? ProfileCreationViewController {
            
            // Check to make sure the IBOutlet is loaded before accessing it
            dest.loadViewIfNeeded()
            dest.emailDisplayTextField.text = email
        }
    }
}
