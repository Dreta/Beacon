import SwiftUI
import MapKit

struct MapItemDetailsView: View {
    var start: CLLocationCoordinate2D
    var item: MKMapItem
    @Binding var selectedItem: MKMapItemWrapped?
    
    @State private var travelTimeText = "..."
    
    var onWalkButtonTapped: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.name ?? "")
                    .font(.title)
                    .padding(.bottom, 3)
                    .bold()
                Spacer()

                
                Button(action: {
                    selectedItem = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .accessibilityLabel("Close")
            }
            Text("\(MapItemView.name(for: item.pointOfInterestCategory)) · \(item.placemark.locality ?? "") \(item.placemark.subLocality ?? "")")
                .padding(.bottom, 8)
            
            // MARK: - "Walk" Button
            Button(action: {
                onWalkButtonTapped?()
            }) {
                Text(LocalizedStringKey("**Walk** · \(travelTimeText)"))
                    .frame(maxWidth: .infinity)
                    .padding(.all, 8)
            }
            .cornerRadius(12)
            .buttonStyle(BorderedProminentButtonStyle())
            .onAppear {
                findTime { maybeTime in
                    guard let time = maybeTime else {
                        travelTimeText = "N/A"
                        return
                    }
                    travelTimeText = formatSeconds(time)
                }
            }
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.quaternarySystemFill))
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        if let phone = item.phoneNumber, !phone.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone")
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    if let phoneURL = URL(string: "tel://\(phone.filter { "0123456789".contains($0) })"),
                                       UIApplication.shared.canOpenURL(phoneURL) {
                                        UIApplication.shared.open(phoneURL)
                                    }
                                }) {
                                    Text(phone)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        if let url = item.url {
                            VStack(alignment: .leading, spacing: 2) {
                                if let phone = item.phoneNumber, !phone.isEmpty {
                                    Divider()
                                        .padding(.bottom, 8)
                                }
                                Text("Website")
                                    .foregroundColor(.secondary)
                                
                                Link(destination: url) {
                                    Text(url.absoluteString)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        let address = formattedAddress()
                        if !address.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                if let phone = item.phoneNumber, !phone.isEmpty || item.url != nil {
                                    Divider()
                                        .padding(.bottom, 8)
                                }
                                Text("Address")
                                    .foregroundColor(.secondary)
                                
                                Text(address)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                        .padding()
                )
                .padding(.top, 16)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 24)
    }
    
    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter.string(from: seconds) ?? ""
    }
    
    private func findTime(completion: @escaping (TimeInterval?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = item
        request.transportType = .walking

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error fetching directions: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            completion(route.expectedTravelTime)
        }
    }
    
    private func formattedAddress() -> String {
        let placemark = item.placemark
        var addressComponents: [String] = []
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: " ")
    }
}
