//
//  NotificationManager.swift
//  UTicket
//
//  Created by AI on 12/3/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

enum NotificationType: String {
    case newListing = "new_listing"
    case purchaseInterest = "purchase_interest"
}

struct AppNotification: Codable {
    let userId: String
    let type: String
    let title: String
    let message: String
    let listingId: String
    let buyerId: String?
    let isRead: Bool
    let createdAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case userId
        case type
        case title
        case message
        case listingId
        case buyerId
        case isRead
        case createdAt
    }
}

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    private let db = Firestore.firestore()
    private let notificationsCollection = "notifications"
    private let usersCollection = "users"
    private var listener: ListenerRegistration?
    private var shownNotificationIds: Set<String> = []
    
    private init() {}
    
    // MARK: - Notification Preferences
    
    func getNotificationPreference(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection(usersCollection).document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching notification preference: \(error)")
                completion(true) // Default to enabled
                return
            }
            
            if let data = document?.data(),
               let notificationsEnabled = data["notificationsEnabled"] as? Bool {
                completion(notificationsEnabled)
            } else {
                completion(true) // Default to enabled if not set
            }
        }
    }
    
    func setNotificationPreference(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection(usersCollection).document(userId).setData([
            "notificationsEnabled": enabled
        ], merge: true) { error in
            if let error = error {
                print("Error saving notification preference: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Create Notifications
    
    func createNewListingNotification(listingId: String, listingName: String, sellerId: String) {
        // Get all users except the seller
        db.collection(usersCollection).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching users for notifications: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let batch = self.db.batch()
            var batchCount = 0
            
            for document in documents {
                let userId = document.documentID
                
                // Skip the seller
                if userId == sellerId {
                    continue
                }
                
                // Check if user has notifications enabled
                let notificationsEnabled = document.data()["notificationsEnabled"] as? Bool ?? true
                if !notificationsEnabled {
                    continue
                }
                
                // Create notification document
                let notificationRef = self.db.collection(self.notificationsCollection).document()
                let notificationData: [String: Any] = [
                    "userId": userId,
                    "type": NotificationType.newListing.rawValue,
                    "title": "New Ticket Available",
                    "message": "\(listingName) is now available for purchase",
                    "listingId": listingId,
                    "buyerId": NSNull(),
                    "isRead": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                batch.setData(notificationData, forDocument: notificationRef)
                batchCount += 1
                
                // Firestore batch limit is 500
                if batchCount >= 500 {
                    batch.commit { error in
                        if let error = error {
                            print("Error creating notifications batch: \(error)")
                        }
                    }
                    batchCount = 0
                }
            }
            
            // Commit remaining notifications
            if batchCount > 0 {
                batch.commit { error in
                    if let error = error {
                        print("Error creating notifications: \(error)")
                    } else {
                        print("Created \(batchCount) new listing notifications")
                    }
                }
            }
        }
    }
    
    func createPurchaseInterestNotification(listingId: String, listingName: String, sellerId: String, buyerId: String) {
        // Check if seller has notifications enabled
        db.collection(usersCollection).document(sellerId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking seller notification preference: \(error)")
                return
            }
            
            let notificationsEnabled = document?.data()?["notificationsEnabled"] as? Bool ?? true
            if !notificationsEnabled {
                return
            }
            
            // Create notification for seller
            let notificationData: [String: Any] = [
                "userId": sellerId,
                "type": NotificationType.purchaseInterest.rawValue,
                "title": "Purchase Interest",
                "message": "Someone is interested in purchasing \(listingName)",
                "listingId": listingId,
                "buyerId": buyerId,
                "isRead": false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            self.db.collection(self.notificationsCollection).addDocument(data: notificationData) { error in
                if let error = error {
                    print("Error creating purchase interest notification: \(error)")
                } else {
                    print("Created purchase interest notification for seller")
                }
            }
        }
    }
    
    // MARK: - Real-time Notification Listener
    
    func startListeningForNotifications(completion: @escaping (AppNotification, String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Stop existing listener if any
        listener?.remove()
        shownNotificationIds.removeAll()
        
        // Listen for all notifications for this user (filter and sort in memory to avoid composite index)
        listener = db.collection(notificationsCollection)
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for notifications: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                // Check if this is a new notification (not from initial load)
                if snapshot?.metadata.isFromCache == true {
                    return
                }
                
                // Check if user has notifications enabled
                self.getNotificationPreference { enabled in
                    if !enabled {
                        return
                    }
                    
                    // Filter unread notifications and sort by createdAt in memory
                    let unreadNotifications = documents.compactMap { doc -> (AppNotification, String)? in
                        do {
                            var notification = try doc.data(as: AppNotification.self)
                            // Only process unread notifications
                            guard !notification.isRead else { return nil }
                            
                            let notificationId = doc.documentID
                            // Skip if we've already shown this notification
                            guard !self.shownNotificationIds.contains(notificationId) else { return nil }
                            
                            return (notification, notificationId)
                        } catch {
                            print("Error decoding notification: \(error)")
                            return nil
                        }
                    }
                    .sorted { first, second in
                        // Sort by createdAt descending (most recent first)
                        let firstTime = first.0.createdAt?.dateValue() ?? Date.distantPast
                        let secondTime = second.0.createdAt?.dateValue() ?? Date.distantPast
                        return firstTime > secondTime
                    }
                    
                    // Process new notifications
                    for (notification, notificationId) in unreadNotifications {
                        self.shownNotificationIds.insert(notificationId)
                        completion(notification, notificationId)
                    }
                }
            }
    }
    
    func stopListeningForNotifications() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Mark Notification as Read
    
    func markNotificationAsRead(notificationId: String) {
        db.collection(notificationsCollection).document(notificationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking notification as read: \(error)")
            }
        }
    }
}

