import SwiftUI
import MapKit

// This is used to prevent constant re-rendering of NavigateSessionView
struct NavigateSessionWrapper: View, Equatable {
    let route: MKRoute
    let endRoute: () -> Void
    
    var body: some View {
        NavigateSessionView(selectedRoute: route, endRoute: endRoute)
    }
    
    static func == (lhs: NavigateSessionWrapper, rhs: NavigateSessionWrapper) -> Bool {
        lhs.route == rhs.route
    }
}
