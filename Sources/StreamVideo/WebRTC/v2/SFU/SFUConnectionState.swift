//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The connection state of the SFU signaling WebSocket, as exposed to the
/// WebRTC state machine.
///
/// The SFU WebSocket is served by `StreamCore.WebSocketClient` (see
/// `SFUWebSocket`). This video-side enum keeps StreamCore's connection-state
/// type out of the WebRTC state machine (which uses many StreamVideo types and
/// therefore cannot import StreamCore). `SFUWebSocket` maps
/// `StreamCore.WebSocketConnectionState` into this type at the boundary.
///
/// - TODO: [StreamCore migration] This boundary enum exists so the WebRTC state
///   machine stays StreamCore-free. Once the leaf types are unified and the SFU
///   wrapper is retired, consumers could use `StreamCore.WebSocketConnectionState`
///   directly and this type can be removed.
enum SFUConnectionState: Equatable {
    /// Describes the source of a disconnection.
    enum DisconnectionSource: Equatable {
        case userInitiated
        case serverInitiated(error: Error?)
        case systemInitiated
        case noPongReceived
        case timeout

        /// The underlying error when the disconnection was server-initiated.
        var serverError: Error? {
            guard case let .serverInitiated(error) = self else { return nil }
            return error
        }

        // `Error` isn't `Equatable`; compare server errors by type + message
        // (ignoring source location), which mirrors `ClientError`'s equality and
        // is enough for de-duplicating connection-state updates.
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.userInitiated, .userInitiated),
                 (.systemInitiated, .systemInitiated),
                 (.noPongReceived, .noPongReceived),
                 (.timeout, .timeout):
                return true
            case let (.serverInitiated(lhsError), .serverInitiated(rhsError)):
                return Self.describe(lhsError) == Self.describe(rhsError)
            default:
                return false
            }
        }

        private static func describe(_ error: Error?) -> String? {
            guard let error else { return nil }
            if let clientError = error as? ClientError {
                return "\(type(of: clientError)):\(clientError.localizedDescription)"
            }
            return String(describing: error)
        }
    }

    case initialized
    case connecting
    case authenticating
    case connected
    case disconnecting(source: DisconnectionSource)
    case disconnected(source: DisconnectionSource)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
