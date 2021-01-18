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
    
    // Associated pin for the photo album presented in this view controller
    var pin: Pin!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    
    @IBOutlet weak var localMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    // MARK: Life cycle
    
    fileprivate func setupFetchedResultsController() {
        // Set up the current map excerpt with pins from persistence
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.objectID)-photos")
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription) // TODO: Error handling
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO
        setupFetchedResultsController()
        
        presentPinOnMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        downloadPhotoUrls()
    }
    
    // MARK: Helper
    
    private func presentPinOnMap() {

        if let pin = pin {
            
            // Present pin on local map
            localMap.view(for: pin)?.tintColor = MKPinAnnotationView.purplePinColor()
            localMap.showAnnotations([pin], animated: true)
        
        } else {
            // TODO: Error handling
        }
    }
    
    private func downloadPhotoUrls() {
        NetworkClient.downloadListOfPhotoUrls(latitude: pin.latitude, longitude: pin.longitude) { (urlList, statusResponse, error) in
            if let urlList = urlList {
                for url in urlList {
                    self.addPhoto(url: url)
                }
            } else {
                // TODO: Error handling
            }
        }
    }
    
    private func addPhoto(url: String) {
        
        let photo = Photo(context: dataController.viewContext)
        photo.url = url
        photo.pin = pin
        try? dataController.viewContext.save()
    
    }
    
    private func downloadPhotoData(photo: Photo, completion: @escaping (UIImage?) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = URL(string: photo.url!),
               let data = try? Data(contentsOf: url) {
                // Convert downloaded image data to UIImage object
                let image = UIImage(data: data)
                
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
        
        // TODO: Error handling & saving of image data to Photo object
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.object(at: indexPath)
        if let img = photo.image {
            cell.imageView.image = UIImage(data: img)
        } else {
            print("Photo not yet downloaded")
            cell.imageView.image = UIImage(named: "placeholder")
            downloadPhotoData(photo: photo) { (image) in
                cell.imageView.image = image
            }
        }
        
        return cell
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [indexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError("Unknown type in changing an object from collection view")
        }
    }
    
}
