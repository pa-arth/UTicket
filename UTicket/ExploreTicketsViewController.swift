//
//    ExploreTicketsViewController.swift
//    UTicket
//
//    Created by Zaviyan Tharwani on 10/22/25.
//    Modified by Paarth Jamdagneya on 12/2/25.

import UIKit
import FirebaseFirestore // ⭐️ ADDED: Import Firestore
import FirebaseAuth

class ExploreTicketsViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private var listings: [TicketListing] = []
    private var listingDocumentIDs: [String] = [] // Store document IDs for wishlist operations
    private var wishlistListingIDs: Set<String> = [] // Track which listings are in wishlist
    
    // ⭐️ ADDED: Database reference
    private let db = Firestore.firestore()
    private let listingCollectionName = "ticketListings"
    private let wishlistCollectionName = "wishlists"
    
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
        fetchWishlistStatus()
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
            
            // Store document IDs and decode listings
            self.listingDocumentIDs = documents.map { $0.documentID }
            self.listings = documents.compactMap { doc -> TicketListing? in
                do {
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
    
    // MARK: - Wishlist Methods
    
    func fetchWishlistStatus() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        db.collection(wishlistCollectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching wishlist: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Extract listing IDs from wishlist documents
                self.wishlistListingIDs = Set(documents.compactMap { doc -> String? in
                    return doc.data()["listingId"] as? String
                })
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    func toggleWishlist(listingId: String, isAdding: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        if isAdding {
            // Add to wishlist
            let wishlistData: [String: Any] = [
                "userId": userId,
                "listingId": listingId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            db.collection(wishlistCollectionName).addDocument(data: wishlistData) { [weak self] error in
                if let error = error {
                    print("Error adding to wishlist: \(error)")
                } else {
                    self?.wishlistListingIDs.insert(listingId)
                    print("Added to wishlist")
                }
            }
        } else {
            // Remove from wishlist
            db.collection(wishlistCollectionName)
                .whereField("userId", isEqualTo: userId)
                .whereField("listingId", isEqualTo: listingId)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error finding wishlist item: \(error)")
                        return
                    }
                    
                    // Delete all matching documents (should only be one)
                    for document in snapshot?.documents ?? [] {
                        document.reference.delete { error in
                            if let error = error {
                                print("Error removing from wishlist: \(error)")
                            } else {
                                self.wishlistListingIDs.remove(listingId)
                                print("Removed from wishlist")
                            }
                        }
                    }
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
        let listingId = listingDocumentIDs[indexPath.row]
        let isInWishlist = wishlistListingIDs.contains(listingId)
        
        // ⭐️ Dequeue the custom ListingCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: listing, mode: .buyerWishlist, isInWishlist: isInWishlist)
        
        // Set up heart button tap handler
        cell.onHeartTapped = { [weak self] isAdding in
            self?.toggleWishlist(listingId: listingId, isAdding: isAdding)
        }
        
        return cell
    }
    
    // Handles the tap and performs the segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showTicketDetail", sender: listings[indexPath.row])
    }
}
