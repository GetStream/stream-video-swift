//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides a method to determine the rejection reason for a call.
public protocol RejectionReasonProviding {

    /// The stream video associated with this provider.
    var streamVideo: StreamVideo? { get set }

    /// Determines the rejection reason for a call with the specified call ID.
    ///
    /// - Parameter callCid: The call ID to evaluate.
    /// - Returns: A string representing the rejection reason, or `nil` if there is no reason to reject
    /// the call.
    func rejectionReason(for callCid: String) -> String?
}

/// A provider that determines the rejection reason for a call based on its state.
final class StreamRejectionReasonProvider: RejectionReasonProviding {

    /// The stream video associated with this provider.
    var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// The currently active call, if any.
    private weak var activeCall: Call?

    /// The currently ringing call, if any.
    private weak var ringingCall: Call?

    /// A container for managing cancellable subscriptions.
    private let cancellables: DisposableBag = .init()

    // MARK: - RejectionReasonProviding

    /// Determines the rejection reason for a call with the specified call ID.
    ///
    /// - Parameter callCid: The call ID to evaluate.
    /// - Returns: A string representing the rejection reason, or `nil` if there is no reason to reject
    /// the call.
    func rejectionReason(for callCid: String) -> String? {
        let activeCall = self.activeCall
        let ringingCall = self.ringingCall

        if callCid == activeCall?.cId {
            return nil
        } else if callCid == ringingCall?.cId {
            if activeCall != nil {
                return RejectCallRequest.Reason.busy
            } else {
                return RejectCallRequest.Reason.decline
            }
        } else {
            return nil
        }
    }

    // MARK: - Private helpers

    /// Updates the provider with the new stream video and sets up subscriptions to its state.
    ///
    /// - Parameter streamVideo: The new stream video to associate with this provider.
    private func didUpdate(_ streamVideo: StreamVideo?) {
        cancellables.removeAll()
        guard let streamVideo else { return }

        streamVideo
            .state
            .$activeCall
            .assign(to: \.activeCall, onWeak: self)
            .store(in: cancellables)

        streamVideo
            .state
            .$ringingCall
            .assign(to: \.ringingCall, onWeak: self)
            .store(in: cancellables)
    }
}

enum RejectionReasonProviderKey: InjectionKey {
    static var currentValue: RejectionReasonProviding = StreamRejectionReasonProvider()
}

extension InjectedValues {
    public var rejectionReasonProvider: RejectionReasonProviding {
        get { Self[RejectionReasonProviderKey.self] }
        set { Self[RejectionReasonProviderKey.self] = newValue }
    }
}
