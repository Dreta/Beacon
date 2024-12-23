import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    let manager = CLLocationManager()
    @Published var location = CLLocationCoordinate2D()
    
    
    var realTimeNavigator: RealTimeNavigator?
    
    override init () {
        super.init()
        manager.delegate = self

        //定位方式
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //权限
        manager.requestWhenInUseAuthorization()
    }
    
//    func checkLocationAuthorizationStatue() {
//        switch CLLocationManager.authorizationStatus() {
//        case .notDetermined:
//            print("Not Authorized")
//        case .authorizedAlways, .authorizedWhenInUse:
//            print("Authorized")
//        case .restricted:
//            print("Restricted")
//        case .denied:
//            print("Denied")
//        @unknown default:
//            print("Unknown Status")
//            
//        }
//    }
    
    func updateLocation() {
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        if currentLocation.horizontalAccuracy > 0 {
            location = currentLocation.coordinate
            // 调用实时导航的 updateLocation
            realTimeNavigator?.updateLocation(currentLocation)
        }
    }
}

