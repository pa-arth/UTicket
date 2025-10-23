//
//  PurchaseConfirmationViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//

import UIKit

class PurchaseConfirmationViewController: UIViewController {
    var listing: TicketListing?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Purchase Confirmed"
        view.backgroundColor = .systemBackground

        if let l = listing {
            titleLabel?.text = "Approved & Purchased ✅\n\(l.eventName)"
            detailsLabel?.text = "\(l.price)\n\(l.date), \(l.time)\n\(l.location)\n\(l.seatInfo)"
        }
    }
    
    @IBAction func backToExploreTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

