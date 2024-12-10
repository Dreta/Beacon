import SwiftUI

struct FrameView: View {
    var image: CGImage?
    var boundingBoxes: [CGRect] = []
    
    private let label = Text("Frame");

    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                ZStack {
                    Image(image, scale: 1.0, orientation: .up, label: label)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    BoundingBoxView(boundingBoxes: boundingBoxes, frameSize: geometry.size)
                }
            } else {
                VStack {
                    Text("To use obstacle detection, please allow camera access in Settings.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                    Button("Open Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

#Preview {
    FrameView()
}

