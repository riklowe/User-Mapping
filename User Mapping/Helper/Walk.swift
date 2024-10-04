//
//  Utils.swift
//  User Mapping
//
//  Created by Richard Lowe on 03/10/2024.
//

import Foundation
import CoreLocation

struct Walk: Codable {
    let locations: [CodableLocation]
    let date: Date
    let distance: CLLocationDistance
    let duration: TimeInterval
    let caloriesBurned: Double // Add this property
}
