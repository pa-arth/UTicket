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
            
            // 🔑 Load Email from Firebase Auth
            loadUserEmail() // ⚠️ Call new function
            emailDisplayTextField.isEnabled = false // Ensure it cannot be edited
            
            // Add tap gesture for photo upload
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadPhotoTapped))
            profilePhotoArea.addGestureRecognizer(tapGesture)
            profilePhotoArea.isUserInteractionEnabled = true
        }

        // MARK: - Firebase Functions

        // Fetches the currently authenticated user's email
        private func loadUserEmail() {
            if let user = Auth.auth().currentUser {
                self.emailDisplayTextField.text = user.email
            } else {
                // Handle case where no user is logged in (e.g., prompt for login)
                self.emailDisplayTextField.text = "Error: No User Logged In"
                print("Error: No Firebase Auth user found.")
            }
        }

        // Saves the user's profile data to Firestore
        private func saveProfileData(fullName: String, phone: String) {
            // 1. Get the current user ID
            guard let uid = Auth.auth().currentUser?.uid else {
                print("Error: User not authenticated.")
                // Optionally show an alert to the user
                return
            }

            // 2. Prepare the data payload
            let profileData: [String: Any] = [
                "fullName": fullName,
                "phone": phone,
                "email": emailDisplayTextField.text ?? "", // Use the displayed email
                "createdAt": FieldValue.serverTimestamp() // Good practice to track creation time
                // Add a field for 'profilePhotoURL' later when implementing storage
            ]

            // 3. Write data to Firestore at "users/{uid}"
            db.collection("users").document(uid).setData(profileData, merge: true) { error in
                if let error = error {
                    print("Error saving profile data: \(error.localizedDescription)")
                    // Optionally show an alert to the user about the error
                } else {
                    print("Profile data successfully saved for user: \(uid)")
                    // 4. Navigate on success
                    self.navigateToTicketListing()
                }
            }
        }
        
    // ---
        
        // MARK: - Actions (IBActions)
        @IBAction func createProfileButtonTapped(_ sender: UIButton) {
            // Ensure email field has a value (should be pre-filled from auth)
            guard let email = emailDisplayTextField.text, !email.isEmpty else {
                print("Email is missing. Cannot save profile.")
                // Handle error (e.g., re-authenticate, show error message)
                return
            }
            
            // Basic field validation
            guard let fullName = fullNameTextField.text, !fullName.isEmpty,
                  let phone = phoneTextField.text, !phone.isEmpty else {
                print("Please fill in all required fields (Full Name and Phone).")
                return
            }

            // 🔑 Call the new Firebase save function
            saveProfileData(fullName: fullName, phone: phone)
        }

    // ---
        
        // MARK: - Image Picker Logic
        // ... (Image Picker code is left as is, but you'd implement Firebase Storage inside didFinishPickingMediaWithInfo)
        
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
            // 1. Display the selected image in the profilePhotoArea (requires profilePhotoArea to be an UIImageView)
            // 2. Upload the image to Firebase Storage
            // 3. Save the returned image URL to the user's profile in the database
            print("Image selected and ready for upload to Firebase Storage. This still needs to be implemented.")
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
