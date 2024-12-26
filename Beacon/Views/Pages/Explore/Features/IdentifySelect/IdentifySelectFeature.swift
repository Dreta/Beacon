import Vision
import SwiftUI

class IdentifySelectFeature: Feature {
    let id = UUID()
    
    static var priority: Int = 0
    static var name: String = "Object Identification"
    static var icon: String = "magnifyingglass"
    private let visionModel: VNCoreMLModel
    
    required init?() {
        guard let model = try? VNCoreMLModel(for: yolo11m().model) else {
            return nil
        }
        self.visionModel = model
    }
    
    func overlays(model: FrameHandler) -> AnyView {
        AnyView(
            ZStack {
                DetectedObjectInfo(model: model)
                BoundingBox(model: model)
            }
        )
    }
    
    func action(model: FrameHandler) {
        guard let image = model.frame else {
            DispatchQueue.main.async {
                model.detectedObjects = []
                model.selectedObject = nil
            }
            return
        }
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    model.detectedObjects = []
                    model.selectedObject = nil
                }
                return
            }
            
            var detections: [DetectedObject] = []
            for observation in request.results ?? [] {
                guard let obj = observation as? VNRecognizedObjectObservation else { continue }
                if let topLabel = obj.labels.first {
                    // VNRecognizedObjectObservation boundingBox is normalized to the image.
                    let detection = DetectedObject(label: topLabel.identifier,
                                                   boundingBox: obj.boundingBox,
                                                   confidence: topLabel.confidence)
                    detections.append(detection)
                }
            }
            DispatchQueue.main.async {
                model.detectedObjects = self.annotateDepth(model: model, for: detections)
                self.updateSelection(model: model, with: model.detectedObjects)
            }
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    model.detectedObjects = []
                    model.selectedObject = nil
                }
            }
        }
    }
    
    func beforeRemove(model: FrameHandler) {
        DispatchQueue.main.async {
            model.detectedObjects = []
            model.selectedObject = nil
        }
    }
    
    private func annotateDepth(model: FrameHandler, for objects: [DetectedObject]) -> [DetectedObject] {
        guard let depthData = model.latestDepthData else { return objects }
        let depthConverted = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        let depthBuffer = depthConverted.depthDataMap
        let width = CVPixelBufferGetWidth(depthBuffer)
        let height = CVPixelBufferGetHeight(depthBuffer)
        
        CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly)
        }
        
        let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer)!.assumingMemoryBound(to: Float.self)
        
        // For each object, take the center point of its bounding box and sample depth
        return objects.map { obj in
            let centerX = obj.boundingBox.midX * CGFloat(width)
            let centerY = (1 - obj.boundingBox.midY) * CGFloat(height) // flip y
            let xInt = Int(centerX)
            let yInt = Int(centerY)
            
            var depthObj = obj
            
            if xInt >= 0 && xInt < width && yInt >= 0 && yInt < height {
                let index = yInt * width + xInt
                let disparity = baseAddress[index]
                if disparity > 0 {
                    let depth = 1.0 / disparity
                    depthObj.depth = depth
                } else {
                    depthObj.depth = nil
                }
            } else {
                depthObj.depth = nil
            }
            return depthObj
        }
    }
    
    private func updateSelection(model: FrameHandler, with objects: [DetectedObject]) {
        guard !objects.isEmpty else {
            model.selectedObject = nil
            model.lastDepth = nil
            return
        }
        
        let centerOfScreen = CGPoint(x: 0.5, y: 0.5)
        let sorted = objects.sorted {
            distanceSquared($0.boundingBox.center, centerOfScreen)
            < distanceSquared($1.boundingBox.center, centerOfScreen)
        }
        
        guard let newSelected = sorted.first else {
            model.selectedObject = nil
            model.lastDepth = nil
            return
        }
        
        model.selectedObject = newSelected
    }
    
    private func distanceSquared(_ boxCenter: CGPoint, _ screenCenter: CGPoint) -> CGFloat {
        let dx = boxCenter.x - screenCenter.x
        let dy = boxCenter.y - screenCenter.y
        return dx * dx + dy * dy
    }
}
