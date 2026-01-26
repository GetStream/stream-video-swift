//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit

/// An enum describing the ways CodeScannerView can hit scanning problems.
enum ScanError: Error {
    /// The camera could not be accessed.
    case badInput

    /// The camera was not capable of scanning the requested codes.
    case badOutput

    /// Initialization failed.
    case initError(_ error: Error)

    /// The camera permission is denied
    case permissionDenied
}

/// The result from a successful scan: the string that was scanned, and also the type of data that was found.
/// The type is useful for times when you've asked to scan several different code types at the same time, because
/// it will report the exact code type that was found.
struct ScanResult {
    /// The contents of the code.
    let string: String

    /// The type of code that was matched.
    let type: AVMetadataObject.ObjectType

    /// The image of the code that was matched
    let image: UIImage?

    /// The corner coordinates of the scanned code.
    let corners: [CGPoint]
}

/// The operating mode for CodeScannerView.
enum ScanMode {
    /// Scan exactly one code, then stop.
    case once

    /// Scan each code no more than once.
    case oncePerCode

    /// Keep scanning all codes until dismissed.
    case continuous

    /// Scan only when capture button is tapped.
    case manual
}

struct CodeScannerView: UIViewControllerRepresentable {

    let codeTypes: [AVMetadataObject.ObjectType]
    let scanMode: ScanMode
    let manualSelect: Bool
    let scanInterval: Double
    let showViewfinder: Bool
    var simulatedData = ""
    var shouldVibrateOnSuccess: Bool
    var isTorchOn: Bool
    var videoCaptureDevice: AVCaptureDevice?
    var completion: (Result<ScanResult, ScanError>) -> Void

    init(
        codeTypes: [AVMetadataObject.ObjectType],
        scanMode: ScanMode = .once,
        manualSelect: Bool = false,
        scanInterval: Double = 2.0,
        showViewfinder: Bool = true,
        simulatedData: String = "",
        shouldVibrateOnSuccess: Bool = true,
        isTorchOn: Bool = false,
        videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.bestForVideo,
        completion: @escaping (Result<ScanResult, ScanError>) -> Void
    ) {
        self.codeTypes = codeTypes
        self.scanMode = scanMode
        self.manualSelect = manualSelect
        self.showViewfinder = showViewfinder
        self.scanInterval = scanInterval
        self.simulatedData = simulatedData
        self.shouldVibrateOnSuccess = shouldVibrateOnSuccess
        self.isTorchOn = isTorchOn
        self.videoCaptureDevice = videoCaptureDevice
        self.completion = completion
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        ScannerViewController(showViewfinder: showViewfinder, parentView: self)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.parentView = self
        uiViewController.updateViewController(
            isTorchOn: isTorchOn,
            isManualCapture: scanMode == .manual,
            isManualSelect: manualSelect
        )
    }
}

struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView(codeTypes: [.qr]) { _ in
            // do nothing
        }
    }
}

