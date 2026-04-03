//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    struct AuthenticationHelper: @unchecked Sendable {
        private var baseURL: URL
        let authenticationProvider: TestsAuthenticationProvider

        init(
            baseURL: URL = .init(string: "https://pronto.getstream.io/api/auth/create-token")!,
            authenticationProvider: TestsAuthenticationProvider = .init()
        ) {
            self.baseURL = baseURL
            self.authenticationProvider = authenticationProvider
        }

        func authenticate(
            userId: String,
            environment: String = "pronto"
        ) async throws -> TestsAuthenticationProvider.TokenResponse {
            try await authenticationProvider.authenticate(
                environment: environment,
                baseURL: baseURL,
                userId: userId
            )
        }
    }
}
