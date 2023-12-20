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
    func canHandle(url: URL) -> Bool {
        if url.scheme == AppEnvironment.appURLScheme {
            return true
        }

        return AppEnvironment
            .supportedDeeplinks
            .compactMap(\.deeplinkURL.host)
            .first { url.host == $0 } != nil
    }

    func handle(url: URL) -> (deeplinkInfo: DeeplinkInfo, user: User?) {
        guard canHandle(url: url) else {
            return (.empty, nil)
        }
        
        // Fetch the callId from the path components
        // e.g https://getstream.io/video/demos/join/path-call-id
        let callPathId: String? = {
            guard
                url.pathComponents.count == 5,
                let callId = url.pathComponents.last
            else {
                return nil
            }
            return callId
        }()

        // Fetch the callId from the query parameters
        // e.g https://getstream.io/video/demos?id=parameter-call-id
        let callParameterId = url.queryParameters["id"]

        guard 
            // Use the the callPathId with higher priority if it's available.
            let callId = callPathId ?? callParameterId
         else {
            log.warning("Unable to handle deeplink because id was missing.")
            return (.empty, nil)
        }

        let callType = url.queryParameters["type"] ?? "default"

        log.debug("Deeplink handled was: \(url)")
        return (DeeplinkInfo(callId: callId, callType: callType), nil)
    }
}
