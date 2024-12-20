import MapKit

class RouteHelper: NSObject,MKLocalSearchCompleterDelegate,ObservableObject {
    
    @Published var routeStr = ""
    let completer = MKLocalSearchCompleter()
    let distanceFormatter = MKDistanceFormatter()
    
    
    func route(){
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 39.983603, longitude: 116.411707), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 39.913414, longitude: 116.197072), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile //先试试机动车
        
        let directions = MKDirections(request: request)
        
        var rs = "Result:\n"
        directions.calculate { [unowned self] response, error in
            guard let mapRoute = response?.routes.first else {
                print("error:\(String(describing: error))")
                return
            }
            rs = rs + "Distance:\(mapRoute.distance)"+"m"+"\n"
            rs = rs + "ExpectedTravelTime:\(mapRoute.expectedTravelTime)"+"s"+"\n"
            
            var index = 0
            for step in mapRoute.steps {
                index+=1
                rs = rs + "\(index): \(step.notice ?? step.instructions)"+"\n"
                rs = rs + distanceFormatter.string(fromDistance: step.distance)+"\n"
            }
            print(rs)
            self.routeStr = rs
        }
    }
}


