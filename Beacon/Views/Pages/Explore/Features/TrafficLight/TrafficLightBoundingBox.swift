import SwiftUI

struct TrafficLightBoundingBox: View {
    @StateObject var model: FrameHandler
    private let label = Text("Bounding Box")
    
    var body: some View {
        GeometryReader { geo in
            if let selected = model.trafficLight {
                
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
    }
    
    private func boundingBoxRect(normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        let x = normalizedRect.minX * size.width
        // Flip y for Vision bounding boxes
        let y = (1 - normalizedRect.maxY) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
