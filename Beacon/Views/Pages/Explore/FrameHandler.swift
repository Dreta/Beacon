import AVFoundation
import CoreImage
import CoreML
import Vision

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var detectedObjects: [DetectedObject] = []
    
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var captureSessionReady = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private let detectionHandler = ObjectDetectionHandler()
    
    private var latestDepthData: AVDepthData?
    private var depthDataOutput = AVCaptureDepthDataOutput()
    
    override init() {
        super.init()
    }
    
    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            sessionQueue.async { [unowned self] in
                if !captureSessionReady {
                    self.setupCaptureSession()
                }
                self.captureSession.startRunning()
                print("Capture session started")
            }
        case .notDetermined:
            requestPermissionAndStart()
        default:
            permissionGranted = false
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    deinit {
        stop()
    }
    
    func requestPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            permissionGranted = granted
            if granted {
                sessionQueue.async { [unowned self] in
                    self.setupCaptureSession()
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    func setupCaptureSession() {
        // Try to select a LiDAR-capable camera
        guard permissionGranted else { return }
        
        // For LiDAR: .builtInLiDARDepthCamera is available on certain devices.
        // If not available, fallback to dual camera if it supports depth.
        guard let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera,
                                                        for: .video,
                                                        position: .back)
            ?? AVCaptureDevice.default(.builtInDualWideCamera,
                                       for: .video,
                                       position: .back) else { return }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo // or .high depending on needs
        captureSession.addInput(videoDeviceInput)
        
        // Video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoOutput)
        // Optional: rotate if needed
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
        
        // Depth output
        if captureSession.canAddOutput(depthDataOutput) {
            depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthDataQueue"))
            depthDataOutput.isFilteringEnabled = true
            captureSession.addOutput(depthDataOutput)
            
            // Synchronize depth with video, if possible
            if let connection = depthDataOutput.connection(with: .depthData), connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            
            // Match the depth format to video format if possible
            if let depthConnection = depthDataOutput.connection(with: .depthData),
               let videoConnection = videoOutput.connection(with: .video) {
                depthConnection.videoRotationAngle = videoConnection.videoRotationAngle
            }
        }
        
        captureSession.commitConfiguration()
        captureSessionReady = true
    }
    
    // Approximate depth for each detected object
    private func annotateDepth(for objects: [DetectedObject]) -> [DetectedObject] {
        guard let depthData = latestDepthData else { return objects }
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
            let centerY = (1 - obj.boundingBox.midY) * CGFloat(height) // flip y due to coordinate systems
            let xInt = Int(centerX)
            let yInt = Int(centerY)
            
            var depthObj = obj
            
            if xInt >= 0 && xInt < width && yInt >= 0 && yInt < height {
                let index = yInt * width + xInt
                let disparity = baseAddress[index]
                // If we are using disparity, depth ≈ 1/disparity (if disparity > 0)
                // Check if disparity > 0 to avoid division by zero
                if disparity > 0 {
                    // Approximate depth in meters (disparity is roughly 1/m)
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
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }

        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
        
        // Run detection in background
        detectionHandler?.performDetection(on: cgImage) { [weak self] objects in
            guard let self = self else { return }
            // Once detection is done, try to annotate depth
            let annotated = self.annotateDepth(for: objects)
            DispatchQueue.main.async {
                self.detectedObjects = annotated
            }
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
}

extension FrameHandler: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                         didOutput depthData: AVDepthData,
                         timestamp: CMTime,
                         connection: AVCaptureConnection) {
        // Store the latest depth data
        self.latestDepthData = depthData
    }
}
