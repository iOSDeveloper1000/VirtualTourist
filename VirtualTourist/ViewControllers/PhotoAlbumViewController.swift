//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import UIKit
import MapKit
import CoreData


// MARK: PhotoAlbumViewController: UIViewController

class PhotoAlbumViewController: UIViewController {
    
    // Associated pin for the photo album presented in this view controller
    var pin: Pin!
    
    var dataController: DataController!
    
    private var fetchedResultsController: NSFetchedResultsController<Photo>!
    private var blockOperations: [BlockOperation] = []
    
    private var userInteractionEnabled = false
    
    let spacing: CGFloat = 8.0
    let itemsPerRow: Int = 3
    
    
    @IBOutlet weak var localMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableUserInteraction(false)
        
        setUpFetchedResultsController()
        
        setUpCollectionViewAndLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
        presentPinOnMap()
        
        // Start donwloading new photos in case none have been stored from previous run
        if pin.photos?.count == 0 {
            downloadPhotoUrls()
        } else {
            enableUserInteraction(true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        // Disallow user to make further interactions
        enableUserInteraction(false)
        
        // Remove existing photos and download new ones
        deleteAllPhotos()
        downloadPhotoUrls()
    }
    
    
    // MARK: Details map helper
    
    private func presentPinOnMap() {

        if let pin = pin {
            
            // Present pin on local map
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
                
                // CASE: No images available.
            }
            
            // Reenable user interaction
            self.enableUserInteraction(true)
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
    
    
    // MARK: User Interaction helper
    
    private func enableUserInteraction(_ state: Bool) {
        newCollectionButton.isEnabled = state
        userInteractionEnabled = state
    }
    
    
    // MARK: Setup methods
    
    private func setUpFetchedResultsController() {
        // Set up the current map excerpt with pins from persistence
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.objectID)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription) // TODO: Error handling
        }
    }
    
    private func setUpCollectionViewAndLayout() {
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
        let photosCount = fetchedResultsController.sections?[section].numberOfObjects ?? 0
        
        if photosCount == 0 {
            collectionView.setBackgroundMessage(message: "No images")
        } else {
            collectionView.removeBackgroundMessage()
        }
        
        print("number of photos: \(photosCount)")
        return photosCount
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
        if userInteractionEnabled {
            let alertVC = UIAlertController(title: "Delete photo?", message: "The photo will be removed permanently from the app.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.deletePhoto(indexPath: indexPath)
            }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
}


// MARK: UICollectionView Extension

extension UICollectionView {
    func setBackgroundMessage(message: String) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        label.text = message
        label.textAlignment = .center
        label.textColor = .gray
        
        backgroundView = label
    }
    
    func removeBackgroundMessage() {
        backgroundView = nil
    }
}


// MARK: NSFetchedResultsController Delegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    /* Implementation inspired by this Swift 4 solution https://stackoverflow.com/a/34694755 */
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerWillChangeContent")
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("FRC didChange anObject")
        
        let operation: BlockOperation
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            operation = BlockOperation(block: {
                self.collectionView.insertItems(at: [newIndexPath])
            })
        case .delete:
            guard let indexPath = indexPath else { return }
            operation = BlockOperation(block: {
                self.collectionView.deleteItems(at: [indexPath])
            })
        case .update:
            guard let indexPath = indexPath else { return }
            operation = BlockOperation(block: {
                self.collectionView.reloadItems(at: [indexPath])
            })
        case .move:
            fatalError("Move operation not supported for collection view items")
        @unknown default:
            fatalError("Unknown type in changing an object from collection view")
        }
        
        blockOperations.append(operation)
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
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerDidChangeContent")
        
        collectionView.performBatchUpdates {
            self.blockOperations.forEach { $0.start() }
        } completion: { (finished) in
            self.blockOperations.removeAll(keepingCapacity: false)
        }
    }
}
