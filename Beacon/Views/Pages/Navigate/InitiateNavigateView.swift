import SwiftUI
import MapKit

struct InitiateNavigateView: View {
    @ObservedObject var model = RouteHelper()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var realTimeNavigator = RealTimeNavigator()
    
    @State private var targetSearch: String = ""
    
    @State private var mapPosition: MapCameraPosition
    
    init() {
        _mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    var body: some View {
        if let coordinate = locationManager.realCoordinate {
            ZStack {
                Map(position: $mapPosition) {
                    UserAnnotation()
                }
                    .onAppear {
                        updateRegion(with: coordinate)
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                VStack {
                    VStack {
                        TextField("Where to...", text: $targetSearch)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
                .background(.ultraThickMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack {
                Text("To use Navigate, please allow location access in Settings.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                Button("Open Settings") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    private func updateRegion(with coordinate: CLLocationCoordinate2D) {
        mapPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
}

struct MapMarkerData: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    InitiateNavigateView()
}
