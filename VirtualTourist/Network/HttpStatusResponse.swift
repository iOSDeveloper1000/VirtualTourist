//
//  HttpStatusResponse.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 16.01.21.
//

import Foundation


struct HttpStatusResponse: Codable {
    
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case code = "status"
        case message = "error"
    }

}
