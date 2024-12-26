import SwiftUI

protocol Feature {
    var priority: Int { get }
    func action(model: FrameHandler)
    func beforeRemove(model: FrameHandler)
    
    init?()
}

extension Feature {
    func beforeRemove(model: FrameHandler) {}
}

class FeaturesHandler: NSObject, ObservableObject {
    // TODO: Save enabled features
    @Published var features: [Feature] = []
    
    override init() {
        super.init()
        features.append(HapticFeedbackFeature())
        features.append(GeneralHapticFeature())
    }
    
    func action(model: FrameHandler) {
        features.sorted { $0.priority < $1.priority }
            .forEach { $0.action(model: model) }
    }
    
    func isEnabled<T: Feature>(_ type: T.Type) -> Bool {
        features.contains { $0 is T }
    }
    
    func enable<T: Feature>(_ type: T.Type) {
        if !isEnabled(type) {
            if let feature = type.init() {
                features.append(feature)
            }
        }
    }
    
    func disable<T: Feature>(_ type: T.Type, model: FrameHandler) {
        if let index = features.firstIndex(where: { $0 is T }) {
            features[index].beforeRemove(model: model)
            features.remove(at: index)
        }
    }
    
    func toggle<T: Feature>(_ type: T.Type, model: FrameHandler) {
        if isEnabled(type) {
            disable(type, model: model)
        } else {
            enable(type)
        }
    }
}
