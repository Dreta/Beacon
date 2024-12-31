import SwiftUI
import MapKit
import BottomSheet

struct InitiateNavigateView: View {
    @ObservedObject var model = RouteHelper()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var realTimeNavigator = RealTimeNavigator()
    
    @State private var currentRoute: MKRoute? = nil
    
    @State private var targetSearch: String = ""
    @State private var searchResults: [MKMapItemWrapped] = []
    @State private var selectedItem: MKMapItemWrapped?
    @FocusState private var searchFocused
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var bottomSheetPosition: BottomSheetPosition = .relativeBottom(0.2)
    
    var body: some View {
        if let coordinate = locationManager.realCoordinate {
            ZStack(alignment: .top) {
                // Replace the SwiftUI Map with our MKMapView wrapper
                MapViewWrapper(region: $region, selectedItem: $selectedItem, route: $currentRoute)
                    .ignoresSafeArea()
                    .onAppear {
                        updateRegion(with: coordinate)
                    }
                    .sheet(item: $selectedItem) { wrapped in
                            MapItemDetailsView(item: wrapped.item, selectedItem: $selectedItem) {
                                // 这里写点击“Walk”时真正的逻辑：
                                guard let userCoord = locationManager.realCoordinate else { return }
                                
                                let userMapItem = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
                                let destination = wrapped.item
                                
                                // 这里直接用 RouteHelper 来算路线
                                let request = MKDirections.Request()
                                request.source = userMapItem
                                request.destination = destination
                                request.transportType = .walking
                                
                                let directions = MKDirections(request: request)
                                directions.calculate { response, error in
                                    guard let route = response?.routes.first else { return }
                                    // 设置给我们的 @State:
                                    currentRoute = route
                                    
                                    // 同时把 route 给 realTimeNavigator
                                    realTimeNavigator.route = route
                                    
                                    // 收起 Sheet，或者保持打开都行
                                    selectedItem = nil
                                }
                            }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    }
                
                if realTimeNavigator.instruction != "No instruction" {
                        Text(realTimeNavigator.instruction)
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .padding(.top, 50)
                    
                        Spacer()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .bottomSheet(
                bottomSheetPosition: $bottomSheetPosition,
                switchablePositions: [.relativeBottom(0.2), .relativeTop(0.95)],
                headerContent: {
                    HStack {
                        // Search field and “clear” button
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .accessibilityHidden(true)
                            TextField("Search", text: self.$targetSearch, onEditingChanged: { begin in
                                // Move bottom sheet to top when search is focused
                                if begin {
                                    bottomSheetPosition = .relativeTop(0.95)
                                }
                            })
                            .focused($searchFocused)
                            .onTapGesture {
                                searchFocused = false
                            }
                            .onChange(of: targetSearch) {
                                // Perform search if needed
                                if targetSearch.count > 1 {
                                    performSearch(query: targetSearch)
                                } else {
                                    searchResults = []
                                }
                            }
                            .submitLabel(.search)

                            if targetSearch != "" {
                                Button(action: {
                                    targetSearch = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                                .accessibilityLabel("Clear")
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 5)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary))
                        
                        if targetSearch != "" || searchResults.count > 0 || searchFocused {
                            Button("Cancel") {
                                targetSearch = ""
                                searchResults = []
                                searchFocused = false
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 5)
                        }
                    }
                    .padding([.horizontal, .bottom])
                    .animation(.default, value: searchFocused)
                }
            ) {
                if targetSearch != "" || searchResults.count > 0 || searchFocused {
                    Divider()
                    VStack {
                        // Show search results
                        ForEach($searchResults) { $item in
                            VStack {
                                Button(action: {
                                    selectedItem = item
                                    bottomSheetPosition = .relativeBottom(0.2)
                                    searchFocused = false
                                    searchResults = []
                                    targetSearch = ""
                                }) {
                                    MapItemView(
                                        item: item.item,
                                        location: coordinate,
                                        searchVerb: targetSearch
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                if searchResults.last!.item.identifier != item.item.identifier {
                                    Divider()
                                }
                            }
                        }
                    }
                } else {
                    // TODO
                    VStack(alignment: .leading) {
                        Text("Recent Searches")
                            .font(.caption)
                        Text("Routes")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity) // Changed from .greatestFiniteMagnitude to .infinity for better behavior
                    .padding()
                }
            }
            .enableAppleScrollBehavior()
            .background(.ultraThickMaterial)
            // **Step 2: Observe changes to `selectedItem` and update the region accordingly**
            .onReceive(locationManager.$rawLocation) { loc in
                guard let loc = loc else { return }
                // 把用户位置传给 realTimeNavigator，更新下一步提示
                realTimeNavigator.updateLocation(loc)
            }
            .onChange(of: selectedItem) { newValue in
                if let item = newValue {
                    // Update the map region to center on the selected POI's coordinate
                    updateRegion(with: item.item.placemark.coordinate)
                }
            }
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
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
    
    private func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems.map(MKMapItemWrapped.init)
            }
        }
    }
}

#Preview {
    InitiateNavigateView()
}

struct MKMapItemWrapped: Identifiable, Equatable {
    let id = UUID()
    let item: MKMapItem
}

// MARK: - MKMapView Wrapper

struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedItem: MKMapItemWrapped?
    
    @Binding var route: MKRoute?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, selectedItem: $selectedItem)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.selectableMapFeatures = [.pointsOfInterest]
        mapView.showsUserTrackingButton = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 1) Keep the region updated
        uiView.setRegion(region, animated: true)
        
        // 2) Synchronize selection from SwiftUI -> MapView
        //    If SwiftUI’s selectedItem is nil, or differs from the last selection,
        //    then we deselect all annotations.
        let lastSelected = context.coordinator.lastSelectedItem
        if selectedItem?.id != lastSelected?.id {
            // Deselect everything
            uiView.selectedAnnotations.forEach {
                uiView.deselectAnnotation($0, animated: false)
            }
            // Update the lastSelectedItem in the Coordinator to match SwiftUI’s new selection
            context.coordinator.lastSelectedItem = selectedItem
        }
        
        uiView.removeOverlays(uiView.overlays)
        if let route = route {
            uiView.addOverlay(route.polyline, level: .aboveRoads)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        
        // We store the SwiftUI binding so we can set it when the user taps a POI
        @Binding var selectedItem: MKMapItemWrapped?
        
        // We also store our own “last selected item” so that `updateUIView`
        // can detect whether SwiftUI’s selectedItem has changed.
        var lastSelectedItem: MKMapItemWrapped? = nil

        init(parent: MapViewWrapper, selectedItem: Binding<MKMapItemWrapped?>) {
            self.parent = parent
            self._selectedItem = selectedItem
        }
        
        // Called by MKMapView when the user taps a feature annotation (POI)
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            guard let feature = annotation as? MKMapFeatureAnnotation else { return }
            
            let featureName = feature.title ?? ""
            
            // Use a local search to find deeper metadata
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = featureName
            request.region = mapView.region
            
            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                guard let self = self else { return }
                
                if let response = response,
                   let mapItem = response.mapItems.first {
                    let wrapped = MKMapItemWrapped(item: mapItem)
                    self.selectedItem = wrapped
                    self.lastSelectedItem = wrapped
                } else {
                    // Fall back to a minimal item using the tapped annotation’s coordinate
                    let fallback = MKMapItem(placemark: MKPlacemark(coordinate: annotation.coordinate))
                    fallback.name = featureName
                    
                    let wrapped = MKMapItemWrapped(item: fallback)
                    self.selectedItem = wrapped
                    self.lastSelectedItem = wrapped
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
    }
}
