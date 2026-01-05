//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallKitMissingPermissionPolicy_EndCallTests: XCTestCase, @unchecked Sendable {

    private lazy var mockApplicationStateAdapter: MockAppStateAdapter! = .init()
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var subject: CallKitMissingPermissionPolicy.EndCall! = .init()

    override func setUp() {
        super.setUp()
        mockApplicationStateAdapter.makeShared()
    }

    override func tearDown() {
        mockApplicationStateAdapter.dismante()
        subject = nil
        mockApplicationStateAdapter = nil
        mockPermissions = nil
        super.tearDown()
    }

    // MARK: - reportCall

    func test_report_appIsInForeground_doesNotThrowError() {
        mockApplicationStateAdapter.stubbedState = .foreground

        XCTAssertNoThrow(try subject.reportCall(), "")
    }

    func test_report_appIsInBackground_hasMicrophonePermission_doesNotThrowError() {
        mockApplicationStateAdapter.stubbedState = .background
        mockPermissions.stubMicrophonePermission(.granted)

        XCTAssertNoThrow(try subject.reportCall(), "")
    }

    func test_report_appIsInBackground_noMicrophonePermission_throwsError() async {
        mockApplicationStateAdapter.stubbedState = .background
        mockPermissions.stubMicrophonePermission(.denied)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .denied }

        XCTAssertThrowsError(try subject.reportCall())
    }
}
