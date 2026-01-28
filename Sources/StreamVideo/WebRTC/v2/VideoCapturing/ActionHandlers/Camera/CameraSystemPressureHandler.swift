//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

final class CameraSystemPressureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private enum QualityTier: Int, Comparable {
        case base = 0
        case medium = 1
        case low = 2

        static func < (lhs: QualityTier, rhs: QualityTier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private enum PressurePolicy {
        static let fairMaxFPS = 24
        static let seriousMaxFPS = 15
        static let criticalMaxFPS = 10
        static let shutdownMaxFPS = 5

        static let downgradeDelay: TimeInterval = 3.0
        static let criticalDowngradeDelay: TimeInterval = 1.0
        static let upgradeDelay: TimeInterval = 10.0
    }

    private let pressureQueue = DispatchQueue(
        label: "io.getstream.CameraSystemPressureHandler.systemPressure"
    )
    private var systemPressureCancellable: AnyCancellable?
    private weak var currentDevice: AVCaptureDevice?
    private var configuredFrameRate: Int = 30
    private var appliedFrameRate: Int?
    private var currentPressureLevel: AVCaptureDevice.SystemPressureState.Level = .nominal
    private var currentQualityTier: QualityTier = .base
    private var baselineCaptureDimensions: CGSize?
    private var appliedCaptureDimensions: CGSize?
    private var pendingQualityWorkItem: DispatchWorkItem?

    var actionDispatcher: (@Sendable (StreamVideoCapturer.Action) async -> Void)?
    private struct CaptureContext {
        var videoSource: RTCVideoSource
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    private var captureContext: CaptureContext?

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(
            position,
            dimensions,
            frameRate,
            videoSource,
            videoCapturer,
            videoCapturerDelegate,
            _
        ):
            guard let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                return
            }
            configuredFrameRate = frameRate
            captureContext = .init(
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
            updateBaselineDimensions(dimensions)
            bindSystemPressure(for: cameraCapturer, position: position)
            refreshQualityTier(immediate: true)

        case let .setCameraPosition(position, videoSource, videoCapturer, videoCapturerDelegate):
            guard let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                return
            }
            captureContext = .init(
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
            // Preserve the current quality tier when switching devices.
            bindSystemPressure(for: cameraCapturer, position: position)
            refreshQualityTier(immediate: true)

        case let .updateCaptureQuality(dimensions, device, _, _, _, reason):
            if reason == .external {
                updateBaselineDimensions(dimensions)
                refreshQualityTier(immediate: true)
            }
            if currentDevice == nil {
                bindSystemPressure(for: device)
            }

        case .stopCapture:
            reset()
        default:
            break
        }
    }

    // MARK: - Private

