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
 
    
    func showPlaceholder(show: Bool, image: UIImage?) {
        
        imageView.image = show ? UIImage(named: "VirtualTourist_placeholder") : image
        imageView.alpha = show ? 0.3 : 1.0
        
        show ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
}
