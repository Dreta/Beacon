import SwiftUI

struct NavigateView: View {
    @ObservedObject var model = RouteHelper()
    @ObservedObject var locationManager = LocationManager()
    @StateObject var realTimeNavigator = RealTimeNavigator()
    @State var isUpdating = false
    @State private var startText: String = ""
    @State private var endText: String = ""
    
    var body: some View {
        VStack {
            VStack {
                Text(realTimeNavigator.instruction)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.2))
                
                Text("lat: \(locationManager.location.latitude), long: \(locationManager.location.longitude)")
                
                if !isUpdating {
                    Button {
                        locationManager.updateLocation()
                        isUpdating = true
                    } label: {
                        Text("Start Updating")
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Enter Start and End Points then press Calculate")
                TextField("Start Point", text: $startText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.top, .bottom], 5)
                TextField("End Point", text: $endText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Calculate") {
                    model.calculateRoute(from: startText, to: endText)
                }
            }.padding()
            
            Divider()
            
            ScrollView {
                Text(model.routeStr)
                    .padding()
            }
        }
        .padding()
        .onAppear() {
            model.$currentRoute
                .sink { [weak realTimeNavigator] route in
                    guard let route = route else { return }
                    realTimeNavigator?.route = route
                }
                .store(in: &realTimeNavigator.cancellables)

        }
    }
}

#Preview {
    NavigateView()
}
