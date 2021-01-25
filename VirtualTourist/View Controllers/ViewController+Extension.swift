//
//  ViewController+Extension.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 25.01.21.
//

import UIKit


// Handling Errors
// Inspired by https://stackoverflow.com/a/60414319

extension UIViewController {
    
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
    
    
    func notifyWithAlert(errorCase: Case, message: String){

        let alertController = UIAlertController(title: errorCase.title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertController, animated: true)
    }
    
}

