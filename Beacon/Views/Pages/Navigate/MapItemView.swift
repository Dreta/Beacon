import MapKit
import SwiftUI

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
    
    static func name(for category: MKPointOfInterestCategory?) -> String {
        let categoryNames: [MKPointOfInterestCategory: String] = [
            // Arts and Culture
            .museum: "Museum",
            .musicVenue: "Music Venue",
            .theater: "Theater",
            
            // Education
            .library: "Library",
            .planetarium: "Planetarium",
            .school: "School",
            .university: "University",
            
            // Entertainment
            .movieTheater: "Movie Theater",
            .nightlife: "Nightlife",
            
            // Health and Safety
            .fireStation: "Fire Station",
            .hospital: "Hospital",
            .pharmacy: "Pharmacy",
            .police: "Police Station",
            
            // Historical and Cultural Landmarks
            .castle: "Castle",
            .fortress: "Fortress",
            .landmark: "Landmark",
            .nationalMonument: "National Monument",
            
            // Food and Drink
            .bakery: "Bakery",
            .brewery: "Brewery",
            .cafe: "Cafe",
            .distillery: "Distillery",
            .foodMarket: "Food Market",
            .restaurant: "Restaurant",
            .winery: "Winery",
            
            // Personal Services
            .animalService: "Animal Service",
            .atm: "ATM",
            .automotiveRepair: "Automotive Repair",
            .bank: "Bank",
            .beauty: "Beauty Service",
            .evCharger: "EV Charger",
            .fitnessCenter: "Fitness Center",
            .laundry: "Laundry Service",
            .mailbox: "Mailbox",
            .postOffice: "Post Office",
            .restroom: "Restroom",
            .spa: "Spa",
            .store: "Store",
            
            // Parks and Recreation
            .amusementPark: "Amusement Park",
            .aquarium: "Aquarium",
            .beach: "Beach",
            .campground: "Campground",
            .fairground: "Fairground",
            .marina: "Marina",
            .nationalPark: "National Park",
            .park: "Park",
            .rvPark: "RV Park",
            .zoo: "Zoo",
            
            // Sports
            .baseball: "Baseball Field",
            .basketball: "Basketball Court",
            .bowling: "Bowling Alley",
            .goKart: "Go-Kart Track",
            .golf: "Golf Course",
            .hiking: "Hiking Trail",
            .miniGolf: "Mini Golf",
            .rockClimbing: "Rock Climbing Facility",
            .skatePark: "Skate Park",
            .skating: "Skating Rink",
            .skiing: "Skiing Area",
            .soccer: "Soccer Field",
            .stadium: "Stadium",
            .tennis: "Tennis Court",
            .volleyball: "Volleyball Court",
            
            // Travel
            .airport: "Airport",
            .carRental: "Car Rental",
            .conventionCenter: "Convention Center",
            .gasStation: "Gas Station",
            .hotel: "Hotel",
            .parking: "Parking Area",
            .publicTransport: "Public Transport",
            
            // Water Sports
            .fishing: "Fishing Area",
            .kayaking: "Kayaking Area",
            .surfing: "Surfing Area",
            .swimming: "Swimming Pool"
        ]
        
        if let category = category {
            return categoryNames[category] ?? "Point of Interest"
        }
        return "Point of Interest"
    }
}
