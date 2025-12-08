//
//    SellerDashboardViewController.swift
//    UTicket
//

import UIKit
import FirebaseFirestore
import Kingfisher
import FirebaseAuth

class SellerDashboardViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var sellerDashboardTableView: UITableView!
    
    var listings: [TicketListing] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sellerDashboardTableView.delegate = self
        sellerDashboardTableView.dataSource = self
        
        sellerDashboardTableView.register(ListingCell.self, forCellReuseIdentifier: "ListingCell")
        
        sellerDashboardTableView.rowHeight = UITableView.automaticDimension
        sellerDashboardTableView.estimatedRowHeight = 150
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchListingsFromFirestore()
    }
    
    // MARK: - Firestore Methods
    
    func fetchListingsFromFirestore() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in. Cannot fetch seller listings.")
            self.listings = []
            DispatchQueue.main.async { self.sellerDashboardTableView.reloadData() }
            return
        }
        

        db.collection("ticketListings")
            .whereField("sellerID", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching documents: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.listings = documents.compactMap { doc -> TicketListing? in
                    do {
                        var listing = try doc.data(as: TicketListing.self)
                        // Ensure price starts with "$"
                        if !listing.price.hasPrefix("$") {
                            listing = TicketListing(
                                eventName: listing.eventName,
                                price: "$" + listing.price,
                                eventDate: listing.eventDate,
                                eventTime: listing.eventTime,
                                seatDetails: listing.seatDetails,
                                imageURL: listing.imageURL,
                                sellerID: listing.sellerID,
                                createdAt: listing.createdAt,
                                isSold: listing.isSold
                            )
                        }
                        return listing
                    } catch {
                        print("Error decoding document: \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.sellerDashboardTableView.reloadData()
                }
            }
    }
    
    func saveListingToFirestore(_ listing: TicketListing) {
        do {
            _ = try db.collection("ticketListings").addDocument(from: listing)
            print("Listing saved successfully!")
        } catch {
            print("Error saving listing: \(error)")
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let listing = listings[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: listing, mode: .sellerMyTickets)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