    private func bindSystemPressure(
        for cameraCapturer: RTCCameraVideoCapturer,
        position: AVCaptureDevice.Position
    ) {
        if let activeDevice = cameraCapturer.captureSession.activeVideoCaptureDevice {
            bindSystemPressure(for: activeDevice)
        } else {
            bindSystemPressure(for: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position))
        }
    }

    private func bindSystemPressure(for device: AVCaptureDevice?) {
        guard let device else { return }
        currentDevice = device
        systemPressureCancellable?.cancel()
        systemPressureCancellable = device
            .publisher(for: \.systemPressureState, options: [.initial, .new])
            .receive(on: pressureQueue)
            .sink { [weak self, weak device] state in
                guard let self, let device else { return }
                self.handleSystemPressureState(state, device: device)
            }
    }

    private func updateBaselineDimensions(_ dimensions: CGSize) {
        baselineCaptureDimensions = dimensions
        appliedCaptureDimensions = nil
    }

    private func reset() {
        systemPressureCancellable?.cancel()
        systemPressureCancellable = nil
        currentDevice = nil
        appliedFrameRate = nil
        currentPressureLevel = .nominal
        currentQualityTier = .base
        baselineCaptureDimensions = nil
        appliedCaptureDimensions = nil
        pendingQualityWorkItem?.cancel()
        pendingQualityWorkItem = nil
        captureContext = nil
    }

    private func handleSystemPressureState(
        _ state: AVCaptureDevice.SystemPressureState,
        device: AVCaptureDevice
    ) {
        currentPressureLevel = state.level
        let targetFPS = targetFrameRate(for: state.level, device: device)
        applyFrameRate(targetFPS, on: device)
        refreshQualityTier(immediate: false)
    }

    private func targetFrameRate(
        for level: AVCaptureDevice.SystemPressureState.Level,
        device: AVCaptureDevice
    ) -> Int {
        let base = configuredFrameRate
        let range = device.activeFormat.frameRateRange

        let unclampedTarget: Int
        switch level {
        case .nominal:
            unclampedTarget = base
        case .fair:
            unclampedTarget = min(base, PressurePolicy.fairMaxFPS)
        case .serious:
            unclampedTarget = min(base, PressurePolicy.seriousMaxFPS)
        case .critical:
            unclampedTarget = min(base, PressurePolicy.criticalMaxFPS)
        case .shutdown:
            unclampedTarget = min(base, PressurePolicy.shutdownMaxFPS)
        default:
            unclampedTarget = base
        }

        return unclampedTarget.clamped(to: range)
    }

    private func refreshQualityTier(immediate: Bool) {
        guard baselineCaptureDimensions != nil else { return }

        let targetTier = qualityTier(for: currentPressureLevel)
        guard targetTier != currentQualityTier else { return }

        pendingQualityWorkItem?.cancel()
        let delay = delayForTierChange(to: targetTier, immediate: immediate)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.currentQualityTier = targetTier
            self.applyPreferredCaptureDimensions()
        }
        pendingQualityWorkItem = workItem
        pressureQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func delayForTierChange(to targetTier: QualityTier, immediate: Bool) -> TimeInterval {
        if immediate { return 0 }
        if targetTier > currentQualityTier {
            switch currentPressureLevel {
            case .critical, .shutdown:
                return PressurePolicy.criticalDowngradeDelay
            default:
                return PressurePolicy.downgradeDelay
            }
        } else {
            return PressurePolicy.upgradeDelay
        }
    }

    private func qualityTier(
        for level: AVCaptureDevice.SystemPressureState.Level
    ) -> QualityTier {
        switch level {
        case .nominal, .fair:
            return .base
        case .serious:
            return .medium
        case .critical, .shutdown:
            return .low
        default:
            return .base
        }
    }

    private func applyPreferredCaptureDimensions() {
        guard let baselineCaptureDimensions else { return }

        let targetDimensions = dimensions(
            for: currentQualityTier,
            baseline: baselineCaptureDimensions
        )

        guard targetDimensions != appliedCaptureDimensions else { return }
        appliedCaptureDimensions = targetDimensions
        log.debug(
            "System pressure updated capture dimensions to \(targetDimensions).",
            subsystems: .videoCapturer
        )
        guard let captureContext, let currentDevice else { return }
        guard let actionDispatcher else { return }
        let action: StreamVideoCapturer.Action = .updateCaptureQuality(
            dimensions: targetDimensions,
            device: currentDevice,
            videoSource: captureContext.videoSource,
            videoCapturer: captureContext.videoCapturer,
            videoCapturerDelegate: captureContext.videoCapturerDelegate,
            reason: .systemPressure
        )
        Task {
            await actionDispatcher(action)
        }
    }

    private func dimensions(
        for tier: QualityTier,
        baseline: CGSize
    ) -> CGSize {
        let scale: CGFloat
        switch tier {
        case .base:
            scale = 1.0
        case .medium:
            scale = 0.75
        case .low:
            scale = 0.5
        }

        let width = Int(baseline.width * scale)
        let height = Int(baseline.height * scale)

        return CGSize(
            width: max(2, width & ~1),
            height: max(2, height & ~1)
        )
    }

    private func applyFrameRate(
        _ targetFPS: Int,
        on device: AVCaptureDevice
    ) {
        guard targetFPS > 0 else { return }
        guard appliedFrameRate != targetFPS else { return }

        do {
            try device.lockForConfiguration()
            let duration = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
            appliedFrameRate = targetFPS
            log.debug(
                "System pressure updated capture FPS to \(targetFPS).",
                subsystems: .videoCapturer
            )
        } catch {
            log.error(
                "Failed to update capture FPS under system pressure: \(error).",
                subsystems: .videoCapturer
            )
        }
    }
}
