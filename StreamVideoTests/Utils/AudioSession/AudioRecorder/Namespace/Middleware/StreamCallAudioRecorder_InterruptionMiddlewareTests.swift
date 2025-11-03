//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

// TODO: Reenable them
// final class StreamCallAudioRecorder_InterruptionMiddlewareTests: XCTestCase, @unchecked Sendable {
//
//    @Injected(\.audioStore) private var audioStore
//
//    private var subject: StreamCallAudioRecorder
//        .Namespace
//        .InterruptionMiddleware! = .init()
//
//    override func tearDown() {
//        subject = nil
//        super.tearDown()
//    }
//
//    // MARK: - init
//
//    func test_audioStoreIsInterrupted_true_dispatchesSetIsInterruptedTrue() async {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setIsInterrupted(value) where value == true:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        audioStore.dispatch(.audioSession(.isInterrupted(true)))
//
//        await safeFulfillment(of: [validation])
//    }
//
//    func test_audioStoreIsInterrupted_false_dispatchesSetIsInterruptedFalse() async {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setIsInterrupted(value) where value == false:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        // We need to post a true to workaround the `removeDuplicates` in the
//        // RTCAudioStore.publisher
//        audioStore.dispatch(.audioSession(.isInterrupted(true)))
//        audioStore.dispatch(.audioSession(.isInterrupted(false)))
//
//        await safeFulfillment(of: [validation])
//    }
// }
