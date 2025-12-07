//
//  OnboardingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 11/11/25.
//
import UIKit
import FirebaseAuth

class OnboardingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleSelectionTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    private let rolePicker = UIPickerView()
    private let roles = ["Buyer", "Seller"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRolePicker()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset form when view appears (important after logout)
        resetForm()
    }
    
    private func resetForm() {
        // Clear text fields
        emailTextField.text = ""
        passwordTextField.text = ""
        
        // Reset role picker to first option (Buyer)
        rolePicker.selectRow(0, inComponent: 0, animated: false)
        roleSelectionTextField.text = roles.first
        
        // Re-enable login button
        loginButton.isEnabled = true
    }

    private func setupUI() {
        loginButton.layer.cornerRadius = 8
    }

    private func setupRolePicker() {
        rolePicker.delegate = self
        rolePicker.dataSource = self
        roleSelectionTextField.inputView = rolePicker
        roleSelectionTextField.text = roles.first
        addDoneToolbar()
    }

    private func addDoneToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .plain,
                                         target: self,
                                         action: #selector(dismissPicker))
        toolbar.setItems([doneButton], animated: false)
        roleSelectionTextField.inputAccessoryView = toolbar
    }

    @objc func dismissPicker() {
        view.endEditing(true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { roles.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { roles[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        roleSelectionTextField.text = roles[row]
    }

    // MARK: - Navigation WITHOUT segues
    private func navigateToNextScreen() {
        let role = roleSelectionTextField.text?.lowercased() ?? ""
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if role.starts(with: "buyer") {
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? UIViewController,
               let navController = self.navigationController {
                navController.pushViewController(exploreVC, animated: true)
            }
        } else if role.starts(with: "seller") {
            if let sellerVC = storyboard.instantiateViewController(withIdentifier: "sellerListing") as? UIViewController,
               let navController = self.navigationController {
                navController.pushViewController(sellerVC, animated: true)
            }
        } else {
            print("Invalid role selected.")
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter both email and password.")
            return
        }

        loginButton.isEnabled = false

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            // Ensure button is re-enabled regardless of outcome
            defer { self?.loginButton.isEnabled = true }

            if let error = error {
                self?.handleLoginError(error)
                return
            }

            self?.navigateToNextScreen()
        }
    }
    
    // MARK: - Error Handling
    
    private func handleLoginError(_ error: Error) {
        // Check if the error is a Firebase Auth Error and extract the code
        guard let authError = AuthErrorCode(rawValue: (error as NSError).code) else {
            // Fallback for non-Firebase errors (e.g., general networking errors)
            showAlert(title: "Login Failed", message: error.localizedDescription)
            return
        }
        
        let title = "Login Failed"
        
        // Switch on the AuthErrorCode enum itself
        switch authError {
        case .wrongPassword:
            showAlert(title: title, message: "The password you entered is incorrect. Please try again.")
            
        case .userNotFound:
            showAlert(title: title, message: "There is no account associated with this email address. Please check your email or sign up for a new account.")
            
        case .invalidEmail:
            showAlert(title: title, message: "The email address you entered is not valid. Please check and try again.")
            
        case .userDisabled:
            showAlert(title: title, message: "This account has been disabled. Please contact support for assistance.")
            
        case .networkError:
            showAlert(title: "Network Error", message: "Unable to connect to the server. Please check your internet connection and try again.")
            
        case .tooManyRequests:
            showAlert(title: "Too Many Attempts", message: "Too many failed login attempts. Please try again later.")
            
        default:
            // Use the error's built-in localized description for other errors
            showAlert(title: title, message: error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
