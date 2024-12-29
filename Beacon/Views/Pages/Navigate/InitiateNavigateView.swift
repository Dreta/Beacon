import SwiftUI
import MapKit
import BottomSheet

struct InitiateNavigateView: View {
    @ObservedObject var model = RouteHelper()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var realTimeNavigator = RealTimeNavigator()
    
    @State private var targetSearch: String = ""
    @State private var searchResults: [MKMapItemWrapped] = []
    @FocusState private var searchFocused
    
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
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .accessibilityHidden(true)
                        TextField("Search", text: self.$targetSearch, onEditingChanged: { begin in
                            // Automatically move the bottom sheet to the top when search is focused
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
                            if targetSearch.count > 2 {
                                performSearch(query: targetSearch)
                            } else {
                                searchResults = []
                            }
                        }
                        .submitLabel(.search)

                        // Clear Button
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
            }) {
                if targetSearch != "" || searchResults.count > 0 || searchFocused {
                    Divider()
                    VStack {
                        // Show search results
                        ForEach($searchResults) { $item in
                            VStack {
                                MapItemView(
                                    item: item.item,
                                    location: coordinate,
                                    searchVerb: targetSearch
                                )
                                // Add a divider between each search result
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
                    .frame(width: .greatestFiniteMagnitude)
                    .padding()
                }
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
    
    private func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        guard let region = mapPosition.region else { return }
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems.map(MKMapItemWrapped.init)
            }
        }
    }
}

struct MKMapItemWrapped: Identifiable {
    let id = UUID()
    let item: MKMapItem
}

struct MapItemView: View {
    var item: MKMapItem
    var location: CLLocationCoordinate2D
    var searchVerb: String
    
