import SwiftUI
import MapKit

struct NavigateSessionView: View {
    @ObservedObject var locationManager: LocationManager = LocationManager()
    @ObservedObject var realTimeNavigator: RealTimeNavigator
    
    init(selectedRoute: MKRoute) {
        realTimeNavigator = RealTimeNavigator()
        realTimeNavigator.route = selectedRoute
    }
    
    var body: some View {
        Map()
            .onReceive(locationManager.$rawLocation) { loc in
                guard let loc = loc else { return }
                realTimeNavigator.updateLocation(loc)
            }
            .overlay {
                Text(realTimeNavigator.instruction)
            }
    }
}
