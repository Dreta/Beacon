import UIKit

class GeneralHapticFeature: Feature {
    var priority: Int = 0
    
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var lastHapticTime: CFAbsoluteTime = 0
    private var lastHapticInterval: TimeInterval = 1.0
    
    init() {
        heavyGenerator.prepare()
        mediumGenerator.prepare()
        lightGenerator.prepare()
    }
    
    func action(model: FrameHandler) {
        // If IdentifySelectFeature is selecting an object, skip.
        guard model.selectedObject == nil else { return }
        
        guard let minDepthValue = model.minDepth else { return }
        
        let maxAllowedDistance: Float = 5.0
        guard minDepthValue <= maxAllowedDistance else { return }
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsed = currentTime - lastHapticTime
        let interval = hapticInterval(for: minDepthValue)
        
        if elapsed >= interval {
            // Choose intensity
            if minDepthValue < 1.0 {
                heavyGenerator.impactOccurred()
            } else if minDepthValue < 2.0 {
                mediumGenerator.impactOccurred()
            } else {
                lightGenerator.impactOccurred()
            }
            lastHapticTime = currentTime
            lastHapticInterval = interval
        }
    }
    
    private func hapticInterval(for depth: Float) -> TimeInterval {
        let minInterval: TimeInterval = 0.1
        let maxInterval: TimeInterval = 1.0
        let fraction = max(0, min(1, (depth - 0.7) / (5.0 - 0.7)))
        let interval = Double(0.05 + fraction * (1.0 - 0.05))
        return max(minInterval, min(interval, maxInterval))
    }
}
