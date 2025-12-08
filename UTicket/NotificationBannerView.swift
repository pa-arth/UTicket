//
//  NotificationBannerView.swift
//  UTicket
//
//  Created by AI on 12/3/25.
//

import UIKit

class NotificationBannerView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var onTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    func configure(title: String, message: String, type: NotificationType) {
        titleLabel.text = title
        messageLabel.text = message
        
        switch type {
        case .newListing:
            iconImageView.image = UIImage(systemName: "ticket.fill")
        case .purchaseInterest:
            iconImageView.image = UIImage(systemName: "hand.raised.fill")
        }
    }
    
    @objc private func handleTap() {
        onTap?()
    }
}

extension NotificationManager {
    func showBanner(for notification: AppNotification, notificationId: String, in viewController: UIViewController) {
        guard let window = viewController.view.window else { return }
        
        let banner = NotificationBannerView()
        banner.configure(title: notification.title, message: notification.message, type: NotificationType(rawValue: notification.type) ?? .newListing)
        
        banner.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(banner)
        
        // Position banner at top, initially off-screen
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
            banner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: -100),
            banner.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])
        
        window.layoutIfNeeded()
        
        // Animate banner sliding down
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            banner.transform = CGAffineTransform(translationX: 0, y: 100)
        } completion: { _ in
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                    banner.transform = CGAffineTransform(translationX: 0, y: -100)
                } completion: { _ in
                    banner.removeFromSuperview()
                }
            }
        }
        
        // Handle tap to navigate
        banner.onTap = { [weak self] in
            self?.handleNotificationTap(notification: notification, notificationId: notificationId, in: viewController)
            UIView.animate(withDuration: 0.3) {
                banner.alpha = 0
            } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }
    
    private func handleNotificationTap(notification: AppNotification, notificationId: String, in viewController: UIViewController) {
        // Mark as read
        markNotificationAsRead(notificationId: notificationId)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch NotificationType(rawValue: notification.type) {
        case .newListing:
            // Navigate to explore screen to see new listings
            if let exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreVC") as? ExploreTicketsViewController {
                viewController.navigationController?.pushViewController(exploreVC, animated: true)
            }
            
        case .purchaseInterest:
            // Navigate to seller dashboard to see purchase requests
            if let sellerDashboardVC = storyboard.instantiateViewController(withIdentifier: "sellerListing") as? SellerDashboardViewController {
                viewController.navigationController?.pushViewController(sellerDashboardVC, animated: true)
            }
            
        case .none:
            break
        }
    }
}

