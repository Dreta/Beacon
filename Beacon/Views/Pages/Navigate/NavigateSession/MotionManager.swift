import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private let motion = CMMotionManager()
    
    /// Indicates whether the user is holding the device upwards.
    @Published var isHoldingUp: Bool = false
    
    // Adjust this threshold to your liking.
    // Pitch (in radians) ranges roughly from -π to +π.
    // 0 = device flat, positive = device leaning “up”, negative = leaning “down”.
    private let pitchThreshold: Double = 0.8
    
    init() {
        // How often to receive motion updates (60 fps here)
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        
        // Start monitoring deviceMotion on the main thread
        motion.startDeviceMotionUpdates(to: .main) { [weak self] deviceMotion, error in
            guard let self = self, let motionData = deviceMotion else { return }
            
            // Get the pitch in radians
            let pitch = motionData.attitude.pitch
            
            // Check if pitch is above our chosen threshold
            let isUp = (pitch >= self.pitchThreshold)
            
            // Publish to SwiftUI
            if self.isHoldingUp != isUp {
                self.isHoldingUp = isUp
            }
        }
    }
    
    deinit {
        motion.stopDeviceMotionUpdates()
    }
}
