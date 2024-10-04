//
//  WalkAnnotation.swift
//  User Mapping
//
//  Created by Richard Lowe on 04/10/2024.
//

import MapKit

enum AnnotationType {
    case start
    case end
}

class WalkAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var type: AnnotationType

    init(coordinate: CLLocationCoordinate2D, title: String?, type: AnnotationType) {
        self.coordinate = coordinate
        self.title = title
        self.type = type
    }
}
