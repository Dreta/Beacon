import SwiftUI

struct TrafficLightInfo: View {
    @StateObject var model: FrameHandler
    private let label = Text("Traffic Light Information")
    
    var body: some View {
        VStack {
            if let selected = model.trafficLight {
                VStack(alignment: .center, spacing: 4) {
                    Text("\(selected.label)".capitalized(with: .current))
                        .font(.headline)
                    
                    Text("\(Int(selected.confidence * 100))%")
                        .font(.subheadline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .foregroundColor(.white)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top)
    }
}
