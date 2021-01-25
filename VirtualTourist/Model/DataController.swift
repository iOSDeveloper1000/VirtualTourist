//
//  DataController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import Foundation
import UIKit
import CoreData


class DataController {
    
    let persistentContainer: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            self.autoSaveViewContext()
            completion?()
        }
    }
    
    func saveViewContext(viewController: UIViewController? = nil) {
        
        if viewContext.hasChanges {
            
            do {
                try viewContext.save()
            
            } catch {
                viewController?.notifyWithAlert(errorCase: .couldNotSave, message: "Internal error: \(error.localizedDescription)")
            }
        }
    }
    
    func autoSaveViewContext(interval: TimeInterval = 50) {
        
        guard interval > 0 else {
            print("Cannot set negative autosave interval")
            return
        }
        
        saveViewContext()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
