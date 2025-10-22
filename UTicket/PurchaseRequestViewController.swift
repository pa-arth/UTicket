//
//  PurchaseRequestViewController.swift
//  UTicket
//
//  Created by Naveed Sadarulanam on 10/21/25.
//

import UIKit

class PurchaseRequestViewController: UIViewController {

    @IBOutlet weak var requestedTicketLabel: UILabel!
    
    // Will add buyer information once buyer segment is added
    @IBOutlet weak var buyerInformationLabel: UILabel!
    
    var ticket: TicketListing?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Placeholder ticket until data is passed from previous VC
        if ticket == nil {
            ticket = TicketListing(
                eventName: "Sam Houston vs Texas Longhorns",
                price: "$200",
                date: "6 Oct",
                time: "7 PM",
                location: "DKR Texas Memorial Stadium",
                seatInfo: "29 Section, 41 Row, 4,5 Seat\n2 Tickets",
                status: "Pending",
                image: UIImage(named: "sample_ticket") ?? UIImage()
            )
        }
        
        // Display ticket info
        if let t = ticket {
            requestedTicketLabel.text = "\(t.eventName)\n\(t.price)\n\(t.date), \(t.time)\n\(t.location)\n\(t.seatInfo)\nStatus: \(t.status)"
            requestedTicketLabel.numberOfLines = 7
                }
    }

}
