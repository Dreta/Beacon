import AVFoundation
import CoreImage
import CoreML
import Vision
import SwiftUI

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var selectedObject: DetectedObject?
    
    private var detectedObjects: [DetectedObject] = []
    
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var captureSessionReady = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private let detectionHandler = ObjectDetectionHandler()
    
    private var latestDepthData: AVDepthData?
    private var depthDataOutput = AVCaptureDepthDataOutput()
    
    // MARK: - Haptic Properties
    // ------------------------------------------------------------
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    
    /// Store the last depth used for interval changes
    private var lastDepth: Float?
    
    // Instead of using a repeating Timer, we'll track time ourselves:
    private var lastHapticTime: CFAbsoluteTime = 0       // last time a haptic was fired
    private var lastHapticInterval: TimeInterval = 1.0   // current time interval between haptics
    
    override init() {
        super.init()
        heavyGenerator.prepare()
        mediumGenerator.prepare()
        lightGenerator.prepare()
    }
    
    // MARK: - Camera Permission
    // ------------------------------------------------------------
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
    
    // MARK: - Capture Session Setup
    // ------------------------------------------------------------
    func setupCaptureSession() {
        guard permissionGranted else { return }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera,
                                                        for: .video,
                                                        position: .back)
                ?? AVCaptureDevice.default(.builtInDualWideCamera,
                                           for: .video,
                                           position: .back) else { return }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(videoDeviceInput)
        
        // Video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoOutput)
        // Rotate video if needed
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
        
        // Depth output
        if captureSession.canAddOutput(depthDataOutput) {
            depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthDataQueue"))
            depthDataOutput.isFilteringEnabled = true
            captureSession.addOutput(depthDataOutput)
            
            // Rotate depth if supported
            if let connection = depthDataOutput.connection(with: .depthData),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            // Match rotation with video
            if let depthConnection = depthDataOutput.connection(with: .depthData),
               let videoConnection = videoOutput.connection(with: .video) {
                depthConnection.videoRotationAngle = videoConnection.videoRotationAngle
            }
        }
        
        captureSession.commitConfiguration()
        captureSessionReady = true
    }
    
    // MARK: - Depth Annotation
    // ------------------------------------------------------------
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
    
    // MARK: - Selection & Haptic Logic
    // ------------------------------------------------------------
    /// Select the object whose bounding box center is closest to (0.5, 0.5) and handle haptics
    private func updateSelection(with objects: [DetectedObject]) {
        guard !objects.isEmpty else {
            // No objects => clear selection
            selectedObject = nil
            lastDepth = nil
            return
        }
        
        let centerOfScreen = CGPoint(x: 0.5, y: 0.5)
        let sorted = objects.sorted {
            distanceSquared($0.boundingBox.center, centerOfScreen)
            < distanceSquared($1.boundingBox.center, centerOfScreen)
        }
        
        guard let newSelected = sorted.first else {
            selectedObject = nil
            lastDepth = nil
            return
        }
        
        selectedObject = newSelected
        handleContinuousHaptics(for: newSelected)
    }
    
    /// Fire light haptics at a variable rate based on depth—without scheduling timers.
    private func handleContinuousHaptics(for object: DetectedObject) {
        guard let depth = object.depth, depth <= 5.0 else {
            lastDepth = nil
            return
        }
        
        if let last = lastDepth, abs(depth - last) < 0.1 {
        } else {
            lastDepth = depth
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
    
    private func distanceSquared(_ boxCenter: CGPoint, _ screenCenter: CGPoint) -> CGFloat {
        let dx = boxCenter.x - screenCenter.x
        let dy = boxCenter.y - screenCenter.y
        return dx * dx + dy * dy
    }
}

// MARK: - CGRect Helper
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
        
        // Run detection in the background
        detectionHandler?.performDetection(on: cgImage) { [weak self] objects in
            guard let self = self else { return }
            // Annotate with depth
            let annotated = self.annotateDepth(for: objects)
            DispatchQueue.main.async {
                // Update the published property
                self.detectedObjects = annotated
                // Then find & track the one closest to center, handle haptics
                self.updateSelection(with: annotated)
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

// MARK: - AVCaptureDepthDataOutputDelegate
extension FrameHandler: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                         didOutput depthData: AVDepthData,
                         timestamp: CMTime,
                         connection: AVCaptureConnection) {
        
        // Store the latest depth data
        self.latestDepthData = depthData
    }
}
