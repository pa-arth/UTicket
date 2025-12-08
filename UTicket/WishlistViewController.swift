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
    private var wishlistListingIDs: [String] = [] // Store listing document IDs for efficient removal
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
           let dest = segue.destination as? TicketDetailViewController {
            // Handle both tuple (new way) and TicketListing (fallback)
            if let tuple = sender as? (listing: TicketListing, documentID: String) {
                dest.listing = tuple.listing
                dest.listingDocumentID = tuple.documentID
            } else if let listing = sender as? TicketListing {
                // Fallback for old code paths
                dest.listing = listing
            }
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
                var fetchedListingIDs: [String] = []
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
                                    fetchedListingIDs.append(listingId)
                                }
                            } catch {
                                print("Error decoding listing \(listingId): \(error)")
                            }
                        }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.wishlistItems = fetchedListings
                    self.wishlistListingIDs = fetchedListingIDs
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func removeFromWishlist(listingId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove from wishlist - fetch all user's wishlist items and filter in memory to avoid composite index
        db.collection(wishlistCollectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding wishlist item: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Wishlist item not found")
                    return
                }
                
                // Filter in memory to find matching listingId
                let matchingDocs = documents.filter { doc in
                    return (doc.data()["listingId"] as? String) == listingId
                }
                
                guard !matchingDocs.isEmpty else {
                    print("Wishlist item not found")
                    return
                }
                
                // Delete all matching documents (should only be one)
                let dispatchGroup = DispatchGroup()
                var hasError = false
                
                for document in matchingDocs {
                    dispatchGroup.enter()
                    document.reference.delete { error in
                        if let error = error {
                            print("Error removing from wishlist: \(error)")
                            hasError = true
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    if !hasError {
                        print("Removed from wishlist")
                        // Refresh the wishlist
                        self.fetchWishlistItems()
                    }
                }
            }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension WishlistViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Ensure arrays are in sync - use the minimum count to be safe
        return min(wishlistItems.count, wishlistListingIDs.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < wishlistItems.count && indexPath.row < wishlistListingIDs.count else {
            return UITableViewCell()
        }
        
        let listing = wishlistItems[indexPath.row]
        let listingId = wishlistListingIDs[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: listing, mode: .buyerWishlist, isInWishlist: true)
        
        // Heart button removes from wishlist
        cell.onHeartTapped = { [weak self] isAdding in
            if !isAdding {
                // Remove from wishlist using the stored listing ID
                self?.removeFromWishlist(listingId: listingId)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < wishlistItems.count && indexPath.row < wishlistListingIDs.count else {
            return
        }
        let listing = wishlistItems[indexPath.row]
        let listingId = wishlistListingIDs[indexPath.row]
        // Pass both listing and document ID as a tuple
        performSegue(withIdentifier: "showTicketDetailFromWishlist", sender: (listing: listing, documentID: listingId))
    }
}
