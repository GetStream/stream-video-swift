//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Adapts camera capture settings when the device reports system pressure.
///
/// This handler observes ``AVCaptureDevice/systemPressureState`` for the
/// active camera device and applies two kinds of adjustments:
/// - Frame rate throttling based on pressure level.
/// - Resolution scaling by selecting a lower capture size tier.
///
/// The goal is to reduce thermal load and keep capture stable before iOS
/// escalates to more severe thermal actions. Changes are debounced so brief
/// spikes do not cause rapid quality oscillation.
///
/// This handler is only used with the new capturing pipeline and depends on a
/// dispatcher to re-issue capture-quality updates back through
/// ``StreamVideoCapturer``.
final class CameraSystemPressureHandler:
    StreamVideoCapturerActionHandler,
    @unchecked Sendable {

    /// Represents a coarse quality bucket used to scale resolution.
    ///
    /// Higher raw values indicate lower quality. This ordering lets the handler
    /// decide whether it is upgrading or downgrading quality based on pressure.
    private enum QualityTier: Int, Comparable {
        case base = 0
        case medium = 1
        case low = 2

        static func < (lhs: QualityTier, rhs: QualityTier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Tunables for FPS throttling and debounce delays.
    ///
    /// Values are intentionally conservative to avoid oscillation while still
    /// relieving thermal pressure quickly.
    private enum PressurePolicy {
        static let fairMaxFPS = 24
        static let seriousMaxFPS = 15
        static let criticalMaxFPS = 10
        static let shutdownMaxFPS = 5

        static let downgradeDelay: TimeInterval = 3.0
        static let criticalDowngradeDelay: TimeInterval = 1.0
        static let upgradeDelay: TimeInterval = 10.0
    }

    /// Serial queue used to process pressure updates and debounce work.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// Subscription for `systemPressureState` changes.
    private var systemPressureCancellable: AnyCancellable?
    /// Current device whose pressure state is being observed.
    private weak var currentDevice: (any SystemPressureCaptureDevice)?
    /// Target frame rate configured by the capture pipeline.
    private var configuredFrameRate: Int = 30
    /// The last frame rate successfully applied to the device.
    private var appliedFrameRate: Int?
    /// Last reported system pressure level.
    private var currentPressureLevel:
        AVCaptureDevice.SystemPressureState.Level = .nominal
    /// Current quality tier derived from pressure.
    private var currentQualityTier: QualityTier = .base
    /// Baseline capture dimensions set by external configuration.
    private var baselineCaptureDimensions: CGSize?
    /// Dimensions currently applied because of pressure changes.
    private var appliedCaptureDimensions: CGSize?
    /// Pending debounced tier adjustment.
    private var pendingQualityWorkItem: Task<Void, Never>?

    @Injected(\.systemPressureCaptureDeviceProvider)
    private var systemPressureCaptureDeviceProvider

    /// Dispatches derived actions back through the capturer pipeline.
    ///
    /// This is used to send ``StreamVideoCapturer.Action/updateCaptureQuality``
    /// when pressure-based adjustments require a new capture configuration.
    /// The dispatcher is assigned by ``StreamVideoCapturer`` when the new
    /// capture pipeline is enabled.
    var actionDispatcher: ((StreamVideoCapturer.Action) async -> Void)?
    /// Retains capture objects required to dispatch quality updates.
    private struct CaptureContext: @unchecked Sendable {
        var videoSource: RTCVideoSource
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    private var captureContext: CaptureContext?

    // MARK: - StreamVideoCapturerActionHandler

    /// Responds to capture lifecycle and quality updates to keep pressure
    /// adjustments in sync with the active camera device.
    ///
    /// The handler listens for:
    /// - ``StreamVideoCapturer.Action/startCapture`` to bind pressure events.
    /// - ``StreamVideoCapturer.Action/setCameraPosition`` to re-bind devices.
    /// - ``StreamVideoCapturer.Action/updateCaptureQuality`` to track external
    ///   quality changes and set the baseline tier.
    /// - ``StreamVideoCapturer.Action/stopCapture`` to tear down observers.
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
            let captureContext = CaptureContext(
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

            try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard
                    let self,
                    let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer
                else {
                    return
                }
                configuredFrameRate = frameRate
                self.captureContext = captureContext
                updateBaselineDimensions(dimensions)
                bindSystemPressure(for: cameraCapturer, position: position)
                refreshQualityTier(immediate: true)
            }

        case let .setCameraPosition(
            position,
            videoSource,
            videoCapturer,
            videoCapturerDelegate
        ):
            let captureContext = CaptureContext(
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

            try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard
                    let self,
                    let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer
                else {
                    return
                }
                self.captureContext = captureContext
                // Preserve the current quality tier when switching devices.
                bindSystemPressure(for: cameraCapturer, position: position)
                refreshQualityTier(immediate: true)
            }
        case let .updateCaptureQuality(dimensions, device, _, _, _, reason):
            try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard
                    let self
                else {
                    return
                }

                if reason == .external {
                    updateBaselineDimensions(dimensions)
                    refreshQualityTier(immediate: true)
                }
                if currentDevice == nil {
                    bindSystemPressure(for: device as? SystemPressureCaptureDevice)
                }
            }

        case .stopCapture:
            try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard
                    let self
                else {
                    return
                }
                reset()
            }
        default:
            break
        }
    }

    // MARK: - Private

    /// Binds pressure observation to the active capture device or a fallback.
    private func bindSystemPressure(
        for cameraCapturer: RTCCameraVideoCapturer,
        position: AVCaptureDevice.Position
    ) {
        let device = systemPressureCaptureDeviceProvider.device(
            for: cameraCapturer,
            position: position
        )
        bindSystemPressure(for: device)
    }

    /// Starts observing `systemPressureState` for the supplied device.
    ///
    /// Existing subscriptions are cancelled so only one device is observed
    /// at a time.
    private func bindSystemPressure(for device: SystemPressureCaptureDevice?) {
        guard let device else { return }
        currentDevice = device
        systemPressureCancellable?.cancel()
        let deviceIdentifier = ObjectIdentifier(device)
        systemPressureCancellable = device
            .systemPressureLevelPublisher
            .receive(on: processingQueue)
            .sink { [weak self] level in
                guard
                    let self,
                    let currentDevice = self.currentDevice,
                    ObjectIdentifier(currentDevice) == deviceIdentifier
                else {
                    return
                }
                self.handleSystemPressureLevel(level, device: currentDevice)
            }
    }

    /// Stores the baseline dimensions and clears applied overrides.
    private func updateBaselineDimensions(_ dimensions: CGSize) {
        baselineCaptureDimensions = dimensions
        appliedCaptureDimensions = nil
    }

    /// Clears all state and cancels pending work when capture stops.
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

    /// Applies pressure-driven adjustments for a single pressure event.
    ///
    /// This recomputes the target FPS, applies it if needed, and schedules
    /// a resolution tier change if pressure has shifted.
    private func handleSystemPressureLevel(
        _ level: AVCaptureDevice.SystemPressureState.Level,
        device: SystemPressureCaptureDevice
    ) {
        currentPressureLevel = level
        let targetFPS = targetFrameRate(for: level, device: device)
        applyFrameRate(targetFPS, on: device)
        refreshQualityTier(immediate: false)
    }

    /// Computes the preferred FPS for a given pressure level.
    ///
    /// The result is clamped to the active format's supported range.
    private func targetFrameRate(
        for level: AVCaptureDevice.SystemPressureState.Level,
        device: SystemPressureCaptureDevice
    ) -> Int {
        let base = configuredFrameRate
        let range = device.activeFormatFrameRateRange

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

    /// Schedules a resolution tier change when pressure level changes.
    ///
    /// Upgrades are delayed longer than downgrades to avoid flapping.
    private func refreshQualityTier(immediate: Bool) {
        guard baselineCaptureDimensions != nil else { return }

        let targetTier = qualityTier(for: currentPressureLevel)
        guard targetTier != currentQualityTier else { return }

        pendingQualityWorkItem?.cancel()
        let delay = delayForTierChange(to: targetTier, immediate: immediate)

        pendingQualityWorkItem = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                self?.processingQueue.addOperation { [weak self] in
                    guard let self else { return }
                    self.currentQualityTier = targetTier
                    self.applyPreferredCaptureDimensions()
                }
            }
        }
    }

    /// Returns the debounce delay for a requested tier transition.
    private func delayForTierChange(
        to targetTier: QualityTier,
        immediate: Bool
    ) -> TimeInterval {
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

    /// Maps system pressure levels into a coarse quality tier.
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

    /// Applies the preferred dimensions for the current tier.
    ///
    /// This dispatches a capture-quality update back through the pipeline.
    private func applyPreferredCaptureDimensions() {
        guard let baselineCaptureDimensions else { return }

        let targetDimensions = dimensions(
            for: currentQualityTier,
            baseline: baselineCaptureDimensions
        )

        guard targetDimensions != appliedCaptureDimensions else { return }
        appliedCaptureDimensions = targetDimensions
        log.debug(
            "System pressure updated capture dimensions to " +
                "\(targetDimensions).",
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

    /// Calculates the target dimensions for the supplied tier.
    ///
    /// Output dimensions are forced to even values to satisfy common
    /// encoder requirements.
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

    /// Applies the target FPS on the active device if it changed.
    ///
    /// The value is expressed as a fixed frame duration to ensure stable
    /// cadence.
    private func applyFrameRate(
        _ targetFPS: Int,
        on device: SystemPressureCaptureDevice
    ) {
        guard targetFPS > 0 else { return }
        guard appliedFrameRate != targetFPS else { return }

        do {
            try device.applyFixedFrameRate(targetFPS)
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
