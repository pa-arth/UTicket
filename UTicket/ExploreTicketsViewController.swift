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
    @IBOutlet weak var searchBar: UISearchBar!
    private var listings: [TicketListing] = []
    private var listingDocumentIDs: [String] = [] // Store document IDs for wishlist operations
    private var wishlistListingIDs: Set<String> = [] // Track which listings are in wishlist
    
    // Search filtering
    private var filteredListings: [TicketListing] = []
    private var filteredListingDocumentIDs: [String] = []
    private var isSearching: Bool = false
    
    // ⭐️ ADDED: Database reference
    private let db = Firestore.firestore()
    private let listingCollectionName = "ticketListings"
    private let wishlistCollectionName = "wishlists"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore Tickets"
        view.backgroundColor = .systemBackground
        
        // Check if outlets are connected
        guard tableView != nil else {
            print("❌ ERROR: tableView outlet is not connected!")
            return
        }
        
        guard searchBar != nil else {
            print("❌ ERROR: searchBar outlet is not connected!")
            return
        }
        
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
        
        // Setup search bar styling
        setupSearchBarStyling()
        
        print("✅ ExploreTicketsViewController viewDidLoad completed")
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
        print("📱 ExploreTicketsViewController viewWillAppear called")
        // ⭐️ CALL FETCH LOGIC: Fetches data every time the view appears.
        fetchExploreListings()
        fetchWishlistStatus()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTicketDetail",
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
    
    // ⭐️ ADDED: Firestore Fetch Method
    func fetchExploreListings() {
        print("🔍 Fetching listings from collection: \(listingCollectionName)")
        
        db.collection(listingCollectionName).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching explore documents: \(error.localizedDescription)")
                print("   Full error: \(error)")
                DispatchQueue.main.async {
                    // Show empty state or error message
                    self.listings = []
                    self.listingDocumentIDs = []
                    self.filteredListings = []
                    self.filteredListingDocumentIDs = []
                    self.tableView.reloadData()
                }
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ Snapshot is nil")
                DispatchQueue.main.async {
                    self.listings = []
                    self.listingDocumentIDs = []
                    self.filteredListings = []
                    self.filteredListingDocumentIDs = []
                    self.tableView.reloadData()
                }
                return
            }
            
            let documents = snapshot.documents
            print("✅ Fetched \(documents.count) documents from Firestore")
            
            if documents.isEmpty {
                print("⚠️ No documents found in collection '\(self.listingCollectionName)'")
            }
            
            // Store document IDs and decode listings
            self.listingDocumentIDs = documents.map { $0.documentID }
            var decodedListings: [TicketListing] = []
            var decodeErrors = 0
            
            for doc in documents {
                do {
                    let listing = try doc.data(as: TicketListing.self)
                    decodedListings.append(listing)
                } catch {
                    decodeErrors += 1
                    print("❌ Error decoding document \(doc.documentID): \(error)")
                    if let data = doc.data() as? [String: Any] {
                        print("   Document data: \(data)")
                    }
                }
            }
            
            if decodeErrors > 0 {
                print("⚠️ Failed to decode \(decodeErrors) out of \(documents.count) documents")
            }
            
            print("✅ Successfully decoded \(decodedListings.count) listings")
            self.listings = decodedListings
            
            // Initialize filtered arrays to match all listings
            self.filteredListings = self.listings
            self.filteredListingDocumentIDs = self.listingDocumentIDs
            
            // Reload the table on the main thread
            DispatchQueue.main.async {
                print("🔄 Reloading table view with \(self.listings.count) listings")
                
                // CRITICAL FIX: If table view has zero height, fix it immediately
                if self.tableView.frame.height == 0 {
                    print("⚠️ CRITICAL: Table view has zero height! Fixing...")
                    print("   Search bar frame: \(self.searchBar.frame)")
                    print("   View safe area frame: \(self.view.safeAreaLayoutGuide.layoutFrame)")
                    print("   View bounds: \(self.view.bounds)")
                    
                    // Calculate available height more accurately
                    let viewHeight = self.view.bounds.height
                    let safeAreaTop = self.view.safeAreaLayoutGuide.layoutFrame.minY
                    let safeAreaBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY
                    let searchBarHeight = self.searchBar.frame.height
                    let navBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
                    
                    // Available height = total view height - safe area top - search bar - navigation bar - some padding
                    let availableHeight = viewHeight - safeAreaTop - searchBarHeight - 16 // 16pt total padding
                    
                    print("   Calculated available height: \(availableHeight)")
                    
                    if availableHeight > 100 { // Only fix if we have reasonable space
                        // Try to find and update height constraint
                        var heightConstraintFound = false
                        
                        // Check view constraints
                        for constraint in self.view.constraints {
                            if (constraint.firstItem === self.tableView || constraint.secondItem === self.tableView) &&
                               (constraint.firstAttribute == .height || constraint.secondAttribute == .height) {
                                constraint.constant = availableHeight
                                heightConstraintFound = true
                                print("   Found and updated height constraint in view")
                                break
                            }
                        }
                        
                        // Check table view's own constraints
                        if !heightConstraintFound {
                            for constraint in self.tableView.constraints {
                                if constraint.firstAttribute == .height {
                                    constraint.constant = availableHeight
                                    heightConstraintFound = true
                                    print("   Found and updated height constraint in table view")
                                    break
                                }
                            }
                        }
                        
                        // If no constraint found, try setting frame directly (might work if autolayout isn't fully set up)
                        if !heightConstraintFound && self.tableView.translatesAutoresizingMaskIntoConstraints {
                            var frame = self.tableView.frame
                            frame.size.height = availableHeight
                            self.tableView.frame = frame
                            print("   Updated frame directly (frame-based layout)")
                        }
                        
                        // Force layout update
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                        
                        print("✅ Fixed table view. New frame: \(self.tableView.frame)")
                    } else {
                        print("⚠️ Available height too small (\(availableHeight)), skipping fix")
                    }
                }
                
                print("   Table view frame: \(self.tableView.frame)")
                
                // If currently searching, re-apply the search filter
                if self.isSearching, let searchText = self.searchBar.text, !searchText.isEmpty {
                    self.filterListings(searchText: searchText)
                } else {
                    // Reload the table view
                    self.tableView.reloadData()
                    
                    // Scroll to top to ensure visibility
                    if !self.listings.isEmpty {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Functionality
    
    private func filterListings(searchText: String) {
        let lowercasedSearch = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if lowercasedSearch.isEmpty {
            // Show all listings if search is empty
            filteredListings = listings
            filteredListingDocumentIDs = listingDocumentIDs
        } else {
            // Filter listings based on search text
            var filtered: [(listing: TicketListing, documentID: String)] = []
            
            for (index, listing) in listings.enumerated() {
                let documentID = listingDocumentIDs[index]
                
                // Search in event name, seat details, price, event date, and event time
                let eventNameMatch = listing.eventName.lowercased().contains(lowercasedSearch)
                let seatDetailsMatch = listing.seatDetails.lowercased().contains(lowercasedSearch)
                let priceMatch = listing.price.lowercased().contains(lowercasedSearch)
                let eventDateMatch = listing.eventDate?.lowercased().contains(lowercasedSearch) ?? false
                let eventTimeMatch = listing.eventTime.lowercased().contains(lowercasedSearch)
                
                if eventNameMatch || seatDetailsMatch || priceMatch || eventDateMatch || eventTimeMatch {
                    filtered.append((listing, documentID))
                }
            }
            
            filteredListings = filtered.map { $0.listing }
            filteredListingDocumentIDs = filtered.map { $0.documentID }
        }
        
        tableView.reloadData()
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
            // Remove from wishlist - fetch all user's wishlist items and filter in memory to avoid composite index
            db.collection(wishlistCollectionName)
                .whereField("userId", isEqualTo: userId)
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
                    
                    guard let documents = snapshot?.documents else {
                        print("No wishlist item found to remove")
                        completion(false)
                        return
                    }
                    
                    // Filter in memory to find matching listingId
                    let matchingDocs = documents.filter { doc in
                        return (doc.data()["listingId"] as? String) == listingId
                    }
                    
                    guard !matchingDocs.isEmpty else {
                        print("No wishlist item found to remove")
                        completion(false)
                        return
                    }
                    
                    // Delete all matching documents (should only be one)
                    let dispatchGroup = DispatchGroup()
                    var hasError = false
                    
                    for document in matchingDocs {
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
    
    // MARK: - Search Bar Styling
    
    private func setupSearchBarStyling() {
        searchBar.delegate = self
        
        // Set initial border properties
        searchBar.layer.borderWidth = 0
        searchBar.layer.cornerRadius = 5
        
        // Customize search bar appearance
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.borderWidth = 0
            textField.layer.cornerRadius = 5
            textField.backgroundColor = .systemBackground
            
            // Add observers for editing state
            textField.addTarget(self, action: #selector(textFieldDidBeginEditingInSearchBar(_:)), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(textFieldDidEndEditingInSearchBar(_:)), for: .editingDidEnd)
        }
    }
    
    @objc private func textFieldDidBeginEditingInSearchBar(_ textField: UITextField) {
        // Apply active outline color to the text field only
        textField.layer.borderWidth = 2.0
        textField.layer.borderColor = UIColor(hex: "#BF5700")?.cgColor
    }
    
    @objc private func textFieldDidEndEditingInSearchBar(_ textField: UITextField) {
        // Remove outline when editing ends
        textField.layer.borderWidth = 0
        textField.layer.borderColor = nil
    }
}

// MARK: - UISearchBarDelegate
extension ExploreTicketsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Show cancel button
        searchBar.showsCancelButton = true
        
        // Apply active outline color to the internal text field only
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.borderWidth = 2.0
            textField.layer.borderColor = UIColor(hex: "#BF5700")?.cgColor
        }
        
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Remove outline when editing ends (but keep searching if there's text)
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            if let searchText = searchBar.text, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Keep border if there's search text
                textField.layer.borderWidth = 2.0
                textField.layer.borderColor = UIColor(hex: "#BF5700")?.cgColor
            } else {
                // Remove border if search is empty
                textField.layer.borderWidth = 0
                textField.layer.borderColor = nil
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Filter listings as user types
        isSearching = true
        filterListings(searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss keyboard when search button is tapped
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Clear search and show all listings
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        isSearching = false
        filteredListings = listings
        filteredListingDocumentIDs = listingDocumentIDs
        tableView.reloadData()
        
        // Remove outline from text field
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.borderWidth = 0
            textField.layer.borderColor = nil
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ExploreTicketsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = isSearching ? filteredListings.count : listings.count
        if count == 0 {
            print("⚠️ numberOfRowsInSection returning 0 (isSearching: \(isSearching), listings: \(listings.count), filtered: \(filteredListings.count))")
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("📱 cellForRowAt called for indexPath: \(indexPath)")
        let listing = isSearching ? filteredListings[indexPath.row] : listings[indexPath.row]
        let listingId = isSearching ? filteredListingDocumentIDs[indexPath.row] : listingDocumentIDs[indexPath.row]
        let isInWishlist = wishlistListingIDs.contains(listingId)
        
        print("   Configuring cell for listing: \(listing.eventName)")
        
        // ⭐️ Dequeue the custom ListingCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListingCell", for: indexPath) as? ListingCell else {
            print("❌ Failed to dequeue ListingCell, returning default cell")
            return UITableViewCell()
        }
        
        print("   ✅ Successfully dequeued ListingCell")
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
        let listing = isSearching ? filteredListings[indexPath.row] : listings[indexPath.row]
        let listingId = isSearching ? filteredListingDocumentIDs[indexPath.row] : listingDocumentIDs[indexPath.row]
        // Pass both listing and document ID as a tuple
        performSegue(withIdentifier: "showTicketDetail", sender: (listing: listing, documentID: listingId))
    }
}
