import AVFoundation
import CoreImage
import CoreML
import Vision

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var boundingBoxes: [CGRect] = []
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    
    private var visionModel: VNCoreMLModel?
    
    override init() {
        super.init()
        setupVisionModel()
        checkPermissionAndStart()
    }
    
    private func setupVisionModel() {
        guard let model = try? yolov8m(configuration: .init()).model else {
            print("Failed to load Core ML model")
            return
        }
        visionModel = try? VNCoreMLModel(for: model)
    }
    
    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            sessionQueue.async { [unowned self] in
                self.setupCaptureSession()
                self.captureSession.startRunning()
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
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        guard permissionGranted else { return }
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let visionModel = visionModel else { return }
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
            self?.processObservations(for: request)
        }
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
        
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func processObservations(for request: VNRequest) {
        guard let results = request.results as? [VNRecognizedTextObservation] else { return }
        
        let boundingBoxes: [CGRect] = results.map { $0.boundingBox }
        print("Discovered \(boundingBoxes.count)") // FIXME WHY ISN'T THIS DISCOVERING ANYTHING??
        DispatchQueue.main.async {
            self.boundingBoxes = boundingBoxes
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
}