    var body: some View {
        HStack {
            Image(systemName: MapItemView.icon(for: item.pointOfInterestCategory))
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(8)
                .foregroundColor(.white)
                .accessibilityHidden(true)
                .background(Circle().fill(MapItemView.color(for: item.pointOfInterestCategory)))
            VStack(alignment: .leading) {
                Text(LocalizedStringKey((item.name ?? "").replacing(searchVerb, with: "**\(searchVerb)**")))
                    .font(.headline)
                    .fontWeight(.regular)
                Text(
                    "\(MapItemView.formattedDistanceBetween(location, item.placemark.coordinate)) · \(item.placemark.thoroughfare ?? "")"
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }.padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
    
    static func formattedDistanceBetween(_ coordinate1: CLLocationCoordinate2D,
                                         _ coordinate2: CLLocationCoordinate2D) -> String {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        
        let distanceInMeters = location1.distance(from: location2) // Distance in meters
        let locale = Locale.current
        let usesMetric = locale.measurementSystem == .metric
        
        if usesMetric {
            let distanceInKilometers = distanceInMeters / 1000
            return String(format: "%.2f km", distanceInKilometers)
        } else {
            let distanceInMiles = distanceInMeters / 1609.34
            return String(format: "%.2f mi", distanceInMiles)
        }
    }
    
    static func color(for category: MKPointOfInterestCategory?) -> Color {
        let categoryColors: [MKPointOfInterestCategory: Color] = [
            // Arts and Culture
            .museum: .purple,
            .musicVenue: .orange,
            .theater: .pink,
            
            // Education
            .library: .green,
            .planetarium: .yellow,
            .school: .indigo,
            .university: .teal,
            
            // Entertainment
            .movieTheater: .red,
            .nightlife: .purple,
            
            // Health and Safety
            .fireStation: .red,
            .hospital: .pink,
            .pharmacy: .green,
            .police: .blue,
            
            // Historical and Cultural Landmarks
            .castle: .brown,
            .fortress: .gray,
            .landmark: .yellow,
            .nationalMonument: .orange,
            
            // Food and Drink
            .bakery: .orange,
            .brewery: .brown,
            .cafe: .yellow,
            .distillery: .blue,
            .foodMarket: .green,
            .restaurant: .red,
            .winery: .purple,
            
            // Personal Services
            .animalService: .brown,
            .atm: .blue,
            .automotiveRepair: .gray,
            .bank: .indigo,
            .beauty: .pink,
            .evCharger: .green,
            .fitnessCenter: .orange,
            .laundry: .blue,
            .mailbox: .red,
            .postOffice: .blue,
            .restroom: .gray,
            .spa: .purple,
            .store: .green,
            
            // Parks and Recreation
            .amusementPark: .yellow,
            .aquarium: .blue,
            .beach: .yellow,
            .campground: .brown,
            .fairground: .purple,
            .marina: .blue,
            .nationalPark: .green,
            .park: .green,
            .rvPark: .gray,
            .zoo: .brown,
            
            // Sports
            .baseball: .red,
            .basketball: .orange,
            .bowling: .red,
            .goKart: .blue,
            .golf: .green,
            .hiking: .brown,
            .miniGolf: .green,
            .rockClimbing: .brown,
            .skatePark: .gray,
            .skating: .blue,
            .skiing: .white,
            .soccer: .green,
            .stadium: .gray,
            .tennis: .yellow,
            .volleyball: .orange,
            
            // Travel
            .airport: .blue,
            .carRental: .blue,
            .conventionCenter: .gray,
            .gasStation: .red,
            .hotel: .purple,
            .parking: .gray,
            .publicTransport: .green,
            
            // Water Sports
            .fishing: .blue,
            .kayaking: .teal,
            .surfing: .cyan,
            .swimming: .blue
        ]
        if let category = category {
            
            return categoryColors[category] ?? .blue
        }
        return .blue
    }
    
    static func icon(for category: MKPointOfInterestCategory?) -> String {
        let categoryIcons: [MKPointOfInterestCategory: String] = [
            // Arts and Culture
            .museum: "building.columns",
            .musicVenue: "music.note.house",
            .theater: "theatermasks",
            
            // Education
            .library: "books.vertical",
            .planetarium: "sparkles",
            .school: "graduationcap",
            .university: "book",
            
            // Entertainment
            .movieTheater: "film",
            .nightlife: "sparkles",
            
            // Health and Safety
            .fireStation: "flame",
            .hospital: "cross.case",
            .pharmacy: "pills",
            .police: "shield",
            
            // Historical and Cultural Landmarks
            .castle: "castle",
            .fortress: "shield.lefthalf.filled",
            .landmark: "star.circle",
            .nationalMonument: "mappin",
            
            // Food and Drink
            .bakery: "fork.knife",
            .brewery: "leaf",
            .cafe: "cup.and.saucer",
            .distillery: "wineglass",
            .foodMarket: "cart",
            .restaurant: "fork.knife",
            .winery: "wineglass",
            
            // Personal Services
            .animalService: "pawprint",
            .atm: "creditcard",
            .automotiveRepair: "wrench",
            .bank: "building.columns",
            .beauty: "scissors",
            .evCharger: "bolt.car",
            .fitnessCenter: "dumbbell",
            .laundry: "washer",
            .mailbox: "envelope",
            .postOffice: "building.columns",
            .restroom: "toilet",
            .spa: "leaf",
            .store: "bag",
            
            // Parks and Recreation
            .amusementPark: "ferriswheel",
            .aquarium: "fish",
            .beach: "sun.max",
            .campground: "tent",
            .fairground: "carousel",
            .marina: "sailboat",
            .nationalPark: "tree",
            .park: "leaf",
            .rvPark: "car",
            .zoo: "pawprint",
            
            // Sports
            .baseball: "sportscourt",
            .basketball: "sportscourt",
            .bowling: "bowling.ball",
            .goKart: "car",
            .golf: "flag",
            .hiking: "figure.walk",
            .miniGolf: "flag",
            .rockClimbing: "figure.climbing",
            .skatePark: "skateboard",
            .skating: "figure.skating",
            .skiing: "figure.skiing.downhill",
            .soccer: "soccerball",
            .stadium: "building",
            .tennis: "tennisball",
            .volleyball: "volleyball",
            
            // Travel
            .airport: "airplane",
            .carRental: "car",
            .conventionCenter: "building.2",
            .gasStation: "fuelpump",
            .hotel: "bed.double",
            .parking: "parkingsign.circle",
            .publicTransport: "bus",
            
            // Water Sports
            .fishing: "fish",
            .kayaking: "canoe",
            .surfing: "waveform",
            .swimming: "figure.swimming"
        ]
        if let category = category {
            return categoryIcons[category] ?? "location.fill"
        }
        return "location.fill"
    }
}

#Preview {
    InitiateNavigateView()
}
