import SwiftUI

struct ExploreView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame, detections: model.detectedObjects)
            .onAppear {
                model.checkPermissionAndStart()
            }
            .onDisappear {
                model.stop()
            }
    }
}

#Preview {
    ExploreView()
}
