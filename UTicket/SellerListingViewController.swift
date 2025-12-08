//
//    SellerListingViewController.swift
//    UTicket
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SellerListingViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let db = Firestore.firestore()
    private let listingCollectionName = "ticketListings"
    
    // MARK: - UI Connections (IBOutlets)
    private var selectedTicketImage: UIImage?
    
    @IBOutlet weak var uploadImageArea: UIImageView!
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventDateDisplay: UITextField!
    @IBOutlet weak var eventTimeDisplay: UITextField!
    // ⭐️ ADDED: New outlet for the price input
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var seatDetailsTextField: UITextField!
    @IBOutlet weak var addListingButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add tap gesture to open image picker
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadTicketImageTapped))
        uploadImageArea.addGestureRecognizer(tapGesture)
        uploadImageArea.isUserInteractionEnabled = true
        
        // Set placeholder upload icon
        let uploadIcon = UIImage(systemName: "square.and.arrow.up") // SF Symbol
        uploadImageArea.image = uploadIcon
        uploadImageArea.tintColor = .systemGray
        uploadImageArea.contentMode = .scaleAspectFit
    }
    
    // MARK: - Firebase Storage Upload (No change needed)
    
    /// Uploads an image to Firebase Storage and returns the download URL
    private func uploadImageAndGetURL(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            DispatchQueue.main.async { completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG."]))) }
            return
        }
        
        let imageID = UUID().uuidString
        let storageRef = Storage.storage().reference()
            .child("ticket_images")
            .child("\(imageID).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error { DispatchQueue.main.async { completion(.failure(error)) }; return }
            storageRef.downloadURL { url, error in
                if let error = error { DispatchQueue.main.async { completion(.failure(error)) }; return }
                guard let downloadURL = url?.absoluteString else {
                    DispatchQueue.main.async { completion(.failure(NSError(domain: "URLFetchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve download URL."]))) }
                    return
                }
                DispatchQueue.main.async { completion(.success(downloadURL)) }
            }
        }
    }
    
    // MARK: - Firestore Save
    
    private func saveListingToFirestore(imageURL: String,
                                      name: String,
                                      date: String,
                                      time: String,
                                      // ⭐️ UPDATED: Added price argument
                                      price: String,
                                      seats: String) {
        
        guard let sellerUID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be logged in to create a listing.")
            return
        }
        
        let listingData: [String: Any] = [
            "eventName": name,
            "eventDate": date,
            "eventTime": time,
            "price": price,
            "seatDetails": seats,
            "imageURL": imageURL,
            "sellerID": sellerUID,
            "createdAt": FieldValue.serverTimestamp(),
            "isSold": false
        ]
        
        let docRef = db.collection(listingCollectionName).document()
        let listingId = docRef.documentID
        
        docRef.setData(listingData) { [weak self] error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Unable to upload the listing.")
            } else {
                print("🎉 Listing created successfully. Returning to dashboard.")
                
                // Create notifications for other users
                NotificationManager.shared.createNewListingNotification(
                    listingId: listingId,
                    listingName: name,
                    sellerId: sellerUID
                )
                
                // Show success pop-up
                self?.showListingCreatedSuccessPopup(listingName: name) {
                    self?.navigateToSuccessScreen()
                }
            }
        }
    }
    
    
    // MARK: - Add Listing
    
    @IBAction func addListingTapped(_ sender: UIButton) {
        
        // ⭐️ UPDATED: Added price validation
        guard let name = eventNameTextField.text, !name.isEmpty,
              let date = eventDateDisplay.text, !date.isEmpty,
              let time = eventTimeDisplay.text, !time.isEmpty,
              let price = priceTextField.text, !price.isEmpty, // ⭐️ ADDED: Price validation
              let seats = seatDetailsTextField.text, !seats.isEmpty else {
            showAlert(title: "Missing Information", message: "Please complete all fields.")
            return
        }
        
        guard let image = selectedTicketImage else {
            showAlert(title: "No Image", message: "Please upload a ticket image.")
            return
        }
        
        addListingButton.isEnabled = false
        addListingButton.setTitle("Uploading...", for: .normal)
        
        uploadImageAndGetURL(image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.addListingButton.isEnabled = true
                self?.addListingButton.setTitle("Add Listing", for: .normal)
                
                switch result {
                    case .success(let url):
                        self?.saveListingToFirestore(imageURL: url,
                                                    name: name,
                                                    date: date,
                                                    time: time,
                                                    // ⭐️ UPDATED: Passed price argument
                                                    price: price,
                                                    seats: seats)
                    case .failure(let error):
                        print("Image upload failed: \(error.localizedDescription)")
                        self?.showAlert(title: "Upload Failed",
                                        message: "Unable to upload image. Try again.")
                }
            }
        }
    }
    
    
    @IBAction func skipForNowTapped(_ sender: UIButton) {
        navigateToSuccessScreen()
    }
    
    
    // MARK: - Image Picker (No change needed)
    
    @objc func uploadTicketImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        selectedTicketImage = image
        uploadImageArea.image = image
        
        print("📸 Ticket image selected.")
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    // MARK: - Navigation (No change needed)
    
    private func navigateToSuccessScreen() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    
    // MARK: - Alerts
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showListingCreatedSuccessPopup(listingName: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Listing Created! 🎉",
            message: "Your listing for \"\(listingName)\" has been successfully created and is now visible to buyers.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Great!", style: .default) { _ in
            completion()
        }
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
}
