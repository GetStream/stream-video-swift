//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enumeration that describes the source from which a call was joined.
///
/// Use `JoinSource` to indicate whether the join action originated from within
/// the app's own UI or through a system-level interface such as CallKit.
/// This helps distinguish the user's entry point and can be used to customize
/// behavior or analytics based on how the call was initiated.
enum JoinSource: Sendable, Equatable {
    /// Carries the completion hook CallKit expects us to invoke once the call
    /// has been joined successfully.
    ///
    /// `CallKitService` stores it on `CallState.joinSource` when the user
    /// answers an incoming call, before the join flow starts. The Call state
    /// machine's joining stage invokes it right after the joined call becomes
    /// the active call (including any join interceptor delay). Completing it
    /// fulfils the pending `CXAnswerCallAction`, which lets CallKit hand
    /// audio session ownership to the app and switches the system call UI
    /// from connecting to a running call duration. It is never invoked on
    /// join failure paths; those complete the action through
    /// `CallKitService`'s error handling.
    struct ActionCompletion: @unchecked Sendable {
        fileprivate let identifier: UUID = .init()
        private let completion: () -> Void

        init(_ completion: @escaping () -> Void) {
            self.completion = completion
        }

        /// Invokes the stored completion callback.
        func complete() {
            completion()
        }
    }

    /// Indicates that the call was joined from within the app's UI.
    case inApp

    /// Indicates that the call was joined via CallKit integration.
    ///
    /// The associated `ActionCompletion` fulfils the pending answer action
    /// and is invoked by the joining stage once the call has joined.
    case callKit(ActionCompletion)

    /// Compares `JoinSource` values while treating CallKit sources as distinct
    /// whenever they wrap different completion hooks.
    static func == (lhs: JoinSource, rhs: JoinSource) -> Bool {
        switch (lhs, rhs) {
        case (.inApp, .inApp):
            return true
        case (.callKit(let lhs), .callKit(let rhs)):
            return lhs.identifier == rhs.identifier
        default:
            return false
        }
    }
}
