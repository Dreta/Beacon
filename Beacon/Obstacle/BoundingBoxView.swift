import SwiftUI

struct BoundingBoxView: View {
    let boundingBoxes: [CGRect]
    let frameSize: CGSize

    var body: some View {
        ZStack {
            ForEach(boundingBoxes, id: \.self) { box in
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: box.width * frameSize.width,
                           height: box.height * frameSize.height)
                    .position(x: box.midX * frameSize.width,
                              y: (1 - box.midY) * frameSize.height) // Flip Y-axis
            }
        }
    }
}
