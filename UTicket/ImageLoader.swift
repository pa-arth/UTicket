//
//    ImageLoader.swift
//    UTicket
//

import UIKit
import Kingfisher

class ImageLoader {
    //    The shared singleton instance
    static let shared = ImageLoader()
    
    private init() {} //    Prevents others from creating an instance
    
    /**
     *    Loads an image asynchronously using Kingfisher and sets it on the target UIImageView.
     *    - Parameter imageView: The UIImageView to set the image on.
     *    - Parameter imageURLString: The URL string (e.g., Firebase Download URL) for the image.
     */
    @MainActor // ⭐️ SOLUTION: Explicitly mark this function to run on the Main Actor
    func loadImage(into imageView: UIImageView, from imageURLString: String) {
        //    1. Ensure the URL is valid
        guard let url = URL(string: imageURLString) else {
            //    Fall back to a local placeholder if the URL is invalid/missing
            //    This line is already on the Main Actor due to the @MainActor annotation
            imageView.image = UIImage(named: "placeholder_image")
            return
        }
        
        //    2. Use Kingfisher to handle the asynchronous loading, caching, and setting
        //    All UIImageView property access is now safely on the Main Actor.
        imageView.kf.indicatorType = .activity //    Show a loading indicator
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder_image"), //    Use a default placeholder
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )
    }
}
