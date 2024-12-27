import Vision
import SwiftUI

class TrafficLightFeature: Feature {
    let id = UUID()
    
    static var priority: Int = 0
    static var name: String = "Traffic Light Detection"
    static var icon: String = "light.beacon.max.fill"
    static var conflict: [any Feature.Type] = [IdentifySelectFeature.self]
    
    private let visionModel: VNCoreMLModel
    
    required init?() {
        guard let model = try? VNCoreMLModel(for: yoloTrafficLight().model) else {
            return nil
        }
        self.visionModel = model
    }
    
    func overlay(model: FrameHandler) -> AnyView {
        AnyView(ZStack {
            TrafficLightBoundingBox(model: model)
            TrafficLightInfo(model: model)
        })
    }
    
    func action(model: FrameHandler) {
        guard let image = model.frame else {
            DispatchQueue.main.async {
                model.trafficLight = nil
            }
            return
        }
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            guard error == nil else {
                model.trafficLight = nil
                return
            }
            var detections: [DetectedObject] = []
            for observation in request.results ?? [] {
                guard let obj = observation as? VNRecognizedObjectObservation else { continue }
                if let topLabel = obj.labels.first {
                    let detection = DetectedObject(label: topLabel.identifier,
                                                   boundingBox: obj.boundingBox,
                                                   confidence: topLabel.confidence)
                    detections.append(detection)
                }
            }
            DispatchQueue.main.async {
                self.updateSelection(model: model, with: detections)
            }
        }
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    model.trafficLight = nil
                }
            }
        }
    }
    
    private func updateSelection(model: FrameHandler, with objects: [DetectedObject]) {
        guard !objects.isEmpty else {
            model.trafficLight = nil
            return
        }
        
        let centerOfScreen = CGPoint(x: 0.5, y: 0.5)
        let sorted = objects.sorted {
            distanceSquared($0.boundingBox.center, centerOfScreen)
            < distanceSquared($1.boundingBox.center, centerOfScreen)
        }
        
        guard let newSelected = sorted.first else {
            model.trafficLight = nil
            return
        }
        
        model.trafficLight = newSelected
    }
    
    private func distanceSquared(_ boxCenter: CGPoint, _ screenCenter: CGPoint) -> CGFloat {
        let dx = boxCenter.x - screenCenter.x
        let dy = boxCenter.y - screenCenter.y
        return dx * dx + dy * dy
    }
    
    func beforeRemove(model: FrameHandler) {
        DispatchQueue.main.async {
            model.trafficLight = nil
        }
    }
}
