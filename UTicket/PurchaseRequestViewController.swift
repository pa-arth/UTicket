//
//  PurchaseRequestViewController.swift
//  UTicket
//
//  Created by Naveed Sadarulanam on 10/21/25.
//

// Change this into a ticket detail screen with the approve buyer elements hidden unless this ticket is marked as purchaseInterest

import UIKit

class PurchaseRequestViewController: BaseViewController {

    @IBOutlet weak var requestedTicketLabel: UILabel!
    
    // Will add buyer information once buyer segment is added
    @IBOutlet weak var buyerInformationLabel: UILabel!
    
    var ticket: TicketListing?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Display ticket info
        if let t = ticket {
            let dateTime = t.eventDate != nil ? "\(t.eventDate ?? ""), \(t.eventTime)" : t.eventTime
            let status = t.isSold ? "Sold" : "Available"
            requestedTicketLabel.text = "\(t.eventName)\n\(t.price)\n\(dateTime)\n\(t.seatDetails)\nStatus: \(status)"
            requestedTicketLabel.numberOfLines = 7
                }
    }

}
