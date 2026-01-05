//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreImage
import Foundation
import StreamVideo
import UIKit

final class LocalParticipantSnapshotViewModel: NSObject, AVCapturePhotoCaptureDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private actor State {
        private(set) var isCapturingVideoFrame = false
        private(set) var zoomFactor: Float = 1
        
        func setIsCapturingVideoFrame(_ value: Bool) {
            isCapturingVideoFrame = value
        }
        
        func setZoomFactor(_ value: Float) {
            zoomFactor = value
        }
    }
    
    private lazy var photoOutput: AVCapturePhotoOutput = .init()
    private lazy var videoOutput: AVCaptureVideoDataOutput = .init()
    private var state = State()
    
    weak var call: Call? {
        didSet {
            guard call?.cId != oldValue?.cId else { return }
            Task {
                do {
                    #if !targetEnvironment(simulator)
                    if #available(iOS 16.0, *) {
                        try await call?.addVideoOutput(videoOutput)
                        /// Following Apple guidelines for videoOutputs from here:
                        /// https://developer.apple.com/library/archive/technotes/tn2445/_index.html
                        videoOutput.alwaysDiscardsLateVideoFrames = true
                    } else {
                        try await call?.addCapturePhotoOutput(photoOutput)
                    }
                    #endif
                } catch {
                    log.error("Failed to setup for localParticipant snapshot", error: error)
                }
            }
        }
    }
    
    func capturePhoto() {
        guard !photoOutput.connections.isEmpty else { return }
        photoOutput.capturePhoto(with: .init(), delegate: self)
    }
    
    func captureVideoFrame() {
        guard !videoOutput.connections.isEmpty else { return }
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue.global(qos: .background)
        )
        Task { await state.setIsCapturingVideoFrame(true) }
    }
    
    func zoom() {
        Task {
            do {
                if await state.zoomFactor > 1 {
                    await state.setZoomFactor(1)
                    try await call?.zoom(by: 1)
                } else {
                    await state.setZoomFactor(1.5)
                    try await call?.zoom(by: 1.5)
                }
            } catch {
                log.error(error)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func sendImageData(_ data: Data) async {
        defer { videoOutput.setSampleBufferDelegate(nil, queue: nil) }
        guard
            let snapshot = UIImage(data: data),
            let resizedImage = resize(image: snapshot, to: .init(width: 30, height: 30)),
            let snapshotData = resizedImage.jpegData(compressionQuality: 0.8)
        else {
            return
        }
        
        do {
            try await call?.sendCustomEvent([
                "snapshot": .string(snapshotData.base64EncodedString())
            ])
        } catch {
            log.error("Failed to send image.", error: error)
        }
    }
    
    private func resize(
        image: UIImage,
        to targetSize: CGSize
    ) -> UIImage? {
        guard
            image.size.width > targetSize.width || image.size.height > targetSize.height
        else {
            return image
        }
        
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Determine the scale factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledWidth = image.size.width * scaleFactor
        let scaledHeight = image.size.height * scaleFactor
        let targetRect = CGRect(
            x: (targetSize.width - scaledWidth) / 2,
            y: (targetSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )
        
        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        image.draw(in: targetRect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            log.error("Failed to capture photo.", error: error)
        } else {
            if let data = photo.fileDataRepresentation() {
                Task { await sendImageData(data) }
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task {
            guard await state.isCapturingVideoFrame else { return }
            
            if let imageBuffer = sampleBuffer.imageBuffer {
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                if let data = UIImage(ciImage: ciImage).jpegData(compressionQuality: 1) {
                    await sendImageData(data)
                }
            }
            
            await state.setIsCapturingVideoFrame(false)
        }
    }
}

/// Provides the default value of the `LocalParticipantSnapshotViewModel` class.
struct LocalParticipantSnapshotViewModelKey: InjectionKey {
    @MainActor
    static var currentValue: LocalParticipantSnapshotViewModel = .init()
}

extension InjectedValues {
    /// Provides access to the `LocalParticipantSnapshotViewModel` class to the views and view models.
    var localParticipantSnapshotViewModel: LocalParticipantSnapshotViewModel {
        get {
            Self[LocalParticipantSnapshotViewModelKey.self]
        }
        set {
            Self[LocalParticipantSnapshotViewModelKey.self] = newValue
        }
    }
}
