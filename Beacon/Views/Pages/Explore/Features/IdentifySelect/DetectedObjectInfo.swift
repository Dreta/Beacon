import SwiftUI

struct DetectedObjectInfo: View {
    @StateObject var model: FrameHandler
    private let label = Text("Detected Object Information")
    
    var body: some View {
        VStack {
            if let selected = model.selectedObject {
                VStack(alignment: .center, spacing: 4) {
                    Text("\(selected.label)".capitalized(with: .current))
                        .font(.headline)
                    
                    if let depth = selected.depth {
                        Text(String(format: "Distance: %.2f m", depth))
                            .font(.subheadline)
                    }
                    
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
