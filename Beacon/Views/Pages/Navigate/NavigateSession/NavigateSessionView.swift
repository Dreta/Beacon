import SwiftUI
import MapKit
import AVFoundation

struct NavigateSessionView: View {
    @ObservedObject var locationManager: LocationManager = LocationManager()
    @ObservedObject var realTimeNavigator: RealTimeNavigator
    
    private let synthesizer = AVSpeechSynthesizer()
    @State private var lastWord = ""
    
    @State private var endRouteSheet = false
    
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
            // MARK: - Map (Hidden from VoiceOver)
            Map()
                .accessibilityHidden(true) // Hides the map from VoiceOver
                .onReceive(locationManager.$rawLocation) { loc in
                    guard let loc = loc else { return }
                    realTimeNavigator.updateLocation(loc)
                    speak(realTimeNavigator.instruction)
                }
            
            VStack {
                // MARK: - Top Overlay (Subtitle and Title)
                VStack(alignment: .leading) {
                    // Subtitle
                    Text(realTimeNavigator.displaySubtitle)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .transition(.move(edge: .top))
                        .id("Subtitle\(realTimeNavigator.displaySubtitle)")
                    
                    // Title
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
                
                // MARK: - Bottom Overlay (Arrival Time, Remaining Time, Distance)
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
                        Button(action: {
                            endRouteSheet = true
                        }) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
