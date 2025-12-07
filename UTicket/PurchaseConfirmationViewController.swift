//
//  PurchaseConfirmationViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//

import UIKit

class PurchaseConfirmationViewController: BaseViewController {
    var listing: TicketListing?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Purchase Confirmed"
        view.backgroundColor = .systemBackground

        if let l = listing {
            titleLabel?.text = "Approved & Purchased ✅\n\(l.eventName)"
            let dateTime = l.eventDate != nil ? "\(l.eventDate ?? ""), \(l.eventTime)" : l.eventTime
            detailsLabel?.text = "\(l.price)\n\(dateTime)\n\(l.seatDetails)"
        }
    }
    
    @IBAction func backToExploreTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

