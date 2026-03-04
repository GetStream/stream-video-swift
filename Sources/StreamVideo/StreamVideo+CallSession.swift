//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension StreamVideo {
    /// Lightweight session context exposing `StreamVideo`-backed user and token
    /// values for call-state and media operations without retaining a strong
    /// reference to the client.
    var callSession: CallSession {
        .init(self)
    }
}

extension StreamVideo {

    /// Session context used by call and media state.
    final class CallSession: @unchecked Sendable {
        /// The authenticated user for the current SDK session.
        let user: User

        /// The auth token used when exposing secure stream metadata.
        /// This token stays in sync with the latest `StreamVideo` token values.
        private(set) var token: UserToken

        private var tokenCancellable: AnyCancellable?

        convenience init(_ streamVideo: StreamVideo) {
            self.init(
                user: streamVideo.user,
                token: streamVideo.token,
                tokenPublisher: streamVideo.tokenPublisher.eraseToAnyPublisher()
            )
        }

        internal init(
            user: User,
            token: UserToken,
            tokenPublisher: AnyPublisher<UserToken, Never>? = nil
        ) {
            self.user = user
            self.token = token
            self.tokenCancellable = tokenPublisher?
                .assign(to: \.token, onWeak: self)
        }
    }
}
