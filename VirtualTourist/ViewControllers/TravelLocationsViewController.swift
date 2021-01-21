//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import UIKit
import MapKit
import CoreData


class TravelLocationsViewController: UIViewController {
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    struct UserDefaultKey {
        static let mapHasLaunchedKey = "KeyForMapHasLaunchedBefore"
        
        static let mapCenterLatKey = "KeyForMapCenterLatitude"
        static let mapCenterLonKey = "KeyForMapCenterLongitude"
        static let mapSpanLatDeltaKey = "KeyForMapLatitudinalDelta"
        static let mapSpanLonDeltaKey = "KeyForMapLongitudinalDelta"
    }
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: Life cycle
    
    fileprivate func setUpFetchedResultsController() {
        // Set up the current map excerpt with pins from persistence
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        //let predicate = NSPredicate(value: true) // TODO: set to map excerpt ?
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            updatePins()
        } catch {
            fatalError(error.localizedDescription) // TODO: Error handling
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(recognizeTouchAndHoldGestureOnMap(_:)))
        longPressRecognizer.minimumPressDuration = 1.5
        
        mapView.delegate = self
        mapView.gestureRecognizers = [longPressRecognizer]
        
        setUpFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
        setUpMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    
    // MARK: Map view helpers
    
    private func setUpMap() {
        if UserDefaults.standard.bool(forKey: UserDefaultKey.mapHasLaunchedKey) {
            print("Map has launched before")
            
            fetchMapSettings()
            
        } else {
            print("This is map's first launch ever!")
            
            UserDefaults.standard.set(true, forKey: UserDefaultKey.mapHasLaunchedKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func fetchMapSettings() {
        let mapCenterLatitude = UserDefaults.standard.double(forKey: UserDefaultKey.mapCenterLatKey)
        let mapCenterLongitude = UserDefaults.standard.double(forKey: UserDefaultKey.mapCenterLonKey)
        let mapSpanLatDelta = UserDefaults.standard.double(forKey: UserDefaultKey.mapSpanLatDeltaKey)
        let mapSpanLonDelta = UserDefaults.standard.double(forKey: UserDefaultKey.mapSpanLonDeltaKey)
        
        let mapCenter = CLLocationCoordinate2D(latitude: mapCenterLatitude, longitude: mapCenterLongitude)
        let mapSpan = MKCoordinateSpan(latitudeDelta: mapSpanLatDelta, longitudeDelta: mapSpanLonDelta)
        let mapRegion = MKCoordinateRegion(center: mapCenter, span: mapSpan)
        
        mapView.setRegion(mapRegion, animated: false)
    }
    
    private func saveMapSettings() {
        print("Store map settings in user defaults")
        
        let mapCenter = mapView.centerCoordinate
        let mapSpan = mapView.region.span
        
        UserDefaults.standard.set(mapCenter.latitude, forKey: UserDefaultKey.mapCenterLatKey)
        UserDefaults.standard.set(mapCenter.longitude, forKey: UserDefaultKey.mapCenterLonKey)
        UserDefaults.standard.set(mapSpan.latitudeDelta, forKey: UserDefaultKey.mapSpanLatDeltaKey)
        UserDefaults.standard.set(mapSpan.longitudeDelta, forKey: UserDefaultKey.mapSpanLonDeltaKey)
    }
    
    private func updatePins() {
        if let pins = fetchedResultsController.fetchedObjects {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(pins)
        } else {
            print("updatePins() else path")
            // TODO: Error handling
        }
    }
}


// MARK: MKMapView Delegate
 
extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reusePinId = "PinIdentifier"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusePinId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusePinId)
            
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.pinTintColor = MKPinAnnotationView.purplePinColor()
        
        } else {
            
            pinView?.annotation = annotation
        
        }
        
        print("Pin - Latitude: \(annotation.coordinate.latitude) - Longitude: \(annotation.coordinate.longitude)")
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? Pin {
            
            let photoAlbumVC = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            photoAlbumVC.pin = pin
            photoAlbumVC.dataController = dataController
            
            navigationController?.pushViewController(photoAlbumVC, animated: true)
            
        } else {
            print("!!! Annotation is no Pin !!!")
            // TODO: Error handling
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Region did change animated")
        saveMapSettings()
    }
}


// MARK: Extension for Gesture Recognition

extension TravelLocationsViewController {
    
    @objc private func recognizeTouchAndHoldGestureOnMap(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.ended else {
            return
        }
        
        let location = sender.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Save coordinates in a Pin entity
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinates.latitude
        pin.longitude = coordinates.longitude
        try? dataController.viewContext.save()
        //dataController.saveInMainContext()
    }
}


// MARK: NSFetchedResultsController Delegate

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            fatalError("Object cannot be converted to Pin") // TODO
        }
        
        print("controller(_:didChange:at:for:newIndexPath:)")
        
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
        case .delete:
            mapView.removeAnnotation(pin)
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
        default:
            fatalError("Cases other than .insert and .delete are not supported for pins.")
        }
    }
}
