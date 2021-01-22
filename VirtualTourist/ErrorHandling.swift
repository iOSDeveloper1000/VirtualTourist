//
//  ErrorHandling.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 22.01.21.
//

import UIKit


class ErrorHandling {
    
    enum Case {
        case networkOffline
        case dataFetchFailed
        case unknownMapAnnotation
        case unsupportedOperation
        case noImagesAvailable
        case urlInvalid
        case couldNotSave
        
        var title: String {
            switch self {
            case .networkOffline:
                return "Network connection offline"
            case .dataFetchFailed:
                return "Could not retrieve data"
            case .unknownMapAnnotation:
                return "Unknown map annotation entry"
            case .unsupportedOperation:
                return "Operation is not supported"
            case .noImagesAvailable:
                return "No images available"
            case .urlInvalid:
                return "URL invalid"
            case .couldNotSave:
                return "Saving failed"
            }
        }
    }
    
    class func notifyUser(onVC controller: UIViewController, case error: Case, detailedDescription: String = "Unknown error") {
        let alertVC = UIAlertController(title: error.title, message: detailedDescription, preferredStyle: .alert)

        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        controller.present(alertVC, animated: true, completion: nil)
    }
    
}