@MainActor
final class ScannerViewController: UIViewController, UINavigationControllerDelegate,
    @MainActor AVCaptureMetadataOutputObjectsDelegate,
    UIAdaptivePresentationControllerDelegate, @MainActor AVCapturePhotoCaptureDelegate {
    private let photoOutput = AVCapturePhotoOutput()
    private var isCapturing = false
    private var handler: ((UIImage) -> Void)?
    var parentView: CodeScannerView!
    var codesFound = Set<String>()
    var didFinishScanning = false
    var lastTime = Date(timeIntervalSince1970: 0)
    private let showViewfinder: Bool

    let fallbackVideoCaptureDevice = AVCaptureDevice.default(for: .video)

    init(showViewfinder: Bool = true, parentView: CodeScannerView) {
        self.parentView = parentView
        self.showViewfinder = showViewfinder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        showViewfinder = false
        super.init(coder: coder)
    }

    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!

    private lazy var viewFinder: UIImageView? = {
        guard let image = UIImage(named: "viewfinder") else {
            return nil
        }

        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var manualCaptureButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "capture")
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(self, action: #selector(manualCapturePressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addOrientationDidChangeObserver()
        setBackgroundColor()
        handleCameraPermission()
    }

    override func viewWillLayoutSubviews() {
        previewLayer?.frame = view.layer.bounds
    }

    @objc func updateOrientation() {
        guard let orientation = view.window?.windowScene?.interfaceOrientation else { return }
        guard let connection = captureSession?.connections.last, connection.isVideoOrientationSupported else { return }
        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeLeft
        case .landscapeRight:
            connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            connection.videoOrientation = .portrait
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateOrientation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupSession()
    }

    private func setupSession() {
        guard let captureSession = captureSession else {
            return
        }

        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        }

        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        addviewfinder()

        reset()

        if (captureSession.isRunning == false) {
            DispatchQueue.main.async {
                self.captureSession?.startRunning()
            }
        }
    }

    private func handleCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .restricted:
            break
        case .denied:
            didFail(reason: .permissionDenied)
        case .notDetermined:
            requestCameraAccess {
                self.setupCaptureDevice()
                DispatchQueue.main.async {
                    self.setupSession()
                }
            }
        case .authorized:
            setupCaptureDevice()
            setupSession()

        default:
            break
        }
    }

    private func requestCameraAccess(completion: (@MainActor @Sendable () -> Void)?) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
            Task { @MainActor in
                guard status else {
                    self?.didFail(reason: .permissionDenied)
                    return
                }
                completion?()
            }
        }
    }

    private func addOrientationDidChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOrientation),
            name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
            object: nil
        )
    }

    private func setBackgroundColor(_ color: UIColor = .black) {
        view.backgroundColor = color
    }

    private func setupCaptureDevice() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = parentView.videoCaptureDevice ?? fallbackVideoCaptureDevice else {
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            didFail(reason: .initError(error))
            return
        }

        if (captureSession!.canAddInput(videoInput)) {
            captureSession!.addInput(videoInput)
        } else {
            didFail(reason: .badInput)
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession!.canAddOutput(metadataOutput)) {
            captureSession!.addOutput(metadataOutput)
            captureSession?.addOutput(photoOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = parentView.codeTypes
        } else {
            didFail(reason: .badOutput)
            return
        }
    }

    private func addviewfinder() {
        guard
            showViewfinder,
            let imageView = viewFinder
        else {
            return
        }

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if (captureSession?.isRunning == true) {
            DispatchQueue.main.async {
                self.captureSession?.stopRunning()
            }
        }

        NotificationCenter.default.removeObserver(self)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    /** Touch the screen for autofocus */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first?.view == view,
              let touchPoint = touches.first,
              let device = parentView.videoCaptureDevice ?? fallbackVideoCaptureDevice,
              device.isFocusPointOfInterestSupported
        else { return }

        let videoView = view
        let screenSize = videoView!.bounds.size
        let xPoint = touchPoint.location(in: videoView).y / screenSize.height
        let yPoint = 1.0 - touchPoint.location(in: videoView).x / screenSize.width
        let focusPoint = CGPoint(x: xPoint, y: yPoint)

        do {
            try device.lockForConfiguration()
        } catch {
            return
        }

        // Focus to the correct point, make continiuous focus and exposure so the point stays sharp when moving the device closer
        device.focusPointOfInterest = focusPoint
        device.focusMode = .continuousAutoFocus
        device.exposurePointOfInterest = focusPoint
        device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        device.unlockForConfiguration()
    }

    @objc func manualCapturePressed(_ sender: Any?) {
        readyManualCapture()
    }

    func showManualCaptureButton(_ isManualCapture: Bool) {
        if manualCaptureButton.superview == nil {
            view.addSubview(manualCaptureButton)
            NSLayoutConstraint.activate([
                manualCaptureButton.heightAnchor.constraint(equalToConstant: 60),
                manualCaptureButton.widthAnchor.constraint(equalTo: manualCaptureButton.heightAnchor),
                view.centerXAnchor.constraint(equalTo: manualCaptureButton.centerXAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: manualCaptureButton.bottomAnchor, constant: 32)
            ])
        }

        view.bringSubviewToFront(manualCaptureButton)
        manualCaptureButton.isHidden = !isManualCapture
    }

    func updateViewController(
        isTorchOn: Bool,
        isManualCapture: Bool,
        isManualSelect: Bool
    ) {
        guard let videoCaptureDevice = parentView.videoCaptureDevice ?? fallbackVideoCaptureDevice else {
            return
        }

        if videoCaptureDevice.hasTorch {
            try? videoCaptureDevice.lockForConfiguration()
            videoCaptureDevice.torchMode = isTorchOn ? .on : .off
            videoCaptureDevice.unlockForConfiguration()
        }

        #if !targetEnvironment(simulator)
        showManualCaptureButton(isManualCapture)
        #endif
    }

    func reset() {
        codesFound.removeAll()
        didFinishScanning = false
        lastTime = Date(timeIntervalSince1970: 0)
    }

    func readyManualCapture() {
        guard parentView.scanMode == .manual else { return }
        reset()
        lastTime = Date()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            guard didFinishScanning == false else { return }

            let photoSettings = AVCapturePhotoSettings()
            guard !isCapturing else { return }
            isCapturing = true

            handler = { [self] image in
                let result = ScanResult(
                    string: stringValue,
                    type: readableObject.type,
                    image: image,
                    corners: readableObject.corners
                )

                switch parentView.scanMode {
                case .once:
                    found(result)
                    // make sure we only trigger scan once per use
                    didFinishScanning = true

                case .manual:
                    if !didFinishScanning, isWithinManualCaptureInterval() {
                        found(result)
                        didFinishScanning = true
                    }

                case .oncePerCode:
                    if !codesFound.contains(stringValue) {
                        codesFound.insert(stringValue)
                        found(result)
                    }

                case .continuous:
                    if isPastScanInterval() {
                        found(result)
                    }
                }
            }
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    func isPastScanInterval() -> Bool {
        Date().timeIntervalSince(lastTime) >= parentView.scanInterval
    }

    func isWithinManualCaptureInterval() -> Bool {
        Date().timeIntervalSince(lastTime) <= 0.5
    }

    func found(_ result: ScanResult) {
        lastTime = Date()

        if parentView.shouldVibrateOnSuccess {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }

        parentView.completion(.success(result))
    }

    func didFail(reason: ScanError) {
        parentView.completion(.failure(reason))
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        isCapturing = false
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.")
            return
        }
        guard let qrImage = UIImage(data: imageData) else {
            print("Unable to generate UIImage from image data.")
            return
        }
        handler?(qrImage)
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        AudioServicesDisposeSystemSoundID(1108)
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        AudioServicesDisposeSystemSoundID(1108)
    }
}

extension AVCaptureDevice {

    /// This returns the Ultra Wide Camera on capable devices and the default Camera for Video otherwise.
    static var bestForVideo: AVCaptureDevice? {
        let deviceHasUltraWideCamera = !AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        ).devices.isEmpty
        return deviceHasUltraWideCamera ? AVCaptureDevice
            .default(.builtInUltraWideCamera, for: .video, position: .back) : AVCaptureDevice.default(for: .video)
    }
}
