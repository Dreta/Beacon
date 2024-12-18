import SwiftUI

struct FrameView: View {
    var image: CGImage?
    var detections: [DetectedObject] = []
    private let label = Text("Frame")
    
    var body: some View {
        ZStack {
            if let image = image {
                // The camera image
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        GeometryReader { geo in
                            ForEach(detections) { detection in
                                // Convert normalized coordinates ([0...1]) to actual coordinates
                                let rect = boundingBoxRect(normalizedRect: detection.boundingBox, in: geo.size)
                                
                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                    
                                    Text("\(detection.label) \(Int(detection.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.7))
                                        .offset(x: rect.minX, y: rect.minY)
                                }
                            }
                        }
                    )
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
    
    private func boundingBoxRect(normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        let x = normalizedRect.minX * size.width
        // Vision's coordinate system for boundingBox is normalized with origin at bottom-left by default.
        // If it’s from VNRecognizedObjectObservation, the origin is actually bottom-left.
        // SwiftUI's coordinate space starts top-left. So we need to flip the y-axis.
        let y = (1 - normalizedRect.maxY) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#Preview {
    FrameView()
}
