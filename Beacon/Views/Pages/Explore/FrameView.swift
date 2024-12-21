import SwiftUI

import SwiftUI

struct FrameView: View {
    var image: CGImage?
    var selected: DetectedObject?
    private let label = Text("Frame")
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        GeometryReader { geo in
                            if let selected = selected {
                                let rect = boundingBoxRect(normalizedRect: selected.boundingBox, in: geo.size)
                                ZStack(alignment: .topLeading) {
                                    // Highlight the detected object
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.yellow, lineWidth: 2)
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                    )
                    .overlay(
                        VStack {
                            if let selected = selected {
                                VStack(alignment: .center, spacing: 4) {
                                    Text("\(selected.label)".capitalized(with: .current))
                                        .font(.headline)
                                    if let depth = selected.depth {
                                        Text(String(format: "Depth: %.2f m", depth))
                                            .font(.subheadline)
                                    }
                                    Text("\(Int(selected.confidence * 100))%")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(16)
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 20)
                    )
            } else {
                VStack {
                    Text("To use Explore, please allow camera access in Settings.")
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
