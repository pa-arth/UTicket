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
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var changePasswordButton: UIButton?
    @IBOutlet weak var signOutButton: UIButton?
    @IBOutlet weak var roleLabel: UILabel?
    @IBOutlet weak var roleButton: UIButton?
    
    private let roles = ["Buyer", "Seller"]
    private var currentRole: String = "Buyer" // Default role
    
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
        loadNotificationPreference()
        setupNotificationSwitch()
        setupRoleSelection()
        loadCurrentRole()
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update corner radius after layout is complete
        setupProfileDesign()
    }
    
    // MARK: - Constraints Setup
    private func setupConstraints() {
        // Add explicit size constraints to ensure all UI elements have defined sizes
        // Note: We're only adding size constraints, not disabling storyboard constraints
        
        // Profile Image View - Ensure it has explicit size (120x120 for circular profile)
        if profileImageView.constraints.filter({ $0.firstAttribute == .width || $0.firstAttribute == .height }).isEmpty {
            NSLayoutConstraint.activate([
                profileImageView.widthAnchor.constraint(equalToConstant: 120),
                profileImageView.heightAnchor.constraint(equalToConstant: 120)
            ])
        }
        
        // Username Label - Add minimum size constraints
        let usernameSizeConstraints = usernameLabel.constraints.filter { 
            $0.firstAttribute == .width || $0.firstAttribute == .height 
        }
        if usernameSizeConstraints.isEmpty {
            NSLayoutConstraint.activate([
                usernameLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
            ])
        }
        
        // Notification Switch - Standard switch size (51x31)
        let switchSizeConstraints = notificationSwitch.constraints.filter { 
            $0.firstAttribute == .width || $0.firstAttribute == .height 
        }
        if switchSizeConstraints.isEmpty {
            NSLayoutConstraint.activate([
                notificationSwitch.widthAnchor.constraint(equalToConstant: 51),
                notificationSwitch.heightAnchor.constraint(equalToConstant: 31)
            ])
        }
        
        // Find and add size constraints to buttons
        if let changePasswordBtn = changePasswordButton ?? findButton(withTitle: "Change Password") {
            let buttonSizeConstraints = changePasswordBtn.constraints.filter { 
                $0.firstAttribute == .width || $0.firstAttribute == .height 
            }
            if buttonSizeConstraints.isEmpty {
                NSLayoutConstraint.activate([
                    changePasswordBtn.widthAnchor.constraint(equalToConstant: 201),
                    changePasswordBtn.heightAnchor.constraint(equalToConstant: 35)
                ])
            }
        }
        
        if let signOutBtn = signOutButton ?? findButton(withTitle: "Sign Out") {
            let buttonSizeConstraints = signOutBtn.constraints.filter { 
                $0.firstAttribute == .width || $0.firstAttribute == .height 
            }
            if buttonSizeConstraints.isEmpty {
                NSLayoutConstraint.activate([
                    signOutBtn.widthAnchor.constraint(equalToConstant: 201),
                    signOutBtn.heightAnchor.constraint(equalToConstant: 35)
                ])
            }
        }
        
        // Find and constrain notification label
        if let notificationLabel = findLabel(withText: "Notifications") {
            let labelSizeConstraints = notificationLabel.constraints.filter { 
                $0.firstAttribute == .width || $0.firstAttribute == .height 
            }
            if labelSizeConstraints.isEmpty {
                NSLayoutConstraint.activate([
                    notificationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
                    notificationLabel.heightAnchor.constraint(equalToConstant: 21)
                ])
            }
        }
    }
    
    // Helper method to find button by title
    private func findButton(withTitle title: String) -> UIButton? {
        return view.subviews.compactMap { $0 as? UIButton }
            .first { $0.title(for: .normal) == title || $0.configuration?.title == title }
    }
    
    // Helper method to find label by text
    private func findLabel(withText text: String) -> UILabel? {
        return view.subviews.compactMap { $0 as? UILabel }
            .first { $0.text == text }
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
        guard let uid = Auth.auth().currentUser?.uid,
              let user = Auth.auth().currentUser else { 
            showAlert(title: "Error", message: "User not authenticated. Please try again.")
            return 
        }
        
        // Ensure user document exists with basic info, then update image URL
        var userData: [String: Any] = [
            "profileImageUrl": url
        ]
        
        // Add email and displayName if available to ensure document exists properly
        if let email = user.email {
            userData["email"] = email
        }
        if let displayName = user.displayName {
            userData["fullName"] = displayName
        }
        
        db.collection("users").document(uid).setData(userData, merge: true) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating profile image URL: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to save profile picture: \(error.localizedDescription)")
                    self.fetchUserProfile()
                }
            } else {
                print("✅ Profile picture updated successfully")
                // Clear Kingfisher cache for this image to force reload
                KingfisherManager.shared.cache.removeImage(forKey: url)
                // Show success message
                DispatchQueue.main.async {
                    self.showAlert(title: "Success", message: "Profile picture updated successfully!")
                }
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
    
    // MARK: - Notification Settings
    
    private func setupNotificationSwitch() {
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchToggled), for: .valueChanged)
    }
    
    private func loadNotificationPreference() {
        NotificationManager.shared.getNotificationPreference { [weak self] enabled in
            DispatchQueue.main.async {
                self?.notificationSwitch.isOn = enabled
            }
        }
    }
    
    @objc private func notificationSwitchToggled() {
        let isEnabled = notificationSwitch.isOn
        NotificationManager.shared.setNotificationPreference(isEnabled) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("Notification preference updated: \(isEnabled)")
                } else {
                    // Revert switch if save failed
                    self?.notificationSwitch.isOn = !isEnabled
                    self?.showAlert(title: "Error", message: "Failed to update notification preference. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Role Selection Setup
    
    private func setupRoleSelection() {
        // Create a button for role selection if it doesn't exist
        if roleButton == nil {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(currentRole, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            button.addTarget(self, action: #selector(roleButtonTapped), for: .touchUpInside)
            view.addSubview(button)
            roleButton = button
            
            // Add constraints for programmatic button
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                button.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 30),
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            roleButton?.addTarget(self, action: #selector(roleButtonTapped), for: .touchUpInside)
        }
        
        // Make role label tappable as well
        if let roleLabel = roleLabel {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(roleButtonTapped))
            roleLabel.addGestureRecognizer(tapGesture)
            roleLabel.isUserInteractionEnabled = true
        }
    }
    
    @objc private func roleButtonTapped() {
        showRoleSelectionActionSheet()
    }
    
    private func showRoleSelectionActionSheet() {
        let alert = UIAlertController(
            title: "Select Role",
            message: "Choose your role to switch between Buyer and Seller dashboards",
            preferredStyle: .actionSheet
        )
        
        // Add actions for each role
        for role in roles {
            let action = UIAlertAction(title: role, style: .default) { [weak self] _ in
                self?.handleRoleSelection(role)
            }
            
            // Mark current role with checkmark
            if role == currentRole {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = roleButton ?? roleLabel
            popover.sourceRect = (roleButton ?? roleLabel)?.bounds ?? CGRect.zero
        }
        
        present(alert, animated: true)
    }
    
    private func handleRoleSelection(_ selectedRole: String) {
        // Only navigate if role actually changed
        if selectedRole != currentRole {
            let previousRole = currentRole
            
            // Show confirmation alert before navigating
            let alert = UIAlertController(
                title: "Switch to \(selectedRole) Mode?",
                message: "You will be navigated to the \(selectedRole) dashboard.",
                preferredStyle: .alert
            )
            
            let confirmAction = UIAlertAction(title: "Switch", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentRole = selectedRole
                self.saveCurrentRole(selectedRole)
                self.updateRoleDisplay()
                self.navigateToRoleDashboard(selectedRole)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        } else {
            // Role didn't change, just update display
            updateRoleDisplay()
        }
    }
    
    private func loadCurrentRole() {
        // Try to load from UserDefaults first
        if let savedRole = UserDefaults.standard.string(forKey: "userRole"), !savedRole.isEmpty {
            // Normalize the role (capitalize first letter)
            let normalizedRole = savedRole.prefix(1).uppercased() + savedRole.dropFirst().lowercased()
            if roles.contains(normalizedRole) {
                currentRole = normalizedRole
            } else {
                // Default to Buyer if invalid role
                currentRole = "Buyer"
                UserDefaults.standard.set("Buyer", forKey: "userRole")
            }
        } else {
            // Try to load from Firestore
            guard let uid = Auth.auth().currentUser?.uid else {
                // Default to Buyer if not logged in
                currentRole = "Buyer"
                updateRoleDisplay()
                return
            }
            
            db.collection("users").document(uid).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let document = document, document.exists {
                    if let role = document.data()?["role"] as? String {
                        // Normalize the role
                        let normalizedRole = role.prefix(1).uppercased() + role.dropFirst().lowercased()
                        if self.roles.contains(normalizedRole) {
                            self.currentRole = normalizedRole
                            UserDefaults.standard.set(normalizedRole, forKey: "userRole")
                        } else {
                            // Default to Buyer if invalid role
                            self.currentRole = "Buyer"
                            UserDefaults.standard.set("Buyer", forKey: "userRole")
                        }
                    } else {
                        // No role in Firestore, default to Buyer
                        self.currentRole = "Buyer"
                        UserDefaults.standard.set("Buyer", forKey: "userRole")
                    }
                } else {
                    // Document doesn't exist, default to Buyer
                    self.currentRole = "Buyer"
                    UserDefaults.standard.set("Buyer", forKey: "userRole")
                }
                
                DispatchQueue.main.async {
                    self.updateRoleDisplay()
                }
            }
        }
        
        updateRoleDisplay()
    }
    
    private func updateRoleDisplay() {
        roleLabel?.text = "Current Role: \(currentRole)"
        roleButton?.setTitle(currentRole, for: .normal)
    }
    
    private func saveCurrentRole(_ role: String) {
        // Save to UserDefaults
        UserDefaults.standard.set(role, forKey: "userRole")
        
        // Save to Firestore
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).setData([
            "role": role
        ], merge: true) { error in
            if let error = error {
                print("Error saving role to Firestore: \(error.localizedDescription)")
            } else {
                print("✅ Role saved successfully: \(role)")
            }
        }
    }
    
    private func navigateToRoleDashboard(_ role: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let navigationController = self.navigationController else {
            print("Error: No navigation controller found")
            return
        }
        
        // Navigate to the appropriate dashboard
        if role.lowercased() == "buyer" {
            // Navigate to Buyer Dashboard (Explore Tickets)
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? UIViewController {
                // Pop all view controllers and set explore as root
                navigationController.setViewControllers([exploreVC], animated: true)
            }
        } else if role.lowercased() == "seller" {
            // Navigate to Seller Dashboard
            if let sellerVC = storyboard.instantiateViewController(withIdentifier: "sellerListing") as? UIViewController {
                // Pop all view controllers and set seller dashboard as root
                navigationController.setViewControllers([sellerVC], animated: true)
            }
        }
    }
    
}
