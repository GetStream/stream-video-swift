//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallCache {
    private let queue = UnfairQueue()
    private var storage: [String: Call] = [:]

    func getCall(
        callType: String,
        callId: String,
        factory: () -> Call
    ) -> Call {
        let cId = callCid(from: callType, callType: callId)
        return queue.sync {
            if let cached = storage[cId] {
                return cached
            } else {
                let call = factory()
                storage[cId] = call
                return call
            }
        }
    }

    func removeCall(callType: String, callId: String) {
        let cId = callCid(from: callType, callType: callId)
        queue.sync {
            storage[cId] = nil
        }
    }
}

extension CallCache: InjectionKey {
    static var currentValue: CallCache = .init()
}

extension InjectedValues {
    var callCache: CallCache {
        get { Self[CallCache.self] }
        set { Self[CallCache.self] = newValue }
    }
}
