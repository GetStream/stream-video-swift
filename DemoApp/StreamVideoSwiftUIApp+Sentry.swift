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
            options.dsn = "https://88ee362df1bd400094bfbb587c10ee3b@o14368.ingest.sentry.io/4504356153393152"
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
