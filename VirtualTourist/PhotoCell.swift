//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 18.01.21.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    //var photo: Photo!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        imageView.image = nil // UIImage(data: photo.image)
    }
}
