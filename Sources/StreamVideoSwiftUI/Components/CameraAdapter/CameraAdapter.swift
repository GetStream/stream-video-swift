//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreImage
import Foundation
import StreamVideo

final class CameraAdapter: NSObject, @unchecked Sendable {
    @Injected(\.captureDeviceProvider) private var captureDeviceProvider
    @Injected(\.orientationAdapter) private var orientationAdapter

    @Published private(set) var image: CIImage?

    private var cameraPosition: CameraPosition
    private var input: AVCaptureDeviceInput?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let frameProcessingQueue = DispatchQueue(label: "frame.processing.queue")
    private let accessQueue: UnfairQueue = .init()
    private let disposableBag = DisposableBag()

    init(cameraPosition: CameraPosition) {
        self.cameraPosition = cameraPosition
        super.init()

        orientationAdapter
            .$orientation
            .map(\.captureVideoOrientation)
            .sink { [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)
    }

    deinit {
        stop()
    }

    func start() async {
        guard
            await requestAccessIfRequired()
        else {
            return
        }
        configureCaptureSession()
    }

    func stop() {
        accessQueue.sync {
            guard
                captureSession.isRunning
            else {
                return
            }
            captureSession.beginConfiguration()
            image = nil
            if let input {
                captureSession.removeInput(input)
            }
            input = nil
            captureSession.removeOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(nil, queue: nil)

            captureSession.commitConfiguration()
            captureSession.stopRunning()
        }
    }

    func updateCameraPosition(_ cameraPosition: CameraPosition) async {
        guard
            cameraPosition != self.cameraPosition
        else {
            return
        }
        stop()
        self.cameraPosition = cameraPosition
        await start()
    }

    // MARK: - Private Helpers

    private func configureCaptureSession() {
        accessQueue.sync {
            guard
                !captureSession.isRunning,
                let device = captureDeviceProvider.device(for: cameraPosition) as? AVCaptureDevice,
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                return
            }
            captureSession.beginConfiguration()
            self.input = input

            captureSession.sessionPreset = AVCaptureSession.Preset.medium
            videoOutput.setSampleBufferDelegate(self, queue: frameProcessingQueue)

            captureSession.addInput(input)
            captureSession.addOutput(videoOutput)

            if
                let videoOutputConnection = videoOutput.connection(with: .video),
                videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored = cameraPosition == .front
            }

            captureSession.commitConfiguration()

            didUpdate(orientationAdapter.orientation.captureVideoOrientation)
            captureSession.startRunning()
        }
    }

    private func requestAccessIfRequired() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            let status = await AVCaptureDevice.requestAccess(for: .video)
            return status
        case .denied:
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func didUpdate(_ orientation: AVCaptureVideoOrientation) {
        guard
            let connection = videoOutput.connection(with: .video),
            connection.videoOrientation != orientation
        else {
            return
        }

        connection.videoOrientation = orientation
    }
}

extension CameraAdapter: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        Task { @MainActor in self.image = image }
    }
}
