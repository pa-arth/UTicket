//
//  SellerListingViewController.swift
//  UTicket
//
//  Created by Paarth Jamdagneya on 10/20/25.
//
import UIKit

class SellerListingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI Connections (IBOutlets)
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
    
    // MARK: - Actions (IBActions)
    @IBAction func addListingTapped(_ sender: UIButton) {
        guard let name = eventNameTextField.text, !name.isEmpty,
              let seats = seatDetailsTextField.text, !seats.isEmpty else {
            print("Please fill in all required listing details.")
            return
        }
        
        // 🔑 Save Listing Data Placeholder
        // 1. Validate that ticket image(s) have been uploaded and URLs are stored.
        // 2. Format the date/time from the display fields.
        // 3. Save the listing to your Firebase database.
        let listingData = ["eventName": name, "seats": seats]
        print("Creating listing: \(listingData)")

        // Navigate to a success screen or home
        print("Listing created successfully.")
    }
    
    @IBAction func skipForNowTapped(_ sender: UIButton) {
        // Navigate to the main app screen without creating a listing
        print("Skipping listing creation. Navigating to main screen.")
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
        
        // 🔑 Ticket Image Upload Placeholder
        // 1. Display the image(s) in the upload area (requires a collection view for multiple images).
        // 2. Upload the image to Firebase Storage.
        // 3. Store the returned image URL(s) temporarily for the listing.
        print("Ticket image selected and ready for Firebase Storage upload.")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
