import AVFoundation
import CoreImage
import CoreML
import Vision

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var boundingBoxes: [CGRect] = []
    @Published var objectDepths: [Float] = []
    
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    
    private var visionModel: VNCoreMLModel?
    private var depthDataMap: CVPixelBuffer?
    
    override init() {
        super.init()
        print("Initializing FrameHandler...")
        setupVisionModel()
        checkPermissionAndStart()
    }
    
    private func setupVisionModel() {
        print("Setting up Vision model...")
        do {
            let model = try yolo11n(configuration: .init()).model
            visionModel = try VNCoreMLModel(for: model)
            print("Core ML model loaded successfully!")
        } catch {
            print("Error loading Core ML model: \(error)")
        }
    }
    
    func checkPermissionAndStart() {
        print("Checking camera permission...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera permission granted.")
            permissionGranted = true
            sessionQueue.async { [unowned self] in
                self.setupCaptureSession()
                self.captureSession.startRunning()
                print("Capture session started.")
            }
        case .notDetermined:
            print("Camera permission not determined. Requesting permission...")
            requestPermissionAndStart()
        default:
            print("Camera permission denied.")
            permissionGranted = false
        }
    }
    
    func requestPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            print("Permission granted: \(granted)")
            permissionGranted = granted
            if granted {
                sessionQueue.async { [unowned self] in
                    self.setupCaptureSession()
                    self.captureSession.startRunning()
                    print("Capture session started after permission.")
                }
            } else {
                print("Camera access denied by user.")
            }
        }
    }
    
    func setupCaptureSession() {
        print("Setting up capture session...")
        let videoOutput = AVCaptureVideoDataOutput()
        let depthOutput = AVCaptureDepthDataOutput()
        guard permissionGranted else {
            print("Permission not granted. Exiting setup.")
            return
        }
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
            print("Failed to get video device.")
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Failed to create video device input.")
            return
        }
        guard captureSession.canAddInput(videoDeviceInput) else {
            print("Cannot add video input to capture session.")
            return
        }
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        if captureSession.canAddOutput(depthOutput) {
            captureSession.addOutput(depthOutput)
            depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthDataQueue"))
        }
        
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
        print("Capture session configured successfully.")
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        guard let visionModel = visionModel else {
            print("Vision model is not set up.")
            return
        }
        
        print("Running Core ML model on captured frame...")
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
            self?.processObservations(for: request)
        }
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
        
        if let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) {
            DispatchQueue.main.async { [unowned self] in
                self.frame = cgImage
            }
        }
    }
    
    private func processObservations(for request: VNRequest) {
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let multiArray = results.first?.featureValue.multiArrayValue else {
            print("No valid results from Core ML model.")
            return
        }
        
        print("Decoding YOLO model output...")

        // YOLO model configuration
        let gridCells = 8400        // Number of grid cells
        let attributesPerBox = 84   // Total attributes per box
        let numClasses = 80         // Adjust based on your model's class count
        
        var boundingBoxes: [CGRect] = []
        var confidenceScores: [Float] = []
        var depths: [Float] = []

        // Iterate through each grid cell
        for i in 0..<gridCells {
            let confidence = multiArray[[0, 4, i] as [NSNumber]].floatValue
            if confidence < 0.4 { continue }  // Confidence threshold
            
            // Extract bounding box (center_x, center_y, width, height) normalized
            let centerX = multiArray[[0, 0, i] as [NSNumber]].floatValue
            let centerY = multiArray[[0, 1, i] as [NSNumber]].floatValue
            let width = multiArray[[0, 2, i] as [NSNumber]].floatValue
            let height = multiArray[[0, 3, i] as [NSNumber]].floatValue
            
            // Convert to CGRect (normalized coordinates)
            let x = CGFloat(centerX - width / 2)
            let y = CGFloat(centerY - height / 2)
            let rect = CGRect(x: x, y: y, width: CGFloat(width), height: CGFloat(height))
            
            // Find class with highest probability
            var maxClassScore: Float = 0.0
            var bestClassIndex: Int = -1
            for c in 5..<5 + numClasses {
                let classScore = multiArray[[0, c, i] as [NSNumber]].floatValue
                if classScore > maxClassScore {
                    maxClassScore = classScore
                    bestClassIndex = c - 5
                }
            }
            
            // Only add bounding boxes with valid class predictions
            if bestClassIndex >= 0 {
                boundingBoxes.append(rect)
                confidenceScores.append(confidence)
                
                // Calculate the average depth for this bounding box
                if let averageDepth = calculateAverageDepth(for: rect) {
                    depths.append(averageDepth)
                } else {
                    depths.append(-1.0)  // Use -1.0 to indicate no depth data
                }
            }
        }
        
        print("Decoded \(boundingBoxes.count) bounding boxes with depths.")
        print("Bounding Boxes: \(boundingBoxes)")
        print("Depth Values: \(depths)")
        
        // Update UI on the main thread
        DispatchQueue.main.async {
            self.boundingBoxes = boundingBoxes
            self.objectDepths = depths
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    private func calculateAverageDepth(for boundingBox: CGRect) -> Float? {
        guard let depthDataMap = depthDataMap else {
            print("Depth data map not available.")
            return nil
        }
        CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthDataMap)
        let height = CVPixelBufferGetHeight(depthDataMap)
        let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthDataMap) / MemoryLayout<Float32>.size
        
        let xMin = Int(boundingBox.minX * CGFloat(width))
        let xMax = Int(boundingBox.maxX * CGFloat(width))
        let yMin = Int(boundingBox.minY * CGFloat(height))
        let yMax = Int(boundingBox.maxY * CGFloat(height))
        
        var depthValues: [Float32] = []
        for y in yMin..<yMax {
            for x in xMin..<xMax {
                let depthValue = baseAddress?.load(fromByteOffset: (y * bytesPerRow + x) * MemoryLayout<Float32>.size, as: Float32.self) ?? 0
                depthValues.append(depthValue)
            }
        }
        
        let averageDepth = depthValues.isEmpty ? nil : depthValues.reduce(0, +) / Float(depthValues.count)
        print("Average depth for bounding box: \(averageDepth ?? -1.0)")
        return averageDepth
    }
}

extension FrameHandler: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(
        _ output: AVCaptureDepthDataOutput,
        didOutput depthData: AVDepthData,
        timestamp: CMTime,
        connection: AVCaptureConnection
    ) {
        self.depthDataMap = depthData.depthDataMap
        print("Depth data map updated.")
    }
}
