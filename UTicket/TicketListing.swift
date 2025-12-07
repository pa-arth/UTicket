//
//  TicketListing.swift
//  UTicket
//
//  Created by Zaviyan Tharwani on 10/22/25.
//

import UIKit
import FirebaseFirestore

struct TicketListing: Hashable, Codable {
    let eventName: String
    let price: String
    let eventDate: String?
    let eventTime: String
    let seatDetails: String
    let imageURL: String
    let sellerID: String
    let createdAt: Timestamp?
    let isSold: Bool
    
    // CodingKeys to map Firestore field names to struct properties
    enum CodingKeys: String, CodingKey {
        case eventName
        case price
        case eventDate
        case eventTime
        case seatDetails
        case imageURL
        case sellerID
        case createdAt
        case isSold
    }
}
