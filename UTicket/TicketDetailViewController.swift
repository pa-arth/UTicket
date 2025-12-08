//
//    TicketDetailViewController.swift
//    UTicket
//
//    Created by Paarth Jamdagneya on 12/3/25.
//

import UIKit
import Kingfisher
import FirebaseFirestore
import FirebaseAuth
import SafariServices

class TicketDetailViewController: BaseViewController {
    
    private let db = Firestore.firestore()
    
    // MARK: - Core Listing Outlets
    @IBOutlet weak var ticketImageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    // MARK: - Detail Row Outlets (Matching ListingCell)
    
    @IBOutlet weak var dateIconImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var seatIconImageView: UIImageView!
    @IBOutlet weak var seatLabel: UILabel!
    
    @IBOutlet weak var locationIconImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    // MARK: - Data
    var listing: TicketListing?
    var listingDocumentID: String? // Store document ID to avoid querying
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ticket Details"
        view.backgroundColor = .systemBackground
        
        setupImageCorners()
        configureViewDetails()
    }
    
    // MARK: - Setup
    
    private func setupImageCorners() {
        // Apply rounded corners to ticket image
        ticketImageView.layer.cornerRadius = 10
        ticketImageView.clipsToBounds = true
    }
    
    // MARK: - Configuration
    
    private func configureViewDetails() {
        guard let l = listing else {
            return
        }
        
        eventLabel.text = l.eventName
        priceLabel.text = l.price
        
        ImageLoader.shared.loadImage(into: ticketImageView, from: l.imageURL)
        
        
        dateIconImageView.image = UIImage(systemName: "calendar")
        dateIconImageView.tintColor = .systemGray
        if let eventDate = l.eventDate {
            dateLabel.text = "\(eventDate), \(l.eventTime)"
        } else {
            dateLabel.text = l.eventTime
        }
        
        seatIconImageView.image = UIImage(systemName: "person.3")
        seatIconImageView.tintColor = .systemGray
        seatLabel.text = l.seatDetails
        
    }

    @IBAction func initiatePurchaseTapped(_ sender: Any) {
        guard let listing = listing,
              let buyerId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Use stored document ID if available, otherwise find it
        if let listingId = listingDocumentID {
            // Create purchase interest notification for seller
            NotificationManager.shared.createPurchaseInterestNotification(
                listingId: listingId,
                listingName: listing.eventName,
                sellerId: listing.sellerID,
                buyerId: buyerId
            )
            
            // Open Stripe payment link
            openStripePaymentLink()
        } else {
            // Fallback: find the listing document ID (should rarely be needed)
            findListingDocumentId(listing: listing) { [weak self] listingId in
                if let listingId = listingId {
                    // Create purchase interest notification for seller
                    NotificationManager.shared.createPurchaseInterestNotification(
                        listingId: listingId,
                        listingName: listing.eventName,
                        sellerId: listing.sellerID,
                        buyerId: buyerId
                    )
                }
                
                // Open Stripe payment link
                DispatchQueue.main.async {
                    self?.openStripePaymentLink()
                }
            }
        }
    }
    
    private func openStripePaymentLink() {
        guard let url = URL(string: "https://buy.stripe.com/8x27sM02u7zD7bv6Lifbq00") else {
            print("Invalid Stripe URL")
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    private func findListingDocumentId(listing: TicketListing, completion: @escaping (String?) -> Void) {
        // Use a simpler query with just sellerID to avoid composite index
        // Then filter in memory
        db.collection("ticketListings")
            .whereField("sellerID", isEqualTo: listing.sellerID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding listing ID: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Listing not found")
                    completion(nil)
                    return
                }
                
                // Filter in memory to match all fields
                let matchingDoc = documents.first { doc in
                    let data = doc.data()
                    return (data["eventName"] as? String) == listing.eventName &&
                           (data["price"] as? String) == listing.price &&
                           (data["seatDetails"] as? String) == listing.seatDetails
                }
                
                completion(matchingDoc?.documentID)
            }
    }
}

