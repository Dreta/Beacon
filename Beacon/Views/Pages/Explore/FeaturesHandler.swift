import SwiftUI

protocol Feature: Identifiable {
    var id: UUID { get }
    
    static var priority: Int { get }
    var _priority: Int { get }
    static var name: String { get }
    static var icon: String { get }
    func action(model: FrameHandler)
    func beforeRemove(model: FrameHandler)
    func overlay(model: FrameHandler) -> AnyView
    
    init?()
}

extension Feature {
    func beforeRemove(model: FrameHandler) {}
    func overlay(model: FrameHandler) -> AnyView {
        AnyView(EmptyView())
    }
    
    var _priority: Int {
        Self.priority
    }
}

class FeaturesHandler: NSObject, ObservableObject {
    // TODO: Save enabled features
    @Published var features: [any Feature] = []
    static let availableFeatures: [any Feature.Type] = [IdentifySelectFeature.self]
    
    override init() {
        super.init()
    }
    
    func action(model: FrameHandler) {
        // Sort feature by priority and run action, noting that priority is static
        features
            .sorted { $0._priority < $1._priority }
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
