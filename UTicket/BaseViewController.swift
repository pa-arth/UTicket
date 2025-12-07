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
}
