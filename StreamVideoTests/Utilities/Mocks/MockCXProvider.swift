//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

final class MockCXProvider: CXProvider {
    enum Invocation {
        case reportNewIncomingCall(uuid: UUID, update: CXCallUpdate, completion: (Error?) -> Void)
        case reportCall(uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)
        case reportOutgoingCallStartedConnecting(uuid: UUID, date: Date?)
        case reportOutgoingCallConnected(uuid: UUID, date: Date?)
    }

    private(set) var invocations: [Invocation] = []

    convenience init() {
        self.init(configuration: .init(localizedName: "test"))
    }

    override func reportNewIncomingCall(
        with UUID: UUID,
        update: CXCallUpdate,
        completion: @escaping (Error?) -> Void
    ) {
        invocations.append(
            .reportNewIncomingCall(
                uuid: UUID,
                update: update,
                completion: completion
            )
        )
        completion(nil)
    }

    override func reportCall(
        with UUID: UUID,
        endedAt dateEnded: Date?,
        reason endedReason: CXCallEndedReason
    ) {
        invocations.append(
            .reportCall(
                uuid: UUID,
                endedAt: dateEnded,
                reason: endedReason
            )
        )
    }

    override func reportOutgoingCall(
        with UUID: UUID,
        startedConnectingAt dateStartedConnecting: Date?
    ) {
        invocations.append(
            .reportOutgoingCallStartedConnecting(
                uuid: UUID,
                date: dateStartedConnecting
            )
        )
    }

    override func reportOutgoingCall(
        with UUID: UUID,
        connectedAt dateConnected: Date?
    ) {
        invocations.append(
            .reportOutgoingCallConnected(
                uuid: UUID,
                date: dateConnected
            )
        )
    }

    func reset() {
        invocations = []
    }
}
