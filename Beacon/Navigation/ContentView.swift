import SwiftUI

struct ContentView: View {
    @ObservedObject var model = RouteHelper()
    @State private var startText: String = ""
    @State private var endText: String = ""
    
    var body: some View {
        VStack {
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
    }
}

#Preview {
    ContentView()
}
