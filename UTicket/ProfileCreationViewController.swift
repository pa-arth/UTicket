//
//  ProfileCreationViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 10/20/25.
//
import UIKit

class ProfileCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI Connections (IBOutlets)
    @IBOutlet weak var profilePhotoArea: UIView! // Or an UIImageView for simplicity
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailDisplayTextField: UITextField! // The pre-filled, non-editable email field

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 🔑 Email Placeholder: Set the initial email from the login screen
        // You'll need to pass the email from OnboardingViewController
        emailDisplayTextField.text = "swarnakadagadkai@utexas.edu" // Replace with passed value
        emailDisplayTextField.isEnabled = false // Ensure it cannot be edited
        
        // Add tap gesture for photo upload
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadPhotoTapped))
        profilePhotoArea.addGestureRecognizer(tapGesture)
        profilePhotoArea.isUserInteractionEnabled = true
    }

    // MARK: - Actions (IBActions)
    @IBAction func createProfileButtonTapped(_ sender: UIButton) {
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            print("Please fill in all required fields.")
            return
        }

        // 🔑 Save Profile Data Placeholder
        // Use your Firebase Firestore/Realtime Database to save the user's profile data
        let profileData = ["fullName": fullName, "phone": phone, "email": emailDisplayTextField.text!]
        print("Saving profile data: \(profileData)")
        
        // Navigate to the next screen (Ticket Listing)
        navigateToTicketListing()
    }
    
    // MARK: - Image Picker Logic
    @objc func uploadPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary // or .camera
        present(picker, animated: true)
    }
    
    // UIImagePickerControllerDelegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        // 🔑 Image Upload Placeholder
        // 1. Display the selected image in the profilePhotoArea
        // 2. Upload the image to Firebase Storage
        // 3. Save the returned image URL to the user's profile in the database
        print("Image selected and ready for upload to Firebase Storage.")
        // Example: profilePhotoArea.image = image (if it's an UIImageView)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // Placeholder function for navigation
    private func navigateToTicketListing() {
        // Implement Storyboard Segue or programmatic navigation here
        print("Navigating to Ticket Listing Screen...")
    }
}
