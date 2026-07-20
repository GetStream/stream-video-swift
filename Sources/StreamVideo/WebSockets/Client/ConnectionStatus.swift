//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// `ConnectionStatus` is just a simplified and friendlier wrapper around `WebSocketConnectionState`.

/// Describes the possible states of the client connection to the servers.
public enum ConnectionStatus: Equatable, Sendable {
    /// The client is initialized but not connected to the remote server yet.
    case initialized
    
    /// The client is disconnected. This is an initial state. Optionally contains an error, if the connection was disconnected
    /// due to an error.
    case disconnected(error: ClientError? = nil)
    
    /// The client is in the process of connecting to the remote servers.
    case connecting
    
    /// The client is connected to the remote server.
    case connected
    
    /// The web socket is disconnecting.
    case disconnecting
}

extension ConnectionStatus {
    init(webSocketConnectionState: WebSocketConnectionState) {
        switch webSocketConnectionState {
        case .initialized:
            self = .initialized
            
        case .connecting, .authenticating:
            self = .connecting
            
        case .connected:
            self = .connected
            
        case .disconnecting:
            self = .disconnecting
            
        case let .disconnected(source):
            let serverError = source.serverError
            let isWaitingForReconnect = webSocketConnectionState.isAutomaticReconnectionEnabled || serverError?
                .isInvalidTokenError == true
            
            self = isWaitingForReconnect ? .connecting : .disconnected(error: serverError?.asVideoClientError)

        @unknown default:
            self = .disconnected()
        }
    }
}

typealias ConnectionId = String

private extension StreamCore.ClientError {
    var asVideoClientError: ClientError {
        ClientError(with: (apiError as Error?) ?? self)
    }
}
