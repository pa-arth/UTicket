//
//  ProfileCreationViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 10/20/25.
//
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage // 1. 🔑 NEW IMPORT for Storage

class ProfileCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let db = Firestore.firestore()
    // 2. 🔑 NEW: Reference to Firebase Storage
    private let storage = Storage.storage()
    
    // 3. 🔑 NEW: Property to hold the selected image before upload
    var selectedImage: UIImage?
    
    // MARK: - UI Connections (IBOutlets)
    // ⚠️ IMPORTANT: Ensure this is connected to your UIImageView in Storyboard
    @IBOutlet weak var profilePhotoArea: UIImageView!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailDisplayTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailDisplayTextField.isEnabled = true
        passwordTextField.isSecureTextEntry = true
        
        // Setup the UIImageView to be circular and ready for tapping
        setupProfileImageView()
        
        // Add tap gesture for photo upload (This was correct)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadPhotoTapped))
        profilePhotoArea.addGestureRecognizer(tapGesture)
        profilePhotoArea.isUserInteractionEnabled = true
    }
    
    // Helper to style the image view
    private func setupProfileImageView() {
        profilePhotoArea.layer.cornerRadius = profilePhotoArea.frame.height / 2
        profilePhotoArea.clipsToBounds = true
        profilePhotoArea.contentMode = .scaleAspectFill
    }

    // MARK: - Firebase Functions

    // 4. 🔑 NEW FUNCTION: Handles the Image Upload to Firebase Storage
    private func uploadProfilePictureToStorage(image: UIImage, uid: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        // Compress image and convert to Data (JPEG is usually smaller than PNG)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data."])
            completion(.failure(error))
            return
        }

        // Create a storage reference path: 'profile_images/USER_UID.jpg'
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")

        // Start the upload task
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image to Storage: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Get the permanent download URL
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil."])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }

    // 5. 🔑 MODIFIED: Combined function for Sign Up, Storage, and Firestore Save
    private func signUpAndSaveProfile(email: String, password: String, fullName: String, phone: String) {
            
        // --- STEP 1: Firebase Authentication (Sign Up) ---
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let self = self else { return }
            
            if let error = error {
                print("Firebase Sign Up Failed: \(error.localizedDescription)")
                // IMPORTANT: Show an alert to the user detailing the error
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Error: Sign up succeeded but UID is missing.")
                return
            }

            // --- STEP 2: Handle Image Upload or Proceed Directly ---
            if let imageToUpload = self.selectedImage {
                
                // Image exists, upload it first
                self.uploadProfilePictureToStorage(image: imageToUpload, uid: uid) { result in
                    switch result {
                    case .success(let url):
                        // Image uploaded, now save Firestore data WITH the URL
                        self.saveProfileDataToFirestore(uid: uid, fullName: fullName, phone: phone, email: email, profileImageUrl: url.absoluteString)
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription). Saving profile without photo URL.")
                        // Fallback: Save profile data without the image URL
                        self.saveProfileDataToFirestore(uid: uid, fullName: fullName, phone: phone, email: email, profileImageUrl: nil)
                    }
                }
            } else {
                // No image selected, proceed to save Firestore data without URL
                self.saveProfileDataToFirestore(uid: uid, fullName: fullName, phone: phone, email: email, profileImageUrl: nil)
            }
        }
    }
    
    // 6. 🔑 NEW FUNCTION: Dedicated Firestore saving logic
    private func saveProfileDataToFirestore(uid: String, fullName: String, phone: String, email: String, profileImageUrl: String?) {
        var profileData: [String: Any] = [
            "fullName": fullName,
            "phone": phone,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add image URL if it exists
        if let url = profileImageUrl {
            profileData["profileImageUrl"] = url
        }

        // Write data to Firestore at "users/{uid}"
        self.db.collection("users").document(uid).setData(profileData, merge: true) { dbError in
            if let dbError = dbError {
                print("Error saving profile data: \(dbError.localizedDescription)")
                // Optionally show an alert to the user about the DB error
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
        
        // 1. Validate all required fields
        guard let email = emailDisplayTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let fullName = fullNameTextField.text, !fullName.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            
            print("Please fill in all required fields (Email, Password, Full Name, and Phone).")
            // Show alert to user
            return
        }

        // 2. Perform Sign Up and Data Save
        signUpAndSaveProfile(email: email, password: password, fullName: fullName, phone: phone)
    }

    // MARK: - Image Picker Logic

    // 📸 Presents the Action Sheet (Camera/Library)
    @objc func uploadPhotoTapped() {
        let alertController = UIAlertController(title: "Choose Profile Picture", message: nil, preferredStyle: .actionSheet)

        // 1. Camera Option (Check availability)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }

        // 2. Photo Library Option
        let libraryAction = UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(libraryAction)

        // 3. Cancel Option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    // Helper function to configure and present the UIImagePickerController
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // 🖼️ Delegate method: Called when the user successfully picks an image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        // Get the edited image (preferred) or the original image
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }

        // 7. 🔑 KEY STEP: Store the image for later use in the upload function
        self.selectedImage = image
        
        // Update the UI immediately
        self.profilePhotoArea.image = image
        
        // Re-apply circular masking
        setupProfileImageView()
        
        print("Image selected and stored locally. Will be uploaded on profile creation.")
    }

    // Delegate method: Called if the user cancels the picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // Placeholder function for navigation
    private func navigateToTicketListing() {
        print("Navigating to Ticket Listing Screen...")
    }
}
