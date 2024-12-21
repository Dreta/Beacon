import Vision
import CoreImage
import UIKit

class ObjectDetectionHandler {
    private let visionModel: VNCoreMLModel
    
    init?() {
        guard let model = try? VNCoreMLModel(for: yolo11m().model) else {
            return nil
        }
        self.visionModel = model
    }
    
    func performDetection(on cgImage: CGImage, completion: @escaping ([DetectedObject]) -> Void) {
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            guard error == nil else {
                completion([])
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
            completion(detections)
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                completion([])
            }
        }
    }
}
