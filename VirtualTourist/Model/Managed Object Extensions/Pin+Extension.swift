//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 14.01.21.
//

import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
    
}
