import SwiftUI

struct ExploreView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(model: model)
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
