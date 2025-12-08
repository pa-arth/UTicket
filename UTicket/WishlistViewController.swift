//
//  WishlistViewController.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth

class WishlistViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var wishlistItems: [TicketListing] = []
    private let db = Firestore.firestore()
    private let wishlistCollectionName = "wishlists"
    private let listingCollectionName = "ticketListings"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wishlist"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ListingCell.self, forCellReuseIdentifier: "ListingCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchWishlistItems()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTicketDetailFromWishlist",
           let dest = segue.destination as? TicketDetailViewController,
           let listing = sender as? TicketListing {
            dest.listing = listing
        }
    }
    
    // MARK: - Firestore Methods
    
    func fetchWishlistItems() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            wishlistItems = []
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        // First, get all wishlist entries for this user
        db.collection(wishlistCollectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching wishlist: \(error)")
                    self.wishlistItems = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.wishlistItems = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    return
                }
                
                // Extract listing IDs
                let listingIDs = documents.compactMap { doc -> String? in
                    return doc.data()["listingId"] as? String
                }
                
                if listingIDs.isEmpty {
                    self.wishlistItems = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    return
                }
                
                // Fetch all listings by their document IDs
                // Firestore doesn't support 'in' query with document IDs directly
                // So we'll fetch each document individually
                var fetchedListings: [TicketListing] = []
                let dispatchGroup = DispatchGroup()
                
                for listingId in listingIDs {
                    dispatchGroup.enter()
                    self.db.collection(self.listingCollectionName)
                        .document(listingId)
                        .getDocument { document, error in
                            defer { dispatchGroup.leave() }
                            
                            if let error = error {
                                print("Error fetching listing \(listingId): \(error)")
                                return
                            }
                            
                            guard let document = document, document.exists else {
                                print("Listing \(listingId) not found")
                                return
                            }
                            
                            do {
                                if let listing = try? document.data(as: TicketListing.self) {
                                    fetchedListings.append(listing)
                                }
                            } catch {
                                print("Error decoding listing \(listingId): \(error)")
                            }
                        }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.wishlistItems = fetchedListings
                    self.tableView.reloadData()
                }
            }
            }
    }


// MARK: - UITableViewDataSource, UITableViewDelegate

extension WishlistViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlistItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let listing = wishlistItems[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: listing, mode: .buyerWishlist, isInWishlist: true)
        
        // Disable heart button in wishlist view (or make it remove from wishlist)
        cell.onHeartTapped = { [weak self] isAdding in
            if !isAdding {
                // Remove from wishlist
                self?.removeFromWishlist(listing: listing)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showTicketDetailFromWishlist", sender: wishlistItems[indexPath.row])
    }
    
    // MARK: - Helper Methods
    
    private func removeFromWishlist(listing: TicketListing) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // We need to find the listing document ID
        // Since we don't store it in TicketListing, we'll query for it
        db.collection(listingCollectionName)
            .whereField("sellerID", isEqualTo: listing.sellerID)
            .whereField("eventName", isEqualTo: listing.eventName)
            .whereField("price", isEqualTo: listing.price)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding listing: \(error)")
                    return
                }
                
                guard let listingDoc = snapshot?.documents.first else {
                    print("Listing not found")
                    return
                }
                
                let listingId = listingDoc.documentID
                
                // Remove from wishlist
                self.db.collection(self.wishlistCollectionName)
                    .whereField("userId", isEqualTo: userId)
                    .whereField("listingId", isEqualTo: listingId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error finding wishlist item: \(error)")
                            return
                        }
                        
                        for document in snapshot?.documents ?? [] {
                            document.reference.delete { error in
                                if let error = error {
                                    print("Error removing from wishlist: \(error)")
                                } else {
                                    print("Removed from wishlist")
                                    // Refresh the wishlist
                                    DispatchQueue.main.async {
                                        self.fetchWishlistItems()
                                    }
                                }
                            }
                        }
                    }
            }
    }
}
