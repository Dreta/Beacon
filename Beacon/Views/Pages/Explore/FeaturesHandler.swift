import SwiftUI

protocol Feature {
    var priority: Int { get }
    func action(model: FrameHandler)
}

class FeaturesHandler: NSObject, ObservableObject {
    // TODO: Save enabled features
    @Published var features: [Feature] = []
    
    override init() {
        super.init()
        guard let feature = IdentifySelectFeature() else { return }
        features.append(feature)
        features.append(HapticFeedbackFeature())
    }
    
    func action(model: FrameHandler) {
        features.sorted { $0.priority < $1.priority }
            .forEach { $0.action(model: model) }
    }
}
