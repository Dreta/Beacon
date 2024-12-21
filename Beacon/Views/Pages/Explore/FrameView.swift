import SwiftUI

struct FrameView: View {
    var model: FrameHandler?
    private let label = Text("Frame")
    
    var body: some View {
        ZStack {
            if let model = model, let image = model.frame {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        GeometryReader { geo in
                            ForEach(model.detectedObjects) { detection in
                                let rect = boundingBoxRect(normalizedRect: detection.boundingBox, in: geo.size)
                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(detection.label) \(Int(detection.confidence * 100))%")
                                        if let depth = detection.depth {
                                            Text(String(format: "Depth: %.2f m", depth))
                                        } else {
                                            Text("Depth: N/A")
                                        }
                                    }
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
                    Text("To use obstacle detection and depth, please allow camera access in Settings.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                    Button("Open Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    
    private func boundingBoxRect(normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        let x = normalizedRect.minX * size.width
        let y = (1 - normalizedRect.maxY) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#Preview {
    FrameView()
}
