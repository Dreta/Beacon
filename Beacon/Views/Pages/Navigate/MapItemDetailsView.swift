import SwiftUI
import MapKit

struct MapItemDetailsView: View {
    var item: MKMapItem
    @Binding var selectedItem: MKMapItemWrapped?
    
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
            Text("\(MapItemView.name(for: item.pointOfInterestCategory)) · \(item.placemark.locality ?? "")\(item.placemark.subLocality ?? "")")
                .padding(.bottom, 8)
            
            Button(action: {
                
            }) {
                Text(LocalizedStringKey("**Walk** · 5 minutes"))
                    .frame(maxWidth: .infinity)
                    .padding(.all, 8)
            }
            .cornerRadius(12)
            .buttonStyle(BorderedProminentButtonStyle())
            
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
                                Divider()
                                    .padding(.bottom, 8)
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
                                Divider()
                                    .padding(.bottom, 8)
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
