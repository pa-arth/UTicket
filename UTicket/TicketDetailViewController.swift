//
//    TicketDetailViewController.swift
//    UTicket
//
//    Created by Paarth Jamdagneya on 12/3/25.
//

import UIKit
import Kingfisher

class TicketDetailViewController: BaseViewController {
    
    // MARK: - Core Listing Outlets
    @IBOutlet weak var ticketImageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    // MARK: - Detail Row Outlets (Matching ListingCell)
    
    @IBOutlet weak var dateIconImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var locationIconImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var seatIconImageView: UIImageView!
    @IBOutlet weak var seatLabel: UILabel!
    
    // MARK: - Data
    var listing: TicketListing?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ticket Details"
        view.backgroundColor = .systemBackground
        
        configureViewDetails()
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
        
        // Location not stored in Firestore, hide location UI
        locationIconImageView.isHidden = true
        locationLabel.isHidden = true
        
        seatIconImageView.image = UIImage(systemName: "person.3")
        seatIconImageView.tintColor = .systemGray
        seatLabel.text = l.seatDetails
        
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPurchaseConfirmation",
            let dest = segue.destination as? PurchaseConfirmationViewController,
            let passed = sender as? TicketListing {
            dest.listing = passed
        }
    }

    @IBAction func initiatePurchaseTapped(_ sender: Any) {
        performSegue(withIdentifier: "showPurchaseConfirmation", sender: listing)
    }
}
