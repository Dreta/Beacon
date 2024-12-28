import SwiftUI

struct FrameView: View {
    @StateObject var model: FrameHandler
    private let label = Text("Explore View")
    
    var body: some View {
        ZStack {
            if let image = model.frame {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        ZStack {
                            ForEach(model.featuresHandler.features, id: \.id) { feature in
                                feature.overlay(model: model)
                            }
                        }.accessibilityHidden(true) // Hide from accessibility to avoid confusion - feedback should be provided separately
                    )
                    .overlay(
                        VStack {
                            HStack {
                                // Enumerate through each of FeaturesHandler.availableFeatures by converting to an array
                                ForEach(Array(FeaturesHandler.availableFeatures.enumerated()), id: \.offset) { index, featureType in
                                    let enabled = model.featuresHandler.isEnabled(featureType)
                                    Button(action: {
                                        model.featuresHandler.toggle(featureType, model: model)
                                    }) {
                                        Image(systemName: featureType.icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                            .padding(10)
                                            .foregroundColor(enabled ? .white : .secondary)
                                            .background(
                                                Circle()
                                                    .fill(enabled ? .accentColor : Color(.systemBackground))
                                            )
                                    }
                                    .accessibilityLabel(
                                        Text(enabled
                                             ? "Turn off \(featureType.name)"
                                             : "Turn on \(featureType.name)")
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(.ultraThinMaterial)
                        }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    )
            } else {
                // Camera access or fallback UI
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
}
