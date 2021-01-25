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
    
    let reusePinIdentifier = "PinIdentifier"
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: Life cycle
    
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
            notifyWithAlert(errorCase: .dataFetchFailed, message: "Internal error: The persisted pins could not be retrieved.")
        }
    }
    
    
    // MARK: Setup methods
    
    private func setUpFetchedResultsController() {
        // Set up the current map excerpt with pins from persistence
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            updatePins()
        } catch {
            notifyWithAlert(errorCase: .dataFetchFailed, message: error.localizedDescription)
        }
    }
    
    private func setUpMap() {
        if UserDefaults.standard.bool(forKey: UserDefaultKey.mapHasLaunchedKey) {
            
            // Retrieve persisted map settings
            fetchMapSettings()
            
        } else {
            
            // This is the first launch ever. Map settings will be persisted with the initial map launch at once in method mapView(_:regionDidChangeAnimated:).
            UserDefaults.standard.set(true, forKey: UserDefaultKey.mapHasLaunchedKey)
            UserDefaults.standard.synchronize()
        }
    }
}


// MARK: MKMapView Delegate
 
extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusePinIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusePinIdentifier)
            
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .red
        
        } else {
            
            pinView?.annotation = annotation
        
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let pin = view.annotation as? Pin {
            
            let photoAlbumVC = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            photoAlbumVC.pin = pin
            photoAlbumVC.dataController = dataController
            
            navigationController?.pushViewController(photoAlbumVC, animated: true)
            
        } else {
            notifyWithAlert(errorCase: .unknownMapAnnotation, message: "Internal error: The given map annotation could not be recognized.")
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Persist map view with each change
        saveMapSettings()
        
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        notifyWithAlert(errorCase: .networkOffline, message: error.localizedDescription)
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
        
        dataController.saveViewContext(viewController: self)
    }
}


// MARK: NSFetchedResultsController Delegate

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            notifyWithAlert(errorCase: .unknownMapAnnotation, message: "Internal error: Could not recognize the given map object as a pin.")
            return
        }
        
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
        case .delete:
            mapView.removeAnnotation(pin)
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
        default:
            notifyWithAlert(errorCase: .unsupportedOperation, message: "Internal error: Cases other than .insert, .delete and .update are not supported for pins.")
        }
    }
}
