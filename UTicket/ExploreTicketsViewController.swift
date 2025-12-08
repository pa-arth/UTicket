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
        
        // Setup wishlist button action
        setupWishlistButton()
        
        // ❌ REMOVED: tableView.reloadData() (It should happen after data is fetched)
    }
    
    // MARK: - Navigation Setup
    
    private func setupWishlistButton() {
        // Set up the wishlist button action programmatically
        // This works whether the button is set in storyboard or not
        if let wishlistButton = navigationItem.leftBarButtonItem {
            wishlistButton.target = self
            wishlistButton.action = #selector(wishlistButtonTapped)
        } else {
            // If button doesn't exist, create it programmatically
            let wishlistButton = UIBarButtonItem(title: "Wishlist", style: .plain, target: self, action: #selector(wishlistButtonTapped))
            wishlistButton.tintColor = UIColor(red: 0.676, green: 0.333, blue: 0.034, alpha: 1.0)
            navigationItem.leftBarButtonItem = wishlistButton
        }
    }
    
    @objc private func wishlistButtonTapped(_ sender: UIBarButtonItem) {
        navigateToWishlist()
    }
    
    private func navigateToWishlist() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let wishlistVC = storyboard.instantiateViewController(withIdentifier: "wishlist") as? WishlistViewController {
            navigationController?.pushViewController(wishlistVC, animated: true)
        }
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
    
    func toggleWishlist(listingId: String, isAdding: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            completion(false)
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
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error adding to wishlist: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        self?.wishlistListingIDs.insert(listingId)
                        print("✅ Added to wishlist: \(listingId)")
                        // Reload table view to update heart icon state
                        self?.tableView.reloadData()
                        completion(true)
                    }
                }
            }
        } else {
            // Remove from wishlist
            db.collection(wishlistCollectionName)
                .whereField("userId", isEqualTo: userId)
                .whereField("listingId", isEqualTo: listingId)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    
                    if let error = error {
                        print("Error finding wishlist item: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No wishlist item found to remove")
                        completion(false)
                        return
                    }
                    
                    // Delete all matching documents (should only be one)
                    let dispatchGroup = DispatchGroup()
                    var hasError = false
                    
                    for document in documents {
                        dispatchGroup.enter()
                        document.reference.delete { error in
                            if let error = error {
                                print("Error removing from wishlist: \(error.localizedDescription)")
                                hasError = true
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        if !hasError {
                            self.wishlistListingIDs.remove(listingId)
                            print("✅ Removed from wishlist: \(listingId)")
                            // Reload table view to update heart icon state
                            self.tableView.reloadData()
                            completion(true)
                        } else {
                            completion(false)
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
        cell.onHeartTapped = { [weak self, weak cell] isAdding in
            guard let self = self, let cell = cell else { return }
            
            // Store the current state in case we need to revert
            let previousState = isInWishlist
            
            // Perform the wishlist operation
            self.toggleWishlist(listingId: listingId, isAdding: isAdding) { success in
                DispatchQueue.main.async {
                    if !success {
                        // Revert the cell state if operation failed
                        // The cell's internal state was already toggled, so we revert it
                        cell.configure(with: listing, mode: .buyerWishlist, isInWishlist: previousState)
                    }
                    // If successful, the table view will reload and update all cells
                }
            }
        }
        
        return cell
    }
    
    // Handles the tap and performs the segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showTicketDetail", sender: listings[indexPath.row])
    }
}
