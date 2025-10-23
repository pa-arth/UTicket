//
//  ExploreTicketsViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//

import UIKit

class ExploreTicketsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private var listings: [TicketListing] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore Tickets"
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
                tableView.delegate = self
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ListingCell")

                // Dummy data
                let sample = TicketListing(
                    eventName: "Sam Houston vs Texas Longhorns",
                    price: "$200",
                    date: "6 Oct",
                    time: "7 PM",
                    location: "DKR Texas Memorial Stadium",
                    seatInfo: "29 Section, 41 Row, 4,5 Seat • 2 Tickets",
                    status: "Active",
                    image: UIImage(named: "sample_ticket") ?? UIImage()
                )
                listings = [sample, sample, sample]

                tableView.reloadData()
            }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTicketDetail",
           let dest = segue.destination as? TicketDetailViewController,
           let listing = sender as? TicketListing {
            dest.listing = listing
        }
    }

        }

        extension ExploreTicketsViewController: UITableViewDataSource, UITableViewDelegate {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                listings.count
            }

            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let listing = listings[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath)

                var content = cell.defaultContentConfiguration()
                content.image = listing.image
                content.text = listing.eventName
                content.secondaryText = "\(listing.price)\n\(listing.date), \(listing.time)\n\(listing.location)\n\(listing.seatInfo)"
                content.secondaryTextProperties.numberOfLines = 4
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                tableView.deselectRow(at: indexPath, animated: true)
                performSegue(withIdentifier: "showTicketDetail", sender: listings[indexPath.row])
            }

        }
        
 

