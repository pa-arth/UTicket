//
//  OnboardingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 11/11/25.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class OnboardingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleSelectionTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    private let rolePicker = UIPickerView()
    private let roles = ["", "Buyer", "Seller"] // Empty string as default first option

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRolePicker()
        setupUI()
        
        // Setup text field styling
        setupTextFieldStyling(emailTextField)
        setupTextFieldStyling(passwordTextField)
        setupTextFieldStyling(roleSelectionTextField)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if user is already signed in (e.g., after account creation)
        // If so, automatically navigate to the appropriate dashboard
        if let currentUser = Auth.auth().currentUser {
            // User is already authenticated, navigate directly
            autoNavigateForAuthenticatedUser()
            return
        }
        
        // Reset form when view appears (important after logout)
        resetForm()
    }
    
    // Automatically navigate if user is already authenticated
    private func autoNavigateForAuthenticatedUser() {
        // Try to get role from UserDefaults first
        var savedRole = UserDefaults.standard.string(forKey: "userRole") ?? ""
        
        // If not in UserDefaults, try Firestore
        if savedRole.isEmpty, let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(uid).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let document = document, document.exists {
                    if let role = document.data()?["role"] as? String {
                        savedRole = role
                        UserDefaults.standard.set(role, forKey: "userRole")
                    }
                }
                
                // Navigate after checking Firestore
                DispatchQueue.main.async {
                    self.navigateBasedOnRole(savedRole)
                }
            }
            return
        }
        
        // Navigate immediately if we have a role from UserDefaults
        navigateBasedOnRole(savedRole)
    }
    
    private func navigateBasedOnRole(_ role: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let roleLower = role.lowercased()
        
        // Default to Buyer if no role is saved
        let normalizedRole: String
        if roleLower.starts(with: "buyer") || role.isEmpty {
            normalizedRole = "Buyer"
        } else if roleLower.starts(with: "seller") {
            normalizedRole = "Seller"
        } else {
            normalizedRole = "Buyer"
        }
        
        // Save the role if it wasn't already saved
        if role != normalizedRole {
            UserDefaults.standard.set(normalizedRole, forKey: "userRole")
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData([
                    "role": normalizedRole
                ], merge: true)
            }
        }
        
        // Navigate to appropriate screen
        if normalizedRole == "Buyer" {
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? UIViewController,
               let navController = self.navigationController {
                navController.setViewControllers([exploreVC], animated: true)
            }
        } else if normalizedRole == "Seller" {
            if let sellerVC = storyboard.instantiateViewController(withIdentifier: "sellerListing") as? UIViewController,
               let navController = self.navigationController {
                navController.setViewControllers([sellerVC], animated: true)
            }
        }
    }
    
    private func resetForm() {
        // Clear text fields
        emailTextField.text = ""
        passwordTextField.text = ""
        
        // Reset role picker to blank and select first row (empty value)
        roleSelectionTextField.text = ""
        rolePicker.selectRow(0, inComponent: 0, animated: false)
        
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
        roleSelectionTextField.text = ""
        // Start picker on first row (empty value)
        rolePicker.selectRow(0, inComponent: 0, animated: false)
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
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let role = roles[row]
        // Return empty string or the role name
        return role.isEmpty ? "" : role
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRole = roles[row]
        // Only set text if a role was selected (not empty)
        if !selectedRole.isEmpty {
            roleSelectionTextField.text = selectedRole
        } else {
            roleSelectionTextField.text = ""
        }
    }

    // MARK: - Navigation WITHOUT segues
    private func navigateToNextScreen() {
        // Get the role from text field and normalize it
        let roleText = roleSelectionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let role = roleText.lowercased()
        
        // Determine the proper role name (capitalized)
        let normalizedRole: String
        if role.starts(with: "buyer") {
            normalizedRole = "Buyer"
        } else if role.starts(with: "seller") {
            normalizedRole = "Seller"
        } else {
            // Default to Buyer if no valid role selected
            normalizedRole = "Buyer"
        }
        
        // Save the role to UserDefaults
        UserDefaults.standard.set(normalizedRole, forKey: "userRole")
        print("✅ Saved role to UserDefaults: \(normalizedRole)")
        
        // Save to Firestore if user is logged in
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData([
                "role": normalizedRole
            ], merge: true) { error in
                if let error = error {
                    print("Error saving role to Firestore: \(error.localizedDescription)")
                } else {
                    print("✅ Saved role to Firestore: \(normalizedRole)")
                }
            }
        }
        
        // Navigate to the appropriate screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if normalizedRole == "Buyer" {
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? UIViewController,
               let navController = self.navigationController {
                navController.pushViewController(exploreVC, animated: true)
            }
        } else if normalizedRole == "Seller" {
            if let sellerVC = storyboard.instantiateViewController(withIdentifier: "sellerListing") as? UIViewController,
               let navController = self.navigationController {
                navController.pushViewController(sellerVC, animated: true)
            }
        } else {
            print("Invalid role selected.")
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            // User is already authenticated, just navigate
            print("User already authenticated: \(currentUser.email ?? "unknown")")
            navigateToNextScreen()
            return
        }
        
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
            
        case .invalidCredential:
            // Handle expired or invalid credentials
            // If user is already signed in, try to navigate instead
            if Auth.auth().currentUser != nil {
                // User is already authenticated, navigate directly
                navigateToNextScreen()
            } else {
                showAlert(title: "Invalid Credentials", message: "The credentials you entered are invalid or have expired. Please try again.")
            }
            
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
    
    // MARK: - Text Field Styling
    
    /// Sets up text field styling with active outline color
    func setupTextFieldStyling(_ textField: UITextField) {
        // Set delegate to handle editing state changes
        textField.delegate = self
        
        // Set initial border properties
        textField.layer.borderWidth = 0
        textField.layer.cornerRadius = 5
        
        // Add observers for editing state
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
    }
    
    @objc func textFieldDidBeginEditing(_ textField: UITextField) {
        // Apply active outline color
        textField.layer.borderWidth = 2.0
        textField.layer.borderColor = UIColor(hex: "#BF5700")?.cgColor
    }
    
    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        // Remove outline when editing ends
        textField.layer.borderWidth = 0
        textField.layer.borderColor = nil
    }
}

// MARK: - UITextFieldDelegate
extension OnboardingViewController: UITextFieldDelegate {
    // Delegate methods can be overridden if needed
}
