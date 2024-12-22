import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    let manager = CLLocationManager()
    @Published var location = CLLocationCoordinate2D()
    
    override init () {
        super.init()
        manager.delegate = self

        //定位方式
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //权限
        manager.requestWhenInUseAuthorization()
    }
    
    func updateLocation() {
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations[locations.count - 1]
        if currentLocation.horizontalAccuracy > 0 {
            location.latitude = currentLocation.coordinate.latitude
            location.longitude = currentLocation.coordinate.longitude
        }
    }
}

