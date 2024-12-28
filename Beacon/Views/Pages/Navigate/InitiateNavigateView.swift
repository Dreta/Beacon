import SwiftUI
import MapKit
import BottomSheet

struct InitiateNavigateView: View {
    @ObservedObject var model = RouteHelper()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var realTimeNavigator = RealTimeNavigator()
    
    @State private var targetSearch: String = ""
    
    @State private var mapPosition: MapCameraPosition
    @State private var bottomSheetPosition: BottomSheetPosition = .relativeBottom(0.2)
    
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
                .ignoresSafeArea(.keyboard)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .bottomSheet(bottomSheetPosition: $bottomSheetPosition, switchablePositions: [.relativeBottom(0.2), .relativeTop(0.95)], headerContent: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: self.$targetSearch, onEditingChanged: { begin in
                        if begin {
                            bottomSheetPosition = .relativeTop(0.95)
                        }
                    })
                }
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.vertical, 8)
                .padding(.horizontal, 5)
                .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary))
                .padding([.horizontal, .bottom])
            }) {
                VStack(alignment: .leading) {
                    Text("Recent Searches")
                        .font(.caption)
                    Text("Routes")
                        .font(.caption2)
                }
                .frame(width: .greatestFiniteMagnitude)
                .padding()
            }
            .enableAppleScrollBehavior()
            .background(.ultraThickMaterial)
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

#Preview {
    InitiateNavigateView()
}
