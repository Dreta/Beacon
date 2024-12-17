import SwiftUI

struct BoundingBoxView: View {
    let boundingBoxes: [CGRect]
    let objectDepths: [Float]
    let frameSize: CGSize

    var body: some View {
        ZStack {
            ForEach(Array(zip(boundingBoxes.indices, boundingBoxes)), id: \.0) { index, box in
                ZStack {
                    // Bounding box
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: box.width, height: box.height) // Use normal coordinates directly
                        .position(x: box.midX, y: box.midY) // Use normal midX and midY directly
                    
                    // Depth label
                    if index < objectDepths.count {
                        Text(String(format: "%.2f m", objectDepths[index]))
                            .font(.caption)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.7))
                            .position(x: box.midX, y: box.minY - 10) // Display slightly above the box
                    }
                }
            }
        }
    }
}
