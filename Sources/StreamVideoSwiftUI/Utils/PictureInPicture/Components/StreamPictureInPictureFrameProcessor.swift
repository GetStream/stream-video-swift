//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamPictureInPictureFrameProcessor {

    struct ProcessedFrame {
        var buffer: CMSampleBuffer
        var trackSize: CGSize
    }

    private var contentSizeCancellable: AnyCancellable?

    private var contentSize: CGSize = .zero

    /// The transformer used to transform and downsample a RTCVideoFrame's buffer.
    private var bufferTransformer = StreamBufferTransformer()

    /// The track's size.
    private var trackSize: CGSize = .zero {
        didSet {
            guard trackSize != oldValue else { return }
            didUpdateTrackSize()
        }
    }

    /// A property that defines if the RTCVideoFrame instances that will be rendered need to be resized
    /// to fid the view's contentSize.
    private var requiresResize = false {
        didSet { bufferTransformer.requiresResize = requiresResize }
    }

    // As we are operate in smaller rendering bounds we skip frames depending on this property's value
    /// to improve performance.
    /// - Note: The number of frames to skip is being calculated based on the ``trackSize`` and
    /// ``contentSize``. It takes into account also the ``sizeRatioThreshold``
    private var noOfFramesToSkipAfterRendering = 1

    /// The number of frames that we have skipped so far. This is used as a step counter in the
    /// ``renderFrame(_:)``.
    private var skippedFrames = 0

    /// We render frames every time the stepper/counter value is 0 and have a valid trackSize.
    private var shouldRenderFrame: Bool { skippedFrames == 0 && trackSize != .zero }

    /// A size ratio threshold used to determine if resizing is required.
    /// - Note: It seems that Picture-in-Picture doesn't like rendering frames that are bigger than its
    /// window size. For this reason, we are setting the resizeThreshold to `1`.
    private let resizeRequiredSizeRatioThreshold: CGFloat = 1

    /// A size ratio threshold used to determine if skipping frames is required.
    private let sizeRatioThreshold: CGFloat = 15

    init(dataPipeline: PictureInPictureDataPipeline) {
        contentSizeCancellable = dataPipeline
            .sizeEventPublisher
            .compactMap {
                switch $0 {
                case let .contentSizeUpdated(size):
                    return size
                default:
                    return nil
                }
            }
            .assign(to: \.contentSize, on: self)
    }

    // MARK: - Reset

    func reset() {
        noOfFramesToSkipAfterRendering = 0
        skippedFrames = 0
        requiresResize = false
    }

    // MARK: - Processing

    func process(
        _ frame: RTCVideoFrame?
    ) -> ProcessedFrame? {
        guard let frame = frame else {
            return nil
        }

        // Update the trackSize and re-calculate rendering properties if the size
        // has changed.
        trackSize = .init(width: Int(frame.width), height: Int(frame.height))

        defer {
            handleFrameSkippingIfRequired()
        }

        guard shouldRenderFrame else {
            return nil
        }

        if
            let yuvBuffer = bufferTransformer.transformAndResizeIfRequired(frame, targetSize: contentSize)?
            .buffer as? StreamRTCYUVBuffer,
            let sampleBuffer = yuvBuffer.sampleBuffer {
            return .init(buffer: sampleBuffer, trackSize: trackSize)
        } else {
            log.warning("Failed to convert \(type(of: frame.buffer)) CMSampleBuffer.")
            return nil
        }
    }

    // MARK: - Private Helpers

    /// A method used to handle the frameSkipping(step) during frame consumption.
    private func handleFrameSkippingIfRequired() {
        if noOfFramesToSkipAfterRendering > 0 {
            if skippedFrames == noOfFramesToSkipAfterRendering {
                skippedFrames = 0
            } else {
                skippedFrames += 1
            }
        } else if skippedFrames > 0 {
            skippedFrames = 0
        }
    }

    /// A method used to calculate rendering required properties, every time the trackSize changes.
    private func didUpdateTrackSize() {
        guard contentSize != .zero, trackSize != .zero else { return }

        let widthDiffRatio = trackSize.width / contentSize.width
        let heightDiffRatio = trackSize.height / contentSize.height
        requiresResize = widthDiffRatio >= resizeRequiredSizeRatioThreshold || heightDiffRatio >= resizeRequiredSizeRatioThreshold
        let requiresFramesSkipping = widthDiffRatio >= sizeRatioThreshold || heightDiffRatio >= sizeRatioThreshold

        /// Skipping frames is decided based on how much bigger is the incoming frame's size compared
        /// to PiP window's size.
        noOfFramesToSkipAfterRendering = requiresFramesSkipping ? max(Int(max(Int(widthDiffRatio), Int(heightDiffRatio)) / 2), 1) :
            0
        skippedFrames = 0
    }
}
