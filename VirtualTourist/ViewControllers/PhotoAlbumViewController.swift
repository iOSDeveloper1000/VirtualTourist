//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController {
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    
    @IBOutlet weak var localMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
}
