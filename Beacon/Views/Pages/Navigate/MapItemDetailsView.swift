import SwiftUI
import MapKit

struct MapItemDetailsView: View {
    var item: MKMapItem
    
    var body: some View {
        VStack {
            Text(item.name ?? "")
                .font(.title)
        }
    }
}
