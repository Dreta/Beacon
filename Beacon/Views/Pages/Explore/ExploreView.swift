import SwiftUI

struct ExploreView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame, selected: model.selectedObject)
            .onAppear {
                model.checkPermissionAndStart()
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                model.stop()
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
}

#Preview {
    ExploreView()
}
