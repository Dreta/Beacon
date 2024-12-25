import SwiftUI

protocol Feature {
    var priority: Int { get }
    func action(model: FrameHandler)
    func beforeRemove(model: FrameHandler)
}

extension Feature {
    func beforeRemove(model: FrameHandler) {}
}

class FeaturesHandler: NSObject, ObservableObject {
    // TODO: Save enabled features
    @Published var features: [Feature] = []
    
    override init() {
        super.init()
        if let f = IdentifySelectFeature() {
            features.append(f)
        }
        features.append(HapticFeedbackFeature())
    }
    
    func action(model: FrameHandler) {
        features.sorted { $0.priority < $1.priority }
            .forEach { $0.action(model: model) }
    }
}
