//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

struct DeeplinkInfo: Equatable {
    var callId: String
    var callType: String

    static let empty = DeeplinkInfo(callId: "", callType: "")
}

struct DeeplinkAdapter {
    var baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func canHandle(url: URL) -> Bool {
        url.absoluteString.contains(baseURL.absoluteString) || url.scheme == AppEnvironment.appURLScheme
    }

    func handle(url: URL) -> (deeplinkInfo: DeeplinkInfo, user: User?) {
        guard canHandle(url: url) else {
            return (.empty, nil)
        }

        guard let callId = url.queryParameters["id"] else {
            log.warning("Unable to handle deeplink because id was missing.")
            return (.empty, nil)
        }

        let callType = url.queryParameters["type"] ?? "default"

        log.debug("Deeplink handled was: \(url)")
        return (DeeplinkInfo(callId: callId, callType: callType), nil)
    }
}
