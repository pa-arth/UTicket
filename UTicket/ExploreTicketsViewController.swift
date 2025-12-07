//
//    ExploreTicketsViewController.swift
//    UTicket
//
//    Created by Zaviyan Tharwani on 10/22/25.
//    Modified by Paarth Jamdagneya on 12/2/25.

import UIKit
import FirebaseFirestore // ⭐️ ADDED: Import Firestore

class ExploreTicketsViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private var listings: [TicketListing] = []
    
    // ⭐️ ADDED: Database reference
    private let db = Firestore.firestore()
    private let listingCollectionName = "ticketListings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore Tickets"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // ⭐️ Register the Custom Cell class
        tableView.register(ListingCell.self, forCellReuseIdentifier: "ListingCell")
        
        // Tell the table view to use self-sizing rows
        tableView.rowHeight = UITableView.automaticDimension
        // Provide an estimate to improve scroll performance
        tableView.estimatedRowHeight = 150
        
        // ❌ REMOVED: tableView.reloadData() (It should happen after data is fetched)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ⭐️ CALL FETCH LOGIC: Fetches data every time the view appears.
        fetchExploreListings()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTicketDetail",
            let dest = segue.destination as? TicketDetailViewController,
            let listing = sender as? TicketListing {
            dest.listing = listing
        }
    }
    
    // ⭐️ ADDED: Firestore Fetch Method
    func fetchExploreListings() {
        db.collection(listingCollectionName).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching explore documents: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Decode documents into the listings array
            self.listings = documents.compactMap { doc -> TicketListing? in
                do {
                    // Assuming TicketListing struct conforms to Codable/Decodable
                    return try doc.data(as: TicketListing.self)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }
            
            // Reload the table on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ExploreTicketsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let listing = listings[indexPath.row]
        
        // ⭐️ Dequeue the custom ListingCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: listing, mode:.buyerWishlist)
        
        return cell
    }
    
    // Handles the tap and performs the segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showTicketDetail", sender: listings[indexPath.row])
    }
}
