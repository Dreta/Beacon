import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("Frame");
    var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label)
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

#Preview {
    FrameView()
}

