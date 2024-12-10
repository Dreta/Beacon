import SwiftUI

struct ObstacleView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame, boundingBoxes: model.boundingBoxes)
            .ignoresSafeArea()
    }
}

#Preview {
    ObstacleView()
}
