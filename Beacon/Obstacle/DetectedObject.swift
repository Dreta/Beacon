import Foundation
import CoreGraphics

struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let boundingBox: CGRect // normalized coordinates [0...1] relative to the image
    let confidence: Float
}
