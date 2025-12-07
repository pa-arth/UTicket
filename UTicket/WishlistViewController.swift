//
//  WishlistViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//
import UIKit

class WishlistViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wishlist"
        view.backgroundColor = .systemBackground
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTicketDetailFromWishlist",
           let dest = segue.destination as? TicketDetailViewController,
           let listing = sender as? TicketListing {
            dest.listing = listing
        }
    }

}
