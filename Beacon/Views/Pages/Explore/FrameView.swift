import SwiftUI

import SwiftUI

struct FrameView: View {
    @StateObject var model: FrameHandler
    private let label = Text("Frame")
    
    var body: some View {
        ZStack {
            if let image = model.frame {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        GeometryReader { geo in
                            if let selected = model.selectedObject {
                                let rect = boundingBoxRect(normalizedRect: selected.boundingBox, in: geo.size)
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.yellow, lineWidth: 2)
                                        .fill(.yellow.opacity(0.2))
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                    )
                    .overlay(
                        VStack {
                            if let selected = model.selectedObject {
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
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .foregroundColor(.white)
                            }
                        }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top)
                    )
                    .overlay(
                        VStack {
                            HStack {
                                Button(action: {
                                    // Add button action here
                                    print("Button tapped!")
                                }) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(.background))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(.ultraThinMaterial)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
