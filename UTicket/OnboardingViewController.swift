//
//  OnboardingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 10/20/25.
//
import UIKit
import FirebaseAuth // Required for Firebase Login

class OnboardingViewController: UIViewController {

    // MARK: - UI Connections (IBOutlets)
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleSelectionTextField: UITextField! // Or another element for role selection
    @IBOutlet weak var loginButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        // Placeholder for initial UI setup (e.g., setting button corner radius if not done in Storyboard)
    }
    // MARK: - Navigation Helper
    private func navigateToNextScreen(email: String) {
        let role = roleSelectionTextField.text?.lowercased() ?? ""
        if role.contains("buyer") {
            performSegue(withIdentifier: "showExplore", sender: email)          // → ExploreTickets
        } else {
            performSegue(withIdentifier: "showProfileCreation", sender: email)  // → ProfileCreation
        }
    }

    // MARK: - Actions (IBActions)
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Handle error: show alert to user
            print("Please enter email and password.")
            return
        }

        
        // TEMPORARY: Simulate successful login for navigation test
        Swift.print("Simulating login attempt with email: \(email)")
        navigateToNextScreen(email: email)

    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfileCreation",
           let email = sender as? String,
           let dest = segue.destination as? ProfileCreationViewController {
            dest.loadViewIfNeeded()
            dest.emailDisplayTextField.text = email
        }
    }

    
    // Placeholder function for navigation
    private func navigateToProfileCreation() {
        // Implement Storyboard Segue or programmatic navigation here
        print("Navigating to Profile Creation Screen...")
    }
}



// 🔑 Firebase Login Placeholder
// Use your Firebase SDK to sign the user in.
/*
Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
    if let error = error {
        // Handle Firebase login error
        print("Login failed: \(error.localizedDescription)")
        return
    }
    
    // Navigate to the next screen (e.g., Profile Creation) on successful login.
    self?.navigateToProfileCreation()
}
*/
