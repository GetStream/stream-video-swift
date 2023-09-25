//
//  DeeplinkTests.swift
//  SwiftUIDemoAppUITests
//
//  Created by Ilias Pavlidakis on 25/9/23.
//

import XCTest

final class DeeplinkTests: StreamTestCase {

    private enum MockDeeplink {
        static let production: URL = .init(string: "https://getstream.io/video/demos?id=test-call")!
        static let pronto: URL = .init(string: "https://pronto.getstream.io/video/demos?id=test-call")!
        static let staging: URL = .init(string: "https://staging.getstream.io/video/demos?id=test-call")!
        static let customScheme: URL = .init(string: "streamvideo://video/demos?id=test-call")!
    }

    func test_customSchemeURL_joinsTheSpecifiedCall() {
        WHEN("User opens a URL that contains a custom scheme") {
            XCUIDevice.shared.open(MockDeeplink.customScheme)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
}

extension XCUIDevice {

    fileprivate func open(_ url: URL) {
        DispatchQueue.main.async {
            // Need to async this because XCUIDevice.shared.system.open
            // synchronously waits for a button to be pressed the first time.
            self.system.open(url)
        }
    }
}
