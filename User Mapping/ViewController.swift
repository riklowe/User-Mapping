//
//  ViewController.swift
//  User Mapping
//
//  Created by Richard Lowe on 03/10/2024.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - WalkSelectionDelegate Protocol
protocol WalkSelectionDelegate: AnyObject {
    func didSelectWalk(_ walk: Walk)
}

// MARK: - ViewController Class
class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, WalkSelectionDelegate {

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!

    @IBOutlet weak var startStopButton: UIButton!

    @IBOutlet weak var showPreviousWalks: UIButton!

    @IBAction func showPreviousWalksTapped(_ sender: Any) {

        print("Navigation Controller: \(String(describing: navigationController))")

        if let walksVC = storyboard?.instantiateViewController(withIdentifier: "WalksViewController") as? WalksViewController {

            //let walks = WalksViewController
            walksVC.delegate = self
            walksVC.walks = walks
            navigationController?.pushViewController(walksVC, animated: true)
        }

    }

    @IBAction func showSettings(_ sender: Any) {
        if let settingsVC = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController {
            navigationController?.pushViewController(settingsVC, animated: true)
        }
    }

    // MARK: - Properties
    let locationManager = CLLocationManager()
    var routeLocations: [CLLocation] = []
    var totalDistance: CLLocationDistance = 0
    var startTime: Date?
    var isTracking = false

    // MARK: - Constants
    let metersPerSecondToMilesPerHour = 2.23694
    let metersToMiles = 0.000621371

    // Stored walks
    var walks: [Walk] = []

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the map view
        mapView.delegate = self
        mapView.showsUserLocation = true

