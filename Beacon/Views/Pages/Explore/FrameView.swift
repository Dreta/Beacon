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
                
                // 1) BOUNDING BOX OVERLAY (IdentifySelectFeature only)
                    .overlay(
                        GeometryReader { geo in
                            if model.featuresHandler
                                .isEnabled(IdentifySelectFeature.self),
                               let selected = model.selectedObject {
                                
                                let rect = boundingBoxRect(normalizedRect: selected.boundingBox, in: geo.size)
                                
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.yellow, lineWidth: 2)
                                        .background(RoundedRectangle(cornerRadius: 8)
                                            .fill(.yellow.opacity(0.2)))
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                    )
                
                // 2) DETECTED OBJECT INFO (IdentifySelectFeature only)
                    .overlay(
                        VStack {
                            if model.featuresHandler
                                .isEnabled(IdentifySelectFeature.self),
                               let selected = model.selectedObject {
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
                    )
                // 4) SETTINGS BUTTON (bottom overlay)
                    .overlay(
                        VStack {
                            HStack {
                                let identifyActive = model.featuresHandler.isEnabled(
                                    IdentifySelectFeature.self
                                )
                                
                                Button(action: {
                                    model.featuresHandler
                                        .toggle(IdentifySelectFeature.self, model: model)
                                }) {
                                    Image(systemName: "person.crop.rectangle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22)
                                        .padding(10)
                                        .foregroundColor(identifyActive ? .white : .secondary)
                                        .background(
                                            Circle()
                                                .fill(identifyActive ? .accentColor : .background)
                                        )
                                }
                                .accessibilityLabel(
                                    Text(identifyActive
                                         ? "Turn off object identification"
                                         : "Turn on object identification")
                                )
                                
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(.ultraThinMaterial)
                        }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
    
    /// Convert a normalized bounding box (0...1) to actual CGRect in the view.
    private func boundingBoxRect(normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        let x = normalizedRect.minX * size.width
        // Flip y for Vision bounding boxes
        let y = (1 - normalizedRect.maxY) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
