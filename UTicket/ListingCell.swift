//
//    ListingCell.swift
//    UTicket
//
//    Created by AI on 12/3/25.
//

import UIKit
import Kingfisher // ⭐️ ADDED: Required for UIImageView extensions/types
// (Assuming ImageLoader.swift is available globally)

enum ListingCellMode {
    case buyerWishlist
    case sellerMyTickets
}

class ListingCell: UITableViewCell {
    
    // MARK: - UI Elements
    let ticketImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let eventNameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let seatImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.3")
        iv.tintColor = .systemGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let seatLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let heartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Closure to handle heart button tap
    var onHeartTapped: ((Bool) -> Void)?
    private var currentListing: TicketListing?
    private var isInWishlist: Bool = false {
        didSet {
            heartButton.isSelected = isInWishlist
        }
    }
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        contentView.addSubview(ticketImageView)
        contentView.addSubview(eventNameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(seatImageView)
        contentView.addSubview(seatLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(heartButton)
        
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            ticketImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            ticketImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            ticketImageView.widthAnchor.constraint(equalToConstant: 100),
            ticketImageView.heightAnchor.constraint(equalToConstant: 80),
            ticketImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            eventNameLabel.topAnchor.constraint(equalTo: ticketImageView.topAnchor),
            eventNameLabel.leadingAnchor.constraint(equalTo: ticketImageView.trailingAnchor, constant: 12),
            eventNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            priceLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: eventNameLabel.leadingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: eventNameLabel.leadingAnchor),
            
            timeLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 6),
            
            seatImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 6),
            seatImageView.leadingAnchor.constraint(equalTo: eventNameLabel.leadingAnchor),
            seatImageView.widthAnchor.constraint(equalToConstant: 14),
            seatImageView.heightAnchor.constraint(equalToConstant: 14),
            
            seatLabel.centerYAnchor.constraint(equalTo: seatImageView.centerYAnchor),
            seatLabel.leadingAnchor.constraint(equalTo: seatImageView.trailingAnchor, constant: 4),
            seatLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            statusLabel.topAnchor.constraint(equalTo: seatLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: eventNameLabel.leadingAnchor),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            heartButton.topAnchor.constraint(equalTo: ticketImageView.topAnchor),
            heartButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            heartButton.widthAnchor.constraint(equalToConstant: 30),
            heartButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func heartButtonTapped() {
        // Store the current state before toggling
        let wasInWishlist = isInWishlist
        let willBeAdding = !wasInWishlist
        
        // Toggle the wishlist state for immediate UI feedback
        isInWishlist.toggle()
        
        // Call the closure to handle Firestore operations
        // Pass true if adding, false if removing
        if let handler = onHeartTapped {
            handler(willBeAdding)
        } else {
            // If closure is not set, revert the toggle
            print("Warning: onHeartTapped closure is not set for ListingCell")
            isInWishlist = wasInWishlist
        }
    }
    
    // MARK: - Configure Cell
    // ⭐️ UPDATED: Removed ticketImage parameter
    func configure(with listing: TicketListing, mode: ListingCellMode, isInWishlist: Bool = false) {
        currentListing = listing
        
        //    1. Set your text labels
        eventNameLabel.text = listing.eventName
        priceLabel.text = listing.price
        dateLabel.text = listing.eventDate ?? "Date TBD"
        timeLabel.text = listing.eventTime
        seatLabel.text = listing.seatDetails
        
        //    2. ⭐️ Fetch image using the shared ImageLoader
        //    This replaces the need for the `ticketImage` parameter.
        ImageLoader.shared.loadImage(into: ticketImageView, from: listing.imageURL)
        
        switch mode {
        case .buyerWishlist:
            //    For the buyer, hide the detailed status and show a 'heart' icon.
            statusLabel.isHidden = true
            heartButton.isHidden = false
            self.isInWishlist = isInWishlist
            // Ensure heart button is enabled and interactive
            heartButton.isEnabled = true
            heartButton.isUserInteractionEnabled = true
            
        case .sellerMyTickets:
            //    For the seller, we show the status label based on isSold.
            statusLabel.isHidden = false
            statusLabel.text = listing.isSold ? "Sold" : "Available"
            statusLabel.textColor = listing.isSold ? .systemRed : .systemGreen
            heartButton.isHidden = true
        }
    }
    
    // Reset cell state when reused
    override func prepareForReuse() {
        super.prepareForReuse()
        // Don't clear onHeartTapped here - it will be set in cellForRowAt
        // But reset the wishlist state
        isInWishlist = false
    }
}