        // Set up the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        // Load saved walks
        walks = DataManager.shared.loadWalks()
    }

    // MARK: - Actions
    @IBAction func startStopButtonTapped(_ sender: UIButton) {
        isTracking.toggle()
        if isTracking {
            // Start tracking
            routeLocations.removeAll()
            totalDistance = 0
            startTime = Date() // Set startTime here
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            locationManager.startUpdatingLocation()
            sender.setTitle("Stop", for: .normal)
        } else {
            // Stop tracking
            locationManager.stopUpdatingLocation()
            saveCurrentWalk()
            addStartAndEndAnnotations(for: routeLocations)
            sender.setTitle("Start", for: .normal)
        }
    }


    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle authorization status changes if needed
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // Permission granted
            break
        case .denied, .restricted:
            // Permission denied
            // Alert the user to enable location services
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let currentLocation = locations.last else { return }

        // Update the map region
        let region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)

        // Append the new location to the route
        routeLocations.append(currentLocation)

        // Update speed and direction metrics
        updateMetrics(with: currentLocation)

        // Draw the route on the map
        drawRoute()
    }

    // MARK: - Metrics Calculation
    func updateMetrics(with location: CLLocation) {
        // Ensure startTime is set
        if startTime == nil {
            startTime = location.timestamp
        }

        // Update duration
        let elapsedTime = location.timestamp.timeIntervalSince(startTime!)
        let durationText = formatDuration(elapsedTime)
        print("Elapsed Time: \(elapsedTime) seconds")
        print("Formatted Duration: \(durationText)")
        durationLabel.text = "Duration: \(durationText)"

        // Update speed in m/s
        let speedInMetersPerSecond = max(location.speed, 0)
        // Convert speed to mph
        let speedInMilesPerHour = speedInMetersPerSecond * metersPerSecondToMilesPerHour
        speedLabel.text = String(format: "Speed: %.2f mph", speedInMilesPerHour)

        // Update direction
        let direction = location.course >= 0 ? location.course : 0
        directionLabel.text = String(format: "Direction: %.2f°", direction)

        // Update average speed and distance
        if routeLocations.count > 1 {
            let lastLocation = routeLocations[routeLocations.count - 2]
            let distance = location.distance(from: lastLocation)
            totalDistance += distance

            let averageSpeedInMetersPerSecond = totalDistance / elapsedTime
            let averageSpeedInMilesPerHour = averageSpeedInMetersPerSecond * metersPerSecondToMilesPerHour
            avgSpeedLabel.text = String(format: "Avg Speed: %.2f mph", averageSpeedInMilesPerHour)

            // Update total distance
            let distanceInMiles = totalDistance * metersToMiles
            distanceLabel.text = String(format: "Distance: %.2f miles", distanceInMiles)

            // Optionally, calculate calories burned during live tracking
            if let weight = UserDefaults.standard.value(forKey: "userWeight") as? Double {
                let metValue = metValueForWalkingSpeed(averageSpeedInMilesPerHour)
                let durationInHours = elapsedTime / 3600
                let caloriesBurned = metValue * weight * durationInHours
                caloriesLabel.text = String(format: "Calories: %.0f kcal", caloriesBurned)
            }
        }
    }

    // MARK: - Map Rendering
    func drawRoute() {
        let coordinates = routeLocations.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)

        // Add new overlay
        mapView.addOverlay(polyline)
    }

    func addStartAndEndAnnotations(for locations: [CLLocation]) {
        guard let startLocation = locations.first, let endLocation = locations.last else { return }

        let startAnnotation = WalkAnnotation(
            coordinate: startLocation.coordinate,
            title: "Start",
            type: .start
        )

        let endAnnotation = WalkAnnotation(
            coordinate: endLocation.coordinate,
            title: "End",
            type: .end
        )

        mapView.addAnnotations([startAnnotation, endAnnotation])
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Exclude user location annotation
        if annotation is MKUserLocation {
            return nil
        }

        if let walkAnnotation = annotation as? WalkAnnotation {
            let identifier = "WalkAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: walkAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = walkAnnotation
            }

            // Customize the marker based on the type
            switch walkAnnotation.type {
            case .start:
                annotationView?.markerTintColor = .green
                annotationView?.glyphText = "S"
            case .end:
                annotationView?.markerTintColor = .red
                annotationView?.glyphText = "E"
            }

            return annotationView
        }

        return nil
    }

    // MARK: - Metrics Calculation
    func updateStatisticsLabels(with walk: Walk) {
        // Update total distance
        let distanceInMiles = walk.distance * metersToMiles
        let distanceText = String(format: "Distance: %.2f miles", distanceInMiles)
        distanceLabel.text = distanceText

        // Update average speed
        let averageSpeedInMetersPerSecond = walk.distance / walk.duration
        let averageSpeedInMilesPerHour = averageSpeedInMetersPerSecond * metersPerSecondToMilesPerHour
        let averageSpeedText = String(format: "Avg Speed: %.2f mph", averageSpeedInMilesPerHour)
        avgSpeedLabel.text = averageSpeedText

        // Update calories burned
        let caloriesText = String(format: "Calories: %.0f kcal", walk.caloriesBurned)
        caloriesLabel.text = caloriesText

        // Update duration
        let durationText = formatDuration(walk.duration)
        durationLabel.text = "Duration: \(durationText)"

        // Reset the current speed and direction labels
        speedLabel.text = "Speed: N/A"
        directionLabel.text = "Direction: N/A"
    }


    // MARK: - Walk Saving and Loading
    func saveCurrentWalk() {
        let codableLocations = routeLocations.map { CodableLocation(location: $0) }
        let walkDuration = Date().timeIntervalSince(startTime ?? Date())
        let walkDistance = totalDistance

        // Fetch user weight from UserDefaults
        guard let weight = UserDefaults.standard.value(forKey: "userWeight") as? Double else {
            showAlert(message: "Please set your weight in the Settings to calculate calories burned.")
            return
        }

        // Calculate average speed in meters per second
        let averageSpeed = walkDistance / walkDuration // m/s
        let speedInMilesPerHour = averageSpeed * metersPerSecondToMilesPerHour

        // Determine MET value based on average speed
        let metValue = metValueForWalkingSpeed(speedInMilesPerHour)

        // Calculate calories burned
        let durationInHours = walkDuration / 3600
        let caloriesBurned = metValue * weight * durationInHours

        // Create the Walk instance
        let walk = Walk(
            locations: codableLocations,
            date: Date(),
            distance: walkDistance,
            duration: walkDuration,
            caloriesBurned: caloriesBurned
        )

        // Append the new walk and save
        walks.append(walk)
        DataManager.shared.saveWalks(walks)
    }

    // MARK: - WalkSelectionDelegate
    func didSelectWalk(_ walk: Walk) {
        displayWalk(walk)
    }

    func metValueForWalkingSpeed(_ speedInMph: Double) -> Double {
        switch speedInMph {
        case ..<2.0:
            return 2.0 // Very slow walking
        case 2.0..<2.5:
            return 2.8 // Slow walking
        case 2.5..<3.0:
            return 3.0 // Moderate walking
        case 3.0..<3.5:
            return 3.5 // Brisk walking
        case 3.5..<4.0:
            return 4.3 // Very brisk walking
        default:
            return 5.0 // Fast walking
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Walk Tracking", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func displayWalk(_ walk: Walk) {
        let locations = walk.locations.map { $0.toCLLocation() }
        let coordinates = locations.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        // Add the saved walk overlay
        mapView.addOverlay(polyline)

        // Add start and end annotations
        addStartAndEndAnnotations(for: locations)

        // Adjust the map region to fit the walk
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20), animated: true)

        // **Update the statistics labels**
        updateStatisticsLabels(with: walk)
    }
}
