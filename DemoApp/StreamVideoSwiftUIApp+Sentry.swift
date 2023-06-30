//
//  StreamVideoSwiftUIApp+Sentry.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/5/23.
//

import Foundation
import StreamVideo
import Sentry

extension StreamVideoSwiftUIApp {

    func configureSentry() {
    #if RELEASE
        // We're tracking Crash Reports / Issues from the Demo App to keep improving the SDK
        SentrySDK.start { options in
            options.dsn = "https://855ff07b9c1841e38842682d5a87d7b4@o389650.ingest.sentry.io/4505447573356544"
            options.debug = true
            options.tracesSampleRate = 1.0
            options.enableAppHangTracking = true
        }
        
        LogConfig.destinationTypes = [ConsoleLogDestination.self, SentryLogDestination.self]

    #endif
    }
}

/// Basic destination for outputting messages to console.
public class SentryLogDestination: BaseLogDestination {
    override open func write(message: String) {
        SentrySDK.capture(message: message)
    }
}
