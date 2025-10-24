//
//  SellerListingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 10/20/25.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class SellerListingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI Connections (IBOutlets)
    private var selectedTicketImage: UIImage?
    
    @IBOutlet weak var uploadImageArea: UIView! // The large box for ticket images
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventDateDisplay: UITextField! // Or TextField for date/time
    @IBOutlet weak var eventTimeDisplay: UITextField! // Or TextField for date/time
    @IBOutlet weak var seatDetailsTextField: UITextField!
    @IBOutlet weak var addListingButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            
            // Add tap gesture to open image picker
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadTicketImageTapped))
            uploadImageArea.addGestureRecognizer(tapGesture)
            uploadImageArea.isUserInteractionEnabled = true
            
            // Initial setup for date/time to match the image
            eventDateDisplay.text = "Oct 6, 2025" // Placeholder
            eventTimeDisplay.text = "09 : 41" // Placeholder
        }
        
        // MARK: - Setup
        private func setupUI() {
            // Example: Setting the Skip button border in code if not done in Storyboard
            skipButton.layer.borderColor = addListingButton.backgroundColor?.cgColor
            skipButton.layer.borderWidth = 1.0
            skipButton.layer.cornerRadius = 8 // Match other buttons
        }
        
        // MARK: - Firebase Functions

        /// Placeholder for the actual image upload to Firebase Storage
        private func uploadImageAndGetURL(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
            // ⚠️ IMPLEMENTATION NOTE:
            // 1. Convert the UIImage to Data (e.g., JPEG or PNG data).
            // 2. Upload the data to Firebase Storage (e.g., in a "ticket_images" folder).
            // 3. Get the download URL after the upload succeeds.
            
            print("--- Placeholder: Image upload function called. ---")
            
            // For demonstration, we'll simulate a successful upload with a dummy URL after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let dummyURL = "gs://your-firebase-bucket/images/ticket_\(UUID().uuidString).jpg"
                print("--- Placeholder: Image upload successful. URL: \(dummyURL) ---")
                completion(.success(dummyURL))
            }
        }
        
        /// Saves the complete ticket listing data to Firestore
        private func saveListingToFirestore(imageURL: String, name: String, date: String, time: String, seats: String) {
            // Ensure the user is logged in to associate the listing with a seller
            guard let sellerUID = Auth.auth().currentUser?.uid else {
                print("Error: User not authenticated. Cannot create listing.")
                // You should show an alert to the user here.
                return
            }
            
            let listingData: [String: Any] = [
                "eventName": name,
                "eventDate": date,
                "eventTime": time,
                "seatDetails": seats,
                "imageURL": imageURL,
                "sellerID": sellerUID,
                "createdAt": FieldValue.serverTimestamp(), // Firestore timestamp for ordering
                "isSold": false
            ]

            // Add a new document to the "listings" collection
            db.collection("listings").addDocument(data: listingData) { [weak self] error in
                if let error = error {
                    print("Error adding document: \(error.localizedDescription)")
                    // Show an error alert
                } else {
                    print("Listing created successfully in Firestore.")
                    // Navigate to a success screen or home
                    self?.navigateToSuccessScreen()
                }
            }
        }

        // MARK: - Actions (IBActions)
        @IBAction func addListingTapped(_ sender: UIButton) {
            // Basic input validation
            guard let name = eventNameTextField.text, !name.isEmpty,
                  let date = eventDateDisplay.text, !date.isEmpty,
                  let time = eventTimeDisplay.text, !time.isEmpty,
                  let seats = seatDetailsTextField.text, !seats.isEmpty else {
                print("Please fill in all required listing details.")
                // Show an alert to the user
                return
            }
            
            guard let image = selectedTicketImage else {
                print("Please upload a ticket image before listing.")
                // Show an alert to the user
                return
            }
            
            // 1. Start the image upload process
            addListingButton.isEnabled = false // Disable button during upload/save
            addListingButton.setTitle("Uploading...", for: .normal)
            
            uploadImageAndGetURL(image: image) { [weak self] result in
                DispatchQueue.main.async {
                    self?.addListingButton.isEnabled = true
                    self?.addListingButton.setTitle("Add Listing", for: .normal)
                    
                    switch result {
                    case .success(let url):
                        // 2. Image uploaded, now save the listing data to Firestore
                        self?.saveListingToFirestore(imageURL: url, name: name, date: date, time: time, seats: seats)
                    case .failure(let error):
                        print("Image upload failed: \(error.localizedDescription)")
                        // Show an error alert
                    }
                }
            }
        }
        
        @IBAction func skipForNowTapped(_ sender: UIButton) {
            // Navigate to the main app screen without creating a listing
            navigateToSuccessScreen() // Assuming this is the main screen
        }
        
        // MARK: - Image Picker Logic
        @objc func uploadTicketImageTapped() {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true)
        }
        
        // UIImagePickerControllerDelegate method
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)
            
            guard let image = info[.originalImage] as? UIImage else { return }
            
            // Store the selected image temporarily
            selectedTicketImage = image
            print("Ticket image selected and stored locally.")
            
            // 1. Display the image (If uploadImageArea is an UIImageView, set its image property here)
            // 2. The actual Firebase Storage upload happens in addListingTapped
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // MARK: - Navigation
        private func navigateToSuccessScreen() {
            // Implement Storyboard Segue or programmatic navigation here
            print("Navigating to main Ticket Listing Screen...")
        }
    }
