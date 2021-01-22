//
//  HttpStatusResponse.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 16.01.21.
//

import Foundation


struct HttpStatusResponse: Codable {
    
    let stat: String
    let code: Int
    let message: String

}
