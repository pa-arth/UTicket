//
//  BaseViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 12/3/25.
//

import UIKit
import FirebaseAuth // ⭐️ ADDED: For accessing the current user's UID
import FirebaseStorage // ⭐️ ADDED: For creating the storage reference
import Kingfisher // Required if ImageLoader uses Kingfisher types

class BaseViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		setupProfileIcon()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		startNotificationListener()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		// Don't stop listener here - we want notifications across all screens
		// Only stop when user logs out
	}

	func setupProfileIcon() {
		// 1. Create a custom button
		let button = UIButton(type: .custom)
		
		// Set a temporary placeholder image while the actual image loads
		button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
		button.tintColor = .systemGray
		
		button.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
		
		// Size and style
		let iconSize: CGFloat = 34
		button.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
		button.layer.cornerRadius = iconSize / 2
		button.layer.masksToBounds = true
		
		// 2. Wrap it in a BarButton
		let barButton = UIBarButtonItem(customView: button)
		navigationItem.rightBarButtonItem = barButton
		
		// ⭐️ 3. LOAD PROFILE IMAGE FROM FIREBASE STORAGE
		loadProfileImage(into: button.imageView!)
	}
	
	private func loadProfileImage(into imageView: UIImageView) {
		guard let uid = Auth.auth().currentUser?.uid else {
			print("User not logged in or UID not found.")
			return
		}
		
		// ⭐️ CONSTRUCT THE STORAGE REFERENCE PATH
		// This assumes your image is saved under "profile_pictures/[USER_UID]/profile.jpg"
		let storageRef = Storage.storage().reference()
			.child("profile_pictures")
			.child(uid)
			.child("profile.jpg")
		
		// ⭐️ FETCH THE DOWNLOAD URL ASYNCHRONOUSLY
		storageRef.downloadURL { [weak self] url, error in
			guard let self = self else { return }
			
			if let error = error {
				print("Error getting profile image URL: \(error.localizedDescription)")
				// Leave the placeholder image
				return
			}
			
			guard let downloadURL = url else {
				print("Download URL was nil.")
				return
			}
			
			// ⭐️ USE IMAGE LOADER TO FETCH AND CACHE THE IMAGE
			// The ImageLoader is marked @MainActor, so this call is safe.
			ImageLoader.shared.loadImage(into: imageView, from: downloadURL.absoluteString)
		}
	}

	@objc func profileTapped() {
		// 1. Get a reference to the Main Storyboard
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		// 2. Instantiate the Settings View Controller
		if let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsVC") as? UIViewController {
			
			// 3. Push the settings screen onto the navigation stack
			self.navigationController?.pushViewController(settingsVC, animated: true)
		}
	}
	
	// MARK: - Notification Listener
	
	private func startNotificationListener() {
		// Only start if user is logged in
		guard Auth.auth().currentUser != nil else {
			return
		}
		
		NotificationManager.shared.startListeningForNotifications { [weak self] notification, notificationId in
			guard let self = self else { return }
			
			// Show banner notification
			NotificationManager.shared.showBanner(for: notification, notificationId: notificationId, in: self)
		}
	}
	
	// MARK: - Text Field Styling
	
	/// Sets up text field styling with active outline color
	/// Call this method in viewDidLoad for each text field you want to style
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
extension BaseViewController: UITextFieldDelegate {
	// Delegate methods can be overridden in subclasses if needed
}

// MARK: - UIColor Extension for Hex Colors
extension UIColor {
	convenience init?(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			return nil
		}
		self.init(
			red: CGFloat(r) / 255,
			green: CGFloat(g) / 255,
			blue: CGFloat(b) / 255,
			alpha: CGFloat(a) / 255
		)
	}
}
