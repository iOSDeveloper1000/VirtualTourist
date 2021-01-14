//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 13.01.21.
//

import UIKit
import MapKit
import CoreData


class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    var longPressRecognizer: UILongPressGestureRecognizer!
 
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(recognizeTouchAndHoldGestureOnMap(_:)))
        longPressRecognizer.minimumPressDuration = 2.0
        
        mapView.delegate = self
        mapView.gestureRecognizers = [longPressRecognizer]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    // MARK: MapView Delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reusePinId = "PinIdentifier"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusePinId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusePinId)
            
            pinView?.animatesDrop = true
            pinView?.canShowCallout = true
            pinView?.pinTintColor = MKPinAnnotationView.purplePinColor()
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        } else {
            
            pinView?.annotation = annotation
        
        }
        
        print("Pin - Latitude: \(annotation.coordinate.latitude) - Longitude: \(annotation.coordinate.longitude)")
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // TODO: callout to next View Controller
    }
    
    // MARK: Navigation in Storyboard
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoAlbumViewController {
            vc.dataController = dataController
        }
    }
    
}

extension TravelLocationsViewController {
    @objc private func recognizeTouchAndHoldGestureOnMap(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.ended else {
            return
        }
        
        let pointAnnotation = MKPointAnnotation()
        
        let location = sender.location(in: mapView)
        
        pointAnnotation.coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        mapView.addAnnotation(pointAnnotation)
    }
}
