import SwiftUI
import MapKit
import BottomSheet

struct InitiateNavigateView: View {
    @ObservedObject var locationManager = LocationManager()
    
    @State private var targetSearch: String = ""
    @State private var searchResults: [MKMapItemWrapped] = []
    @State private var selectedItem: MKMapItemWrapped?
    
    @State private var toNavigateItem: MKMapItemWrapped?
    @State private var routesToShow: [MKRoute] = []
    @State private var selectedRoute: MKRoute?
    
    @FocusState private var searchFocused
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var bottomSheetPosition: BottomSheetPosition = .relativeBottom(0.2)
    
    var body: some View {
        if let selectedRoute = selectedRoute {
            NavigateSessionWrapper(route: selectedRoute)
                .id(selectedRoute)
        } else if let coordinate = locationManager.realCoordinate {
            ZStack(alignment: .top) {
                MapViewWrapper(region: $region, selectedItem: $selectedItem, routesToShow: $routesToShow, toNavigateItem: $toNavigateItem)
                    .ignoresSafeArea()
                    .onAppear {
                        updateRegion(with: coordinate)
                    }
                    .sheet(item: $selectedItem) { wrapped in
                        MapItemDetailsView(
                            start: coordinate,
                            item: wrapped.item,
                            selectedItem: $selectedItem
                        ) {
                            toNavigateItem = wrapped
                            selectedItem = nil
                        }
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents([.medium])
                    }
                    .sheet(item: $toNavigateItem) { wrapped in
                        if let start = locationManager.realCoordinate {
                            AvailableRoutesView(start: start, end: wrapped.item, routes: $routesToShow, toNavigateItem: $toNavigateItem, region: $region, selectedRoute: $selectedRoute)
                                .presentationBackgroundInteraction(.enabled)
                                .presentationDetents([.medium, .large])
                                .presentationDragIndicator(.visible)
                                .onDisappear {
                                    routesToShow = []
                                }
                        }
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
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .enableAppleScrollBehavior()
            .background(.ultraThickMaterial)
            .onChange(of: selectedItem) {
                if let item = selectedItem {
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
    
    static func == (lhs: MKMapItemWrapped, rhs: MKMapItemWrapped) -> Bool {
        return lhs.item.identifier == rhs.item.identifier
    }
}

// MARK: - MKMapView Wrapper

struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedItem: MKMapItemWrapped?
    @Binding var routesToShow: [MKRoute]
    @Binding var toNavigateItem: MKMapItemWrapped?
    
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
        //    If toNavigateItem is not nil, select it and override any other selections
        //    Else if selectedItem is not nil and differs from the last selection, select it
        //    Else, deselect all annotations and remove programmatic annotations
        
        if let navigateItem = toNavigateItem {
            // Override selection with toNavigateItem
            selectAnnotation(for: navigateItem, in: uiView, context: context)
        } else if let selected = selectedItem, selected.id != context.coordinator.lastSelectedItem?.id {
            // Select the new selectedItem
            selectAnnotation(for: selected, in: uiView, context: context)
        } else if selectedItem == nil && toNavigateItem == nil {
            // Deselect all annotations
            uiView.selectedAnnotations.forEach {
                uiView.deselectAnnotation($0, animated: false)
            }
            
            // Remove Programmatically Added Annotations
            for annotation in context.coordinator.programmaticAnnotations {
                uiView.removeAnnotation(annotation)
            }
            context.coordinator.programmaticAnnotations.removeAll()
            
            // Reset Last Selected Item
            context.coordinator.lastSelectedItem = nil
        }
        
        // 3) Remove existing overlays
        uiView.removeOverlays(uiView.overlays)
        
        // 4) Add new overlays (routes)
        for route in routesToShow {
            uiView.addOverlay(route.polyline)
        }
        
        // 5) Set the firstPolyline in the Coordinator for rendering purposes
        if let firstRoute = routesToShow.first {
            context.coordinator.firstPolyline = firstRoute.polyline
        } else {
            context.coordinator.firstPolyline = nil
        }
    }
    
    /// Helper function to select an annotation based on MKMapItemWrapped
    private func selectAnnotation(for mapItemWrapped: MKMapItemWrapped, in mapView: MKMapView, context: Context) {
        // **Remove Existing Programmatically Added Annotations**
        for annotation in context.coordinator.programmaticAnnotations {
            mapView.removeAnnotation(annotation)
        }
        context.coordinator.programmaticAnnotations.removeAll()
        
        // **Deselect All Existing Annotations**
        mapView.selectedAnnotations.forEach {
            mapView.deselectAnnotation($0, animated: false)
        }
        
        // **Find Matching Annotation Among Existing Annotations**
        if let matchingAnnotation = mapView.annotations.first(where: { annotation in
            let placemark = mapItemWrapped.item.placemark
            return annotation.coordinate.latitude == placemark.coordinate.latitude &&
            annotation.coordinate.longitude == placemark.coordinate.longitude &&
            annotation.title == placemark.name
        }) {
            // **Select the Matching Annotation**
            mapView.selectAnnotation(matchingAnnotation, animated: true)
            context.coordinator.lastSelectedItem = mapItemWrapped
        } else {
            // **Add a New Programmatic Annotation**
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItemWrapped.item.placemark.coordinate
            annotation.title = mapItemWrapped.item.name
            mapView.addAnnotation(annotation)
            mapView.selectAnnotation(annotation, animated: true)
            
            // **Track the Added Annotation**
            context.coordinator.programmaticAnnotations.append(annotation)
            context.coordinator.lastSelectedItem = mapItemWrapped
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        
        // Binding to selectedItem
        @Binding var selectedItem: MKMapItemWrapped?
        
        // Tracks the last selected item to detect changes
        var lastSelectedItem: MKMapItemWrapped? = nil
        
        // **Tracks programmatically added annotations**
        var programmaticAnnotations: [MKPointAnnotation] = []
        
        // Tracks the first polyline for styling
        var firstPolyline: MKPolyline?
        
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
        
        // MARK: - Renderer for Overlays
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            if let first = firstPolyline, polyline === first {
                // First MKRoute: Full Blue Color
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
            } else {
                // Other MKRoutes: Faded Blue Color
                renderer.strokeColor = .systemBlue.withAlphaComponent(0.5)
                renderer.lineWidth = 8
            }
            
            return renderer
        }
    }
}
