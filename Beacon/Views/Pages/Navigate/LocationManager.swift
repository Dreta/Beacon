import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    @Published var realCoordinate: CLLocationCoordinate2D?
    @Published var rawLocation: CLLocation?
    
    override init() {
        super.init()
        configureLocationManager()
    }
    
    private func configureLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if checkPermissions() {
            startUpdatingLocation()
        }
    }
    
    func checkPermissions() -> Bool {
        // FIXME
        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                return manager.authorizationStatus == .authorizedWhenInUse
            case .restricted, .denied:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        if currentLocation.horizontalAccuracy > 0 {
            rawLocation = currentLocation
            realCoordinate = properToChina(currentLocation.coordinate)
        }
    }
    
    // MARK: - Chinese government coordinate system converter - screw those people
    let pi = 3.1415926535897932384626
    let a = 6378245.0
    let ee = 0.00669342162296594323

    func outOfChina(_ coord: CLLocationCoordinate2D) -> Bool {
        let lng = coord.longitude
        let lat = coord.latitude
        return (lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271)
    }

    func chinaToProper(_ coord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = coord.latitude
        let lng = coord.longitude
        
        if outOfChina(coord) {
            return coord
        } else {
            let dLat = transformLat(lng: lng - 105.0, lat: lat - 35.0)
            let dLng = transformLng(lng: lng - 105.0, lat: lat - 35.0)
            let radLat = lat / 180.0 * pi
            var magic = sin(radLat)
            magic = 1 - ee * magic * magic
            let sqrtMagic = sqrt(magic)
            let mgLat = lat + (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
            let mgLng = lng + (dLng * 180.0) / (a / sqrtMagic * cos(radLat) * pi)
            return CLLocationCoordinate2D(latitude: lat * 2 - mgLat, longitude: lng * 2 - mgLng)
        }
    }

    func properToChina(_ coord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = coord.latitude
        let lng = coord.longitude
        
        if outOfChina(coord) {
            return coord
        } else {
            let dLat = transformLat(lng: lng - 105.0, lat: lat - 35.0)
            let dLng = transformLng(lng: lng - 105.0, lat: lat - 35.0)
            let radLat = lat / 180.0 * pi
            var magic = sin(radLat)
            magic = 1 - ee * magic * magic
            let sqrtMagic = sqrt(magic)
            let mgLat = lat + (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
            let mgLng = lng + (dLng * 180.0) / (a / sqrtMagic * cos(radLat) * pi)
            return CLLocationCoordinate2D(latitude: mgLat, longitude: mgLng)
        }
    }

    func transformLat(lng: Double, lat: Double) -> Double {
        var ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * sqrt(abs(lng))
        ret += (20.0 * sin(6.0 * lng * pi) + 20.0 * sin(2.0 * lng * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(lat * pi) + 40.0 * sin(lat / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(lat / 12.0 * pi) + 320 * sin(lat * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    func transformLng(lng: Double, lat: Double) -> Double {
        var ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * sqrt(abs(lng))
        ret += (20.0 * sin(6.0 * lng * pi) + 20.0 * sin(2.0 * lng * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(lng * pi) + 40.0 * sin(lng / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(lng / 12.0 * pi) + 300.0 * sin(lng / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
}

