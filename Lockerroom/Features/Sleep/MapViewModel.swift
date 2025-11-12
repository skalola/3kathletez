//
//  MapViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import MapKit
import Combine

enum TransportType: String, CaseIterable, Hashable {
    case drive = "Drive"
    case walk = "Walk"
    case transit = "Transit"
    
    var mapKitType: MKDirectionsTransportType {
        switch self {
        case .drive:
            return .automobile
        case .walk:
            return .walking
        case .transit:
            return .transit
        }
    }
}

@MainActor
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedLocation: MKMapItem?
    @Published var travelTime: TimeInterval?
    @Published var travelTimeMessage: String = ""
    @Published var transportType: TransportType = .drive
    
    // --- NEW ---
    @Published var destinationName: String = "" // To store the location name
    
    private var locationManager: CLLocationManager?
    @Published private(set) var userLocation: CLLocation?
    
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newText in
                if !newText.isEmpty {
                    self?.performSearch(query: newText)
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            print("Location services are disabled.")
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Location is restricted.")
        case .denied:
            print("Location permission denied.")
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                userLocation = location
            }
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            manager.stopUpdatingLocation()
        }
    }
    
    func performSearch(query: String) {
        guard let userLocation = userLocation else {
            print("User location not available for search.")
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self, let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            self.searchResults = response.mapItems
        }
    }
    
    func calculateTravelTime(to destination: MKMapItem) {
        guard let userLocation = userLocation else {
            travelTimeMessage = "Could not get user location."
            return
        }
        
        self.selectedLocation = destination
        self.travelTimeMessage = "Calculating..."
        self.destinationName = destination.name ?? "Selected Location" // <-- NEW
        
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = destination
        request.transportType = transportType.mapKitType
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            
            guard let self = self, let route = response?.routes.first else {
                self?.travelTimeMessage = "Could not calculate travel time."
                self?.travelTime = nil
                return
            }
            
            self.travelTime = route.expectedTravelTime
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            self.travelTimeMessage = formatter.string(from: route.expectedTravelTime) ?? "..."
        }
    }
}
