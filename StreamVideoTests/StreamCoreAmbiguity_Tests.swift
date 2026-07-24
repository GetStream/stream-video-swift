//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import StreamVideo
import XCTest

final class StreamCoreAmbiguity_Tests: XCTestCase, @unchecked Sendable {
    func test_importingBothModules_resolvesSharedSymbols() {
        let types: [Any.Type] = [
            APIError.self,
            APIHelper.self,
            APIKey.self,
            BaseLogDestination.self,
            ClientError.self,
            CodableHelper.self,
            ConnectUserDetailsRequest.self,
            ConsoleLogDestination.self,
            CreateDeviceRequest.self,
            Device.self,
            DisposableBag.self,
            Injected<Int>.self,
            InjectedValues.self,
            InternetConnectionProtocol.self,
            InternetConnectionQuality.self,
            InternetConnectionStatus.self,
            JSONDataEncoding.self,
            ListDevicesResponse.self,
            LogConfig.self,
            LogDetails.self,
            LogLevel.self,
            LogSubsystem.self,
            Logger.self,
            ModelResponse.self,
            NullEncodable<String>.self,
            OpenISO8601DateFormatter.self,
            RawJSON.self,
            RecursiveQueue.self,
            Response<String>.self,
            StreamRuntimeCheck.self,
            UnfairQueue.self,
            User.self,
            UserAuthType.self,
            UserToken.self,
            UserTokenProvider.self,
            UserTokenUpdater.self,
            WSAuthMessageRequest.self
        ]

        _ = types
    }
}
