import SwiftUI
import MapKit
import AVFoundation

struct NavigateSessionView: View {
    @ObservedObject var locationManager: LocationManager = LocationManager()
    @ObservedObject var realTimeNavigator: RealTimeNavigator
    @StateObject private var motionManager = MotionManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @State private var player: AVAudioPlayer?
    @State private var lastWord = ""
    
    // Sheet state
    @State private var endRouteSheet = false
    
    // Throttle timestamp
    @State private var lastLocationUpdate: Date? = nil
    
    // Track the current user location here
    @State private var currentLocation: CLLocationCoordinate2D? = nil
    
    var selectedRoute: MKRoute
    var endRoute: () -> Void
    
    init(selectedRoute: MKRoute, endRoute: @escaping () -> Void) {
        self.selectedRoute = selectedRoute
        self.endRoute = endRoute
        realTimeNavigator = RealTimeNavigator()
        realTimeNavigator.route = selectedRoute
    }
    
    var body: some View {
        ZStack {
            // MARK: - UIKit MapView Wrapper
            RouteMapView(route: selectedRoute,
                         userLocation: $currentLocation)
                .accessibilityHidden(true)

            VStack {
                // MARK: - Top Overlay
                VStack(alignment: .leading) {
                    Text(realTimeNavigator.displaySubtitle)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .transition(.move(edge: .top))
                        .id("Subtitle\(realTimeNavigator.displaySubtitle)")
                    
                    Text(realTimeNavigator.displayTitle)
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                        .transition(.move(edge: .top))
                        .id("Title\(realTimeNavigator.displayTitle)")
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(24)
                .background(.black)
                .accessibilityHidden(true)
                
                Spacer()
                
                // MARK: - Bottom Overlay
                VStack {
                    HStack(spacing: 16) {
                        
                        // Arrival Time
                        VStack(alignment: .leading) {
                            Text(formattedArrivalTime())
                                .font(.title2)
                                .bold()
                                .accessibilityLabel("Estimated arrival time is \(formattedArrivalTime())")
                            Text("Arrival")
                                .font(.subheadline)
                                .accessibilityHidden(true)
                        }
                        
                        // Time Remaining
                        VStack(alignment: .leading) {
                            Text(formattedTimeRemaining())
                                .font(.title2)
                                .bold()
                                .accessibilityLabel("Time remaining is \(formattedTimeRemaining())")
                            Text("Time")
                                .font(.subheadline)
                                .accessibilityHidden(true)
                        }
                        
                        // Distance Remaining
                        VStack(alignment: .leading) {
                            Text(formattedDistanceRemaining())
                                .font(.title2)
                                .bold()
                                .accessibilityLabel("Distance remaining is \(formattedDistanceRemaining())")
                            Text("Distance")
                                .font(.subheadline)
                                .accessibilityHidden(true)
                        }
                        
                        Spacer()
                        
                        // More Options Button
                        Button {
                            endRouteSheet = true
                        } label: {
                            Image(systemName: "chevron.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .accessibilityLabel("More Options")
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .padding(24)
                    .background(Color(.systemBackground))
                }
            }
        }
        .sheet(isPresented: $endRouteSheet, onDismiss: { endRouteSheet = false }) {
            // MARK: - Sheet for Ending the Navigation
            VStack(alignment: .leading) {
                HStack {
                    Text("Options")
                        .font(.title)
                        .bold()
                    Spacer()
                    Button(action: {
                        endRouteSheet = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Button(action: {
                    endRouteSheet = false
                    endRoute()
                    speak("Navigation ended.")
                }) {
                    Text("End Navigation")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .font(.title3)
                        .bold()
                }
                .cornerRadius(12)
                .buttonStyle(BorderedProminentButtonStyle())
                .padding(16)
                .tint(.red)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationDetents([.medium])
        }
        .onAppear {
            speak("Walking navigation started.")
        }
        // Present ExploreView if user holds phone up
        .fullScreenCover(isPresented: $motionManager.isHoldingUp) {
            ExploreView()
                .onAppear {
                    playSound("explore.mp3")
                }
                .onDisappear {
                    playSound("explore-closed.mp3")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // MARK: - Throttle location updates and realTimeNavigator
        .onReceive(locationManager.$rawLocation) { loc in
            if loc == nil { return }
            currentLocation = locationManager.realCoordinate
            
            let now = Date()
            if let lastUpdate = lastLocationUpdate,
               now.timeIntervalSince(lastUpdate) < 2 {
                // Skip if less than 2s
                return
            }
            
            // Otherwise update realTimeNavigator
            lastLocationUpdate = now
            realTimeNavigator.updateLocation(CLLocation(latitude: locationManager.realCoordinate!.latitude, longitude: locationManager.realCoordinate!.longitude))
            speak(realTimeNavigator.instruction)
        }
    }
    
    // MARK: - Speech
    private func speak(_ word: String) {
        if lastWord != word {
            let utterance = AVSpeechUtterance(string: word)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
            lastWord = word
        }
    }
    
    // MARK: - Audio
    private func playSound(_ name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: nil) else { return }
        let url = URL(fileURLWithPath: path)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            player.play()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Formatting Helpers
    private func formattedArrivalTime() -> String {
        let arrivalDate = Date().addingTimeInterval(realTimeNavigator.timeRemaining)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: arrivalDate)
    }
    
    private func formattedTimeRemaining() -> String {
        let interval = realTimeNavigator.timeRemaining
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: interval) ?? "N/A"
    }
    
    private func formattedDistanceRemaining() -> String {
        let distance = realTimeNavigator.distanceRemaining
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit, .naturalScale]
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1
        
        var measurement = Measurement(value: distance, unit: UnitLength.meters)
        if distance >= 1000 {
            measurement = measurement.converted(to: .kilometers)
        }
        
        return formatter.string(from: measurement)
    }
}


struct RouteMapView: UIViewRepresentable {
    var route: MKRoute
    @Binding var userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // We want to follow the user location with heading (so the map orients to user facing direction).
        mapView.userTrackingMode = .followWithHeading
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        
        // Add the route overlay
        mapView.addOverlay(route.polyline)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard let location = userLocation else { return }

        let coordinate = location
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // If it's the polyline for the route, render it with a line.
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 12
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
