//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallCacheTests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var callId: String! = .unique
    private lazy var callType: String! = "test"
    private var cId: String { callCid(from: callId, callType: callType) }
    private lazy var subject: CallCache! = .init()

    override func tearDown() {
        callId = nil
        callType = nil
        subject = nil
        super.tearDown()
    }

    func testCallCreatesNewCallWhenNotCached() {

        let factory: () -> Call = { [callType, callId] in
            .dummy(callType: callType!, callId: callId!)
        }

        let call = subject.call(for: cId, factory: factory)

        XCTAssertEqual(call.cId, cId)
    }

    func testCallReturnsCachedCall() {
        let call = Call.dummy(callType: callType, callId: callId)

        // Add call to cache manually
        _ = subject.call(for: cId) { call }

        // Call should return the cached call
        let cachedCall = subject.call(for: cId, factory: { .dummy() })

        XCTAssertTrue(call === cachedCall)
    }

    func testRemoveCallById() {
        let call = Call.dummy(callType: callType, callId: callId)

        // Add call to cache
        _ = subject.call(for: cId, factory: { call })

        // Remove call by id
        subject.remove(for: cId)

        // Call should create a new call since the cache is empty
        let factory: () -> Call = { [callType, callId] in
            .dummy(callType: callType!, callId: callId!)
        }
        let newCall = subject.call(for: cId, factory: factory)

        XCTAssertFalse(call === newCall)
    }
}
