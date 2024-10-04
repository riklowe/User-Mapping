//
//  CodeableLocation.swift
//  User Mapping
//
//  Created by Richard Lowe on 03/10/2024.
//

import Foundation
import CoreLocation

struct CodableLocation: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
   // let caloriesBurned: Double // New property

    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.timestamp = location.timestamp
        //self.caloriesBurned =
    }

    func toCLLocation() -> CLLocation {
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: altitude,
                          horizontalAccuracy: kCLLocationAccuracyBest,
                          verticalAccuracy: kCLLocationAccuracyBest,
                          timestamp: timestamp)
    }
}
