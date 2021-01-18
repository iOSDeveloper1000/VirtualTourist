//
//  DataController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import Foundation
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
            
            completion?()
        }
    }
    
    func saveInMainContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error while saving")
                print(error.localizedDescription)
            }
        }
    }
    
}
