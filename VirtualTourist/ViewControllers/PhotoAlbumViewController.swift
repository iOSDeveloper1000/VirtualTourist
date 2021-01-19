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
    
    let spacing: CGFloat = 8.0
    let itemsPerRow: Int = 3
    
    
    @IBOutlet weak var localMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
        
        setUpCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
        presentPinOnMap()
        
        print("Photos count is \(pin.photos?.count ?? -1)")
        if pin.photos?.count == 0 {
            downloadPhotoUrls()
        } else {
            print("No further download necessary")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        deleteAllPhotos()
        downloadPhotoUrls()
    }
    
    
    // MARK: Details map helper
    
    private func presentPinOnMap() {

        if let pin = pin {
            
            // Present pin on local map
            localMap.view(for: pin)?.tintColor = MKPinAnnotationView.purplePinColor()
            localMap.showAnnotations([pin], animated: true)
        
        } else {
            // TODO: Error handling
            print("Pin is nil.")
        }
    }
    
    
    // MARK: Collection View helper
    
    private func downloadPhotoUrls() {
        _ = NetworkClient.downloadListOfPhotoUrls(latitude: pin.latitude, longitude: pin.longitude) { (urlList, statusResponse, error) in
            if let urlList = urlList {
                for url in urlList {
                    self.addPhoto(urlString: url)
                }
            } else {
                // TODO: Error handling
                print("Didn't get a url list")
            }
        }
    }
    
    private func addPhoto(urlString: String) {
        
        let photo = Photo(context: dataController.viewContext)
        photo.url = urlString
        photo.pin = pin
        try? dataController.viewContext.save()
    
        // Start downloading photo
        if let url = URL(string: urlString) {
            downloadPhotoData(url: url) { (imgData) in
                photo.image = imgData
                try? self.dataController.viewContext.save()
            }
        } else {
            print("URL Could not be retrieved")
        }
    }
    
    private func downloadPhotoData(url: URL, completion: @escaping (Data?) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url) {
                
                DispatchQueue.main.async {
                    completion(data)
                }
            } else {
                print("Data could not be downloaded")
            }
        }
        
        // TODO: Error handling & saving of image data to Photo object
    }
    
    private func deletePhoto(indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    private func deleteAllPhotos() {
        if let photos = pin.photos {
            for photo in photos {
                dataController.viewContext.delete(photo as! NSManagedObject)
            }
            try? dataController.viewContext.save()
        } else {
            print("Photos array is nil")
            // TODO: Error handling
        }
    }
    
    
    // MARK: Setup methods
    
    private func setUpFetchedResultsController() {
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
    
    private func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Set up flow layout
        let shortEdge = min(collectionView.frame.size.width, collectionView.frame.size.height) // short edge of display (depending on orientation)
        let padding = (CGFloat(itemsPerRow) - 1) * spacing
        let itemSize = (shortEdge - padding) / CGFloat(itemsPerRow)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.itemSize = CGSize(width: itemSize, height: itemSize)
    }
}


// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("number of photos: \(pin.photos?.count ?? 0)")
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.object(at: indexPath)
        if let img = photo.image {
            cell.imageView.image = UIImage(data: img)
        } else {
            print("Photo not yet downloaded")
            cell.imageView.image = UIImage(named: "VirtualTourist_placeholder")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: "Delete photo?", message: "The photo will be removed permanently from the app.", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.deletePhoto(indexPath: indexPath)
        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
}


// MARK: UICollectionViewDelegateFlowLayout

/*extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    // Setting the cell sizes properly
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //print("collectionView.frame.width is \(collectionView.frame.width)")
        
        let itemSize = (collectionView.frame.width - CGFloat(2 * cellsPerRow + 1) * cellInset) / CGFloat(cellsPerRow)
        return CGSize(width: itemSize, height: itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellInset, left: cellInset, bottom: cellInset, right: cellInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellInset
    }
}*/


// MARK: NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("FRC didChange anObject")
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("FRC didChange sectionInfo")
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            collectionView.insertSections(indexSet)
        case .delete:
            collectionView.deleteSections(indexSet)
        default:
            fatalError("Invalid change type in collection view controller for section index \(sectionIndex)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerWillChangeContent")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerDidChangeContent")
    }
}
