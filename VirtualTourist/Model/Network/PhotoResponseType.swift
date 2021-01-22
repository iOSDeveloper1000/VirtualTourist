//
//  PhotoResponseType.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 16.01.21.
//

import Foundation


struct PhotoType: Decodable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    
}

struct PhotosType: Decodable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    
    let photo: [PhotoType]
    
}

struct PhotoResponseType: Decodable {
    
    let photos: PhotosType
    let stat: String
    
}
