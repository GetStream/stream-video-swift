//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the failure attached to a `completed` event with
/// `outcome == .failure`.
///
/// A failure carries a `code` and a human-readable `reason`. When the failure
/// originates on the client, the `code` is one of ``ClientEventFailureCode``.
/// When the failure originates on the backend, the backend error code is sent
/// instead, per the spec ("Send the client-side code if the failure originated
/// on the client; otherwise send the backend error.").
struct ClientEventFailure: Sendable, Equatable {
    /// The failure code string sent in `retry_failure_code`.
    let code: String
    /// The failure reason string sent in `retry_failure_reason`.
    let reason: String

    /// Creates a failure from a known client-side failure code.
    init(code: ClientEventFailureCode, reason: String? = nil) {
        self.code = code.rawValue
        self.reason = reason ?? code.defaultReason
    }

    /// Creates a failure with an explicit code and reason.
    init(code: String, reason: String) {
        self.code = code
        self.reason = reason
    }

    /// Maps an arbitrary error thrown during a join stage to a failure.
    ///
    /// Client-originated errors (cancellation, timeouts, offline) map to the
    /// standard ``ClientEventFailureCode`` values. Backend errors keep their
    /// own code and message.
    init(_ error: Error) {
        if error is CancellationError {
            self.init(code: .clientAborted)
        } else if error is TimeOutError {
            self.init(code: .requestTimeout, reason: error.localizedDescription)
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                self.init(code: .requestTimeout, reason: urlError.localizedDescription)
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed,
                 .cannotConnectToHost,
                 .cannotFindHost:
                self.init(code: .networkOffline, reason: urlError.localizedDescription)
            default:
                self.init(
                    code: "\(urlError.errorCode)",
                    reason: urlError.localizedDescription
                )
            }
        } else if let apiError = error as? APIError {
            self.init(code: "\(apiError.code)", reason: apiError.message)
        } else {
            self.init(
                code: "\((error as NSError).code)",
                reason: error.localizedDescription
            )
        }
    }
}

extension ClientEventFailureCode {
    /// Example reason text used when a caller does not provide one.
    var defaultReason: String {
        switch self {
        case .clientAborted:
            return "Aborted: user left during retry"
        case .requestTimeout:
            return "Timed out"
        case .networkOffline:
            return "Device offline"
        case .iceConnectivityFailed:
            return "ICE connectivity failed"
        case .dtlsConnectivityFailed:
            return "DTLS connectivity failed"
        case .backendLeave:
            return "Backend leave received during join"
        }
    }
}
