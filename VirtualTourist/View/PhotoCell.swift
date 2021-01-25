//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 18.01.21.
//

import UIKit


class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
 
    
    func showPlaceholder() {
        imageView.image = UIImage(named: "VirtualTourist_placeholder")
        imageView.alpha = 0.3
        
        activityIndicator.startAnimating()
    }
    
    func presentImage(image: UIImage?) {
        imageView.image = image
        imageView.alpha = 1.0  // Reset alpha value back to normal
        
        activityIndicator.stopAnimating()
    }
}
