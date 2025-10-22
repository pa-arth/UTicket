//
//  SellerDashboardViewController.swift
//  UTicket
//
//  Created by Naveed Sadarulanam on 10/21/25.
//

import UIKit

struct TicketListing {
    let eventName: String
    let price: String
    let date: String
    let time: String
    let location: String
    let seatInfo: String
    let status: String
    let image: UIImage
}

class SellerDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var sellerDashboardTableView: UITableView!
    
    var listings: [TicketListing] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sellerDashboardTableView.delegate = self
        sellerDashboardTableView.dataSource = self
        
        sellerDashboardTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ListingCell")
                
        // Dummy data
        let exampleListing = TicketListing(
            eventName: "Sam Houston vs Texas Longhorns",
            price: "$200",
            date: "6 Oct",
            time: "7 PM",
            location: "DKR Texas Memorial Stadium",
            seatInfo: "29 Section, 41 Row, 4,5 Seat\n2 Tickets",
            status: "Active",
            image: UIImage(named: "sample_ticket") ?? UIImage()
        )
        listings.append(exampleListing)
        listings.append(exampleListing)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return listings.count
       }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let listing = listings[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            content.image = listing.image
            content.text = listing.eventName
            content.secondaryText = "\(listing.price)\n\(listing.date), \(listing.time)\n\(listing.location)\n\(listing.seatInfo)\nStatus: \(listing.status)"
            content.secondaryTextProperties.numberOfLines = 7
            cell.contentConfiguration = content
            
            return cell
        }
}
