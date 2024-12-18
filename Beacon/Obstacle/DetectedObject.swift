import Foundation
import CoreGraphics

struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let boundingBox: CGRect
    let confidence: Float
    var depth: Float?
}
