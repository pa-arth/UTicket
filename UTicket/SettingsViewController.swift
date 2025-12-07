//
//    SettingsViewController.swift
//    UTicket
//
//    Created by Paarth Jamdagneya on 12/3/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher // ⭐️ ADDED: Required for ImageLoader/Kingfisher functionality

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    // MARK: - Properties
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        view.backgroundColor = .systemBackground
        
        setupProfileImageTapGesture()
        fetchUserProfile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update corner radius after layout is complete
        setupProfileDesign()
    }
    
    // MARK: - Profile Setup
    func setupProfileDesign() {
        // Make the image view circular
        // Note: Ensure the ImageView in storyboard is square (e.g., 100x100)
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // Set a default placeholder while loading (only if no image is set)
        if profileImageView.image == nil {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray
        }
    }
    
    private func setupProfileImageTapGesture() {
        // Make the image view clickable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
    }

    func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else { return }

        // 1. Get Name from Firebase Auth
        self.usernameLabel.text = user.displayName ?? "User"

        // 2. Get Image URL from Firestore
        db.collection("users").document(user.uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Try to get the specific field where you stored the URL
                if let urlString = document.data()?["profileImageUrl"] as? String {
                    
                    // ⭐️ UPDATED: Use the centralized ImageLoader
                    ImageLoader.shared.loadImage(into: self.profileImageView, from: urlString)
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
    
    // MARK: - Profile Image Change
    
    @objc private func profileImageTapped() {
        let alertController = UIAlertController(title: "Change Profile Picture", message: nil, preferredStyle: .actionSheet)
        
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
        
        // 3. Remove Photo Option (Only if user has a profile picture)
        // Check if the current image is not the default placeholder
        let isDefaultImage = profileImageView.image == UIImage(systemName: "person.circle.fill") && 
                            profileImageView.tintColor == .systemGray
        if !isDefaultImage {
            let removeAction = UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.removeProfilePicture()
            }
            alertController.addAction(removeAction)
        }
        
        // 4. Cancel Option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // For iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = profileImageView
            popover.sourceRect = profileImageView.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // Get the edited image (preferred) or the original image
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            return
        }
        
        // Store the image for upload
        selectedImage = image
        
        // Update the UI immediately
        profileImageView.image = image
        profileImageView.tintColor = nil // Clear tint color for real images
        
        // Re-apply circular masking
        setupProfileDesign()
        
        // Upload the image
        uploadProfilePicture()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Profile Picture Upload
    
    private func uploadProfilePicture() {
        guard let image = selectedImage,
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "Unable to upload profile picture. Please try again.")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            showAlert(title: "Error", message: "Could not process the image. Please try again.")
            return
        }
        
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        
        // Show loading indicator (optional - you can add a UIActivityIndicatorView if desired)
        
        storageRef.putData(imageData, metadata: nil) { [weak self] (metadata, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error uploading image to Storage: \(error.localizedDescription)")
                self.showAlert(title: "Upload Failed", message: "Failed to upload profile picture. Please try again.")
                // Revert to previous image
                self.fetchUserProfile()
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    self.showAlert(title: "Upload Failed", message: "Failed to get image URL. Please try again.")
                    self.fetchUserProfile()
                    return
                }
                
                guard let downloadURL = url else {
                    self.showAlert(title: "Upload Failed", message: "Invalid image URL. Please try again.")
                    self.fetchUserProfile()
                    return
                }
                
                // Update Firestore with the new image URL
                self.updateProfileImageURL(url: downloadURL.absoluteString)
            }
        }
    }
    
    private func updateProfileImageURL(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).setData([
            "profileImageUrl": url
        ], merge: true) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating profile image URL: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to save profile picture. Please try again.")
                self.fetchUserProfile()
            } else {
                print("✅ Profile picture updated successfully")
                // Clear Kingfisher cache for this image to force reload
                KingfisherManager.shared.cache.removeImage(forKey: url)
            }
        }
    }
    
    private func removeProfilePicture() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let alert = UIAlertController(title: "Remove Photo", message: "Are you sure you want to remove your profile picture?", preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Delete from Storage
            let storageRef = self.storage.reference().child("profile_images/\(uid).jpg")
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting image from Storage: \(error.localizedDescription)")
                }
            }
            
            // Remove from Firestore
            self.db.collection("users").document(uid).updateData([
                "profileImageUrl": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error removing profile image URL: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to remove profile picture.")
                } else {
                    // Reset to default image
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self.profileImageView.tintColor = .systemGray
                    self.setupProfileDesign()
                    print("✅ Profile picture removed successfully")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(removeAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // MARK: - Change Password Action
    @IBAction func changePasswordTapped(_ sender: UIButton) {
        guard let userEmail = Auth.auth().currentUser?.email else {
            showAlert(title: "Error", message: "No user found.")
            return
        }

        let alert = UIAlertController(title: "Reset Password", message: "We will send a password reset link to \(userEmail).", preferredStyle: .alert)

        let sendAction = UIAlertAction(title: "Send Email", style: .default) { _ in
            Auth.auth().sendPasswordReset(withEmail: userEmail) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                self.showAlert(title: "Success", message: "Check your inbox to reset your password.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(sendAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    // MARK: - Sign Out Action
    @IBAction func signOutTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            do {
                // 1. Terminate Firebase session
                try Auth.auth().signOut()
                
                // ⭐️ FIX: Clear all caches and temporary session data
                self.clearAppCachesAndSessionData()
                
                // 2. Navigate to login screen
                self.goToLoginScreen()
                
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
                self.showAlert(title: "Error", message: "Could not sign out.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    // ⭐️ NEW FUNCTION: Centralized cache clearing
    func clearAppCachesAndSessionData() {
        // 1. Clear Kingfisher's memory and disk cache (important for profile photos, etc.)
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache {
            print("✅ Kingfisher disk cache cleared.")
        }
        
        // 2. Clear all website data (cookies, session data, local storage for WebViews)
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // 3. Optional: If you use any custom storage (like UserDefaults) for tokens/sessions, clear them here.
        // UserDefaults.standard.removeObject(forKey: "userSessionToken")
        
        print("✅ All app caches cleared.")
    }

    // MARK: - Helper Functions
    func goToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Get the initial view controller from storyboard (which should be the navigation controller with LoginVC)
        // This ensures we get the proper navigation structure
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // Try to get the initial view controller from storyboard (usually the navigation controller)
        if let initialVC = storyboard.instantiateInitialViewController() {
            window.rootViewController = initialVC
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        } else {
            // Fallback: if no initial VC, try to get LoginVC and wrap it in a nav controller
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
            let navController = UINavigationController(rootViewController: loginVC)
            window.rootViewController = navController
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
