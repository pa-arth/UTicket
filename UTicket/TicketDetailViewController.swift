//
//  TicketDetailViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//

import UIKit

class TicketDetailViewController: UIViewController {
    @IBOutlet weak var ticketImageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var metaLabel: UILabel!
    var listing: TicketListing?   // we'll pass this from Explore

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ticket Details"
        view.backgroundColor = .systemBackground
        if let l = listing {
            ticketImageView.image = l.image
            eventLabel.text = l.eventName
            metaLabel.text =
                "\(l.price)\n\(l.date), \(l.time)\n\(l.location)\n\(l.seatInfo)"
        }
    }
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



