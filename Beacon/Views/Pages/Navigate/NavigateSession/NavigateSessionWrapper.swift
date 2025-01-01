import SwiftUI
import MapKit

// This is used to prevent constant re-rendering of NavigateSessionView
struct NavigateSessionWrapper: View, Equatable {
    let route: MKRoute
    
    var body: some View {
        NavigateSessionView(selectedRoute: route)
    }
}
