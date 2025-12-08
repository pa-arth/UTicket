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
import FirebaseStorage

class ProfileCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    var selectedImage: UIImage?
    
    // 🔑 Allowed Domain for UT Austin
    private let allowedDomain = "@utexas.edu"
    
    // MARK: - UI Connections (IBOutlets)
    @IBOutlet weak var profilePhotoArea: UIImageView!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailDisplayTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailDisplayTextField.isEnabled = true
        passwordTextField.isSecureTextEntry = true
        
        // Add tap gesture for photo upload
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadPhotoTapped))
        profilePhotoArea.addGestureRecognizer(tapGesture)
        profilePhotoArea.isUserInteractionEnabled = true
        
        // Set a default/placeholder image and style
        profilePhotoArea.image = UIImage(systemName: "person.circle.fill")
        profilePhotoArea.tintColor = .systemGray4
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupProfileImageView() // Now frame.height has its real value
    }
    
    // MARK: - Utility Functions
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // Helper to style the image view
    private func setupProfileImageView() {
        profilePhotoArea.layer.cornerRadius = profilePhotoArea.frame.height / 2
        profilePhotoArea.clipsToBounds = true
        profilePhotoArea.contentMode = .scaleAspectFill
    }
    
    // 🔑 NEW: Helper function to check the required email domain
    private func isAllowedDomain(email: String) -> Bool {
        return email.lowercased().hasSuffix(allowedDomain)
    }
    
    // MARK: - Firebase Functions
    
    // Handles the Image Upload to Firebase Storage
    private func uploadProfilePictureToStorage(image: UIImage, uid: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            let error = NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data."])
            completion(.failure(error))
            return
        }
        
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image to Storage: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil."])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    // Combined function for Sign Up, Storage, and Firestore Save
    private func signUpAndSaveProfile(email: String, password: String, fullName: String, phone: String) {
        
        // --- STEP 1: Firebase Authentication (Sign Up) ---
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let self = self else { return }
            
            if let error = error {
                print("Firebase Sign Up Failed: \(error.localizedDescription)")
                self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Error: Sign up succeeded but UID is missing.")
                self.showAlert(title: "Sign Up Error", message: "Could not retrieve user ID after successful sign up.")
                return
            }
            
            // --- STEP 2: Upload Profile Picture (Required) ---
            // Profile picture is required, so this should always exist due to validation
            guard let imageToUpload = self.selectedImage else {
                print("Error: Profile picture is required but was not found.")
                self.showAlert(title: "Error", message: "Profile picture is required. Please try again.")
                // Delete the user account since we can't complete profile creation
                authResult?.user.delete { _ in }
                return
            }
            
            // Update display name in Firebase Auth
            let changeRequest = authResult?.user.createProfileChangeRequest()
            changeRequest?.displayName = fullName
            changeRequest?.commitChanges { error in
                if let error = error {
                    print("Error updating display name: \(error.localizedDescription)")
                    // Continue anyway, display name update is not critical
                }
            }
            
            // Upload the image
            self.uploadProfilePictureToStorage(image: imageToUpload, uid: uid) { result in
                switch result {
                case .success(let url):
                    // Image uploaded, now save Firestore data WITH the URL
                    self.saveProfileDataToFirestore(uid: uid, fullName: fullName, phone: phone, email: email, profileImageUrl: url.absoluteString)
                case .failure(let error):
                    print("Failed to upload image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(title: "Upload Failed", message: "Failed to upload profile picture: \(error.localizedDescription). Please try again.")
                    }
                    // Delete the user account since profile creation failed
                    authResult?.user.delete { _ in }
                }
            }
        }
    }
    
    // Dedicated Firestore saving logic
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
        self.db.collection("users").document(uid).setData(profileData, merge: true) { [weak self] dbError in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let dbError = dbError {
                    print("Error saving profile data: \(dbError.localizedDescription)")
                    self.showAlert(title: "Profile Save Error", message: "Failed to save profile data: \(dbError.localizedDescription)")
                } else {
                    print("Profile data successfully saved for user: \(uid)")
                    // Navigate to the appropriate screen after successful profile creation
                    self.navigateAfterProfileCreation()
                }
            }
        }
    }
    
    // Navigate to the appropriate screen after profile creation
    private func navigateAfterProfileCreation() {
        // Check if there's a navigation controller
        if let navigationController = self.navigationController {
            // Pop back to the previous screen (likely OnboardingViewController)
            navigationController.popViewController(animated: true)
        } else {
            // If no navigation controller, try to navigate to the main app screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? UIViewController {
                // Present modally or set as root
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let navController = UINavigationController(rootViewController: exploreVC)
                    window.rootViewController = navController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private func validatePassword(_ password: String) -> (isValid: Bool, errorMessage: String?) {
        // Check minimum length
        if password.count < 6 {
            return (false, "Password must be at least 6 characters long.")
        }
        
        // Additional validations can be added here (e.g., uppercase, lowercase, numbers, special chars)
        // For now, just check length
        
        return (true, nil)
    }
    
    private func validateEmail(_ email: String) -> (isValid: Bool, errorMessage: String?) {
        // Basic email format validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            return (false, "Please enter a valid email address.")
        }
        
        return (true, nil)
    }
    
    private func validatePhone(_ phone: String) -> (isValid: Bool, errorMessage: String?) {
        // Remove common phone formatting characters for validation
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Check if phone has at least 10 digits (US phone number format)
        if cleanedPhone.count < 10 {
            return (false, "Please enter a valid phone number.")
        }
        
        return (true, nil)
    }
    
    // MARK: - Actions (IBActions)
    @IBAction func createProfileButtonTapped(_ sender: UIButton) {
        
        // 1. Validate all required fields
        guard let email = emailDisplayTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !fullName.isEmpty,
              let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty else {
            
            showAlert(title: "Missing Fields", message: "Please fill in all required fields.")
            return
        }
        
        // 2. Validate profile picture is selected
        guard selectedImage != nil else {
            showAlert(title: "Profile Picture Required", message: "Please select a profile picture before creating your account.")
            return
        }
        
        // 3. Validate email format
        let emailValidation = validateEmail(email)
        if !emailValidation.isValid {
            showAlert(title: "Invalid Email", message: emailValidation.errorMessage ?? "Please enter a valid email address.")
            return
        }
        
        // 🔑 4. Check for UTEXAS Domain (Client-Side)
        if !isAllowedDomain(email: email) {
            showAlert(title: "Invalid Email Domain", message: "Sign-up is restricted to email addresses ending with \(allowedDomain).")
            return
        }
        
        // 5. Validate password
        let passwordValidation = validatePassword(password)
        if !passwordValidation.isValid {
            showAlert(title: "Invalid Password", message: passwordValidation.errorMessage ?? "Password does not meet requirements.")
            return
        }
        
        // 6. Check if passwords match
        guard password == confirmPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords do not match.")
            return
        }
        
        // 7. Validate phone number
        let phoneValidation = validatePhone(phone)
        if !phoneValidation.isValid {
            showAlert(title: "Invalid Phone Number", message: phoneValidation.errorMessage ?? "Please enter a valid phone number.")
            return
        }
        
        // 8. Perform Sign Up and Data Save
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
        
        // 3. Remove Photo Option (Only if an image is selected)
        if selectedImage != nil {
            let removeAction = UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.selectedImage = nil
                self.profilePhotoArea.image = UIImage(systemName: "person.circle.fill") // Reset to default
                self.profilePhotoArea.tintColor = .systemGray4
                self.setupProfileImageView()
            }
            alertController.addAction(removeAction)
        }
        
        // 4. Cancel Option
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
        
        // Store the image for later use in the upload function
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
}
