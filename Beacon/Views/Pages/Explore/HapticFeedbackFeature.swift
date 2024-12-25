import UIKit

class HapticFeedbackFeature: Feature {
    var priority = 1 // Needs to happen AFTER IdentifySelectFeature
    
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Instead of using a repeating Timer, we'll track time ourselves:
    private var lastHapticTime: CFAbsoluteTime = 0       // last time a haptic was fired
    private var lastHapticInterval: TimeInterval = 1.0   // current time interval between haptics
    
    init() {
        heavyGenerator.prepare()
        mediumGenerator.prepare()
        lightGenerator.prepare()
    }
    
    func action(model: FrameHandler) {
        guard let object = model.selectedObject else { return }
        guard let depth = object.depth, depth <= 5.0 else {
            model.lastDepth = nil
            return
        }
        
        if let last = model.lastDepth, abs(depth - last) < 0.1 {
        } else {
            model.lastDepth = depth
            lastHapticInterval = hapticInterval(for: depth)
        }
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsed = currentTime - lastHapticTime
        
        if elapsed >= lastHapticInterval {
            if depth < 1.0 {
                heavyGenerator.impactOccurred()
            } else if depth < 2.0 {
                mediumGenerator.impactOccurred()
            } else {
                lightGenerator.impactOccurred()
            }
            lastHapticTime = currentTime
        }
    }
    
    /// Compute haptic interval based on depth
    private func hapticInterval(for depth: Float) -> TimeInterval {
        let minInterval: TimeInterval = 0.1
        let maxInterval: TimeInterval = 1.0
        
        let fraction = max(0, min(1, (depth - 0.7) / (5.0 - 0.7)))
        let interval = 0.05 + fraction * (1.0 - 0.05)
        return max(minInterval, min(Double(interval), maxInterval))
    }
}
