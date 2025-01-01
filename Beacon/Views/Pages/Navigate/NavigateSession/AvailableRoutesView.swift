import SwiftUI
import MapKit

struct AvailableRoutesView: View {
    @State var start: CLLocationCoordinate2D
    @State var end: MKMapItem
    @Binding var routes: [MKRoute]
    
    @Binding var toNavigateItem: MKMapItemWrapped?
    @Binding var region: MKCoordinateRegion
    @Binding var selectedRoute: MKRoute?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Routes")
                    .font(.title)
                    .padding(.bottom, 3)
                    .bold()
                Spacer()
                
                
                Button(action: {
                    toNavigateItem = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            List(routes, id: \.self) { route in
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatSeconds(route.expectedTravelTime))
                            .font(.title3)
                            .bold()
                        Text("\(formatArrivalTime(route.expectedTravelTime)) · \(formatDistance(route.distance))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        selectedRoute = route
                    }) {
                        Text("Go")
                            .font(.title3)
                            .bold()
                            .padding(.all, 8)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.green)
                    .frame(maxHeight: .infinity)
                }
            }
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            fetchRoutes()
            updateRegion()
        }
        .onChange(of: start) {
            fetchRoutes()
            updateRegion()
        }
        .onChange(of: end) {
            fetchRoutes()
            updateRegion()
        }
    }
    
    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter.string(from: seconds) ?? ""
    }
    
    private func formatArrivalTime(_ seconds: TimeInterval) -> String {
        let currentDate = Date()
        let arrivalDate = currentDate.addingTimeInterval(seconds)
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        
        if calendar.isDateInToday(arrivalDate) {
            let timeString = timeFormatter.string(from: arrivalDate)
            return "\(timeString)"
        } else if calendar.isDateInTomorrow(arrivalDate) {
            // Arrival is tomorrow
            let timeString = timeFormatter.string(from: arrivalDate)
            return "\(timeString) tomorrow"
        } else {
            let startOfToday = calendar.startOfDay(for: currentDate)
            let startOfArrival = calendar.startOfDay(for: arrivalDate)
            
            if let daysDifference = calendar.dateComponents([.day], from: startOfToday, to: startOfArrival).day {
                if daysDifference > 1 {
                    let weekday = weekdayFormatter.string(from: arrivalDate)
                    let timeString = timeFormatter.string(from: arrivalDate)
                    return "\(weekday) at \(timeString)"
                }
            }
        }
        
        let fallbackTimeString = timeFormatter.string(from: arrivalDate)
        return "\(fallbackTimeString)"
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        let locale = Locale.current
        
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        formatter.locale = locale
        formatter.numberFormatter.maximumFractionDigits = 0
        if locale.measurementSystem == .metric {
            return formatter.string(from: measurement)
        } else {
            let miles = measurement.converted(to: .miles)
            return formatter.string(from: miles)
        }
    }
    
    private func fetchRoutes() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = end
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error fetching directions: \(error.localizedDescription)")
                routes = []
                return
            }
            routes = response?.routes ?? []
        }
    }
    
    private func updateRegion() {
        let startCoordinate = start
        let endCoordinate = end.placemark.coordinate
        
        // Calculate the midpoint between start and end
        let midLatitude = (startCoordinate.latitude + endCoordinate.latitude) / 2
        let midLongitude = (startCoordinate.longitude + endCoordinate.longitude) / 2
        var center = CLLocationCoordinate2D(latitude: midLatitude, longitude: midLongitude)
        
        // Calculate the span (how much of the map to display)
        let latitudeDelta = abs(startCoordinate.latitude - endCoordinate.latitude) * 1.5
        let longitudeDelta = abs(startCoordinate.longitude - endCoordinate.longitude) * 1.5
        
        // Ensure a minimum span to prevent excessive zooming in
        let minSpan = 0.008
        let finalLatitudeDelta = max(latitudeDelta, minSpan)
        let finalLongitudeDelta = max(longitudeDelta, minSpan)
        
        let span = MKCoordinateSpan(latitudeDelta: finalLatitudeDelta, longitudeDelta: finalLongitudeDelta)
        
        // Move the center upwards so that the bottom sheet won't obscure the route
        let shiftFactor: Double = -0.5
        center.latitude += (span.latitudeDelta * shiftFactor)
        region = MKCoordinateRegion(center: center, span: span)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
