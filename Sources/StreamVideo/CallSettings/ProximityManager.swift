//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Manages proximity-related functionality for a call, including policy management
/// and proximity state observation. Only active on phone devices.
final class ProximityManager: @unchecked Sendable {

    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.currentDevice) private var currentDevice
    @Injected(\.proximityMonitor) private var proximityMonitor

    /// Whether proximity monitoring is supported on the current device
    var isSupported: Bool { currentDevice.deviceType == .phone }

    /// Weak reference to the associated call
    private weak var call: Call?
    /// Thread-safe storage for registered proximity policies
    @Atomic private var policies: [ObjectIdentifier: any ProximityPolicy] = [:]

    /// Cancellable for active call observation
    private var activeCallCancellable: AnyCancellable?
    /// Cancellable for proximity state observation
    private var observationCancellable: AnyCancellable?

    /// Creates a new proximity manager for the specified call
    /// - Parameter call: Call instance to manage proximity for
    init(_ call: Call) {
        self.call = call

        if isSupported {
            activeCallCancellable = streamVideo
                .state
                .$activeCall
                .sinkTask { @MainActor [weak self] in self?.didUpdateActiveCall($0) }
        }
    }

    deinit {
        activeCallCancellable?.cancel()
        observationCancellable?.cancel()
    }

    // MARK: - Policies

    /// Adds a proximity policy to be managed by this instance
    /// - Parameter policy: Policy to add
    /// - Throws: ClientError if call is nil
    func add(_ policy: any ProximityPolicy) throws {
        guard isSupported else { return }

        guard let call else {
            throw ClientError("ProximityPolicy identifier:\(policy) cannot be attached while Call is nil.")
        }
        policies[type(of: policy).identifier] = policy
        log.info("ProximityPolicy identifier:\(policy) has been attached on Call id:\(call.callId) type:\(call.callType).")
    }

    /// Removes a proximity policy from management
    /// - Parameter policy: Policy to remove
    func remove(_ policy: any ProximityPolicy) {
        guard isSupported else { return }

        policies[type(of: policy).identifier] = nil

        guard let call else {
            return
        }
        log.info("ProximityPolicy identifier:\(policy) has been removed from Call id:\(call.callId) type:\(call.callType).")
    }

    // MARK: - Private Helpers

    /// Handles active call changes by starting/stopping proximity observation
    /// - Parameter activeCall: New active call or nil if no active call
    @MainActor
    private func didUpdateActiveCall(_ activeCall: Call?) {
        if
            let activeCall,
            call?.cId == activeCall.cId,
            policies.isEmpty == false,
            observationCancellable == nil {
            proximityMonitor.startObservation()
            observationCancellable = proximityMonitor
                .statePublisher
                .removeDuplicates()
                .sink { [weak self] in self?.didUpdateProximity($0) }
            log.info("Proximity observation has started.")
        } else if
            activeCall == nil,
            observationCancellable != nil {
            observationCancellable?.cancel()
            observationCancellable = nil
            proximityMonitor.stopObservation()
            log.info("Proximity observation has stopped.")
        } else {
            /* No-op */
        }
    }

    /// Notifies all registered policies of a proximity state change
    /// - Parameter proximity: New proximity state
    private func didUpdateProximity(_ proximity: ProximityState) {
        guard let call else {
            return
        }

        for policy in policies {
            policy.value.didUpdateProximity(proximity, on: call)
        }
    }
}
