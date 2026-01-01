//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

struct DeeplinkInfo: Equatable {
    var url: URL?
    var callId: String
    var callType: String
    var baseURL: AppEnvironment.BaseURL

    static let empty = DeeplinkInfo(
        url: nil,
        callId: "",
        callType: "",
        baseURL: AppEnvironment.baseURL
    )
}

struct DeeplinkAdapter {
    func canHandle(url: URL) -> Bool {
        if url.scheme == AppEnvironment.appURLScheme {
            return true
        }

        let result = AppEnvironment
            .supportedDeeplinks
            .compactMap(\.deeplinkURL.host)
            .first { url.host == $0 } != nil

        return result
    }

    func handle(url: URL) -> (deeplinkInfo: DeeplinkInfo, user: User?) {
        guard canHandle(url: url) else {
            return (.empty, nil)
        }

        if
            url.host == AppEnvironment.BaseURL.livestream.url.host,
            let callId = url.queryParameters["id"] ?? url.queryParameters["view"] {
            return (
                DeeplinkInfo(
                    url: url,
                    callId: callId,
                    callType: .livestream,
                    baseURL: AppEnvironment.BaseURL.livestream
                ),
                nil
            )
        } else {
            let pathComponentsCount = url.pathComponents.endIndex

            // Fetch the callId from the path components
            // e.g https://getstream.io/join/path-call-id
            let callPathId: String? = {
                guard
                    pathComponentsCount >= 2,
                    url.pathComponents[pathComponentsCount - 2] == "join",
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
            let host = url.host
            let baseURL: AppEnvironment.BaseURL = AppEnvironment
                .BaseURL
                .allCases
                .first { $0.url.host == host } ?? AppEnvironment.baseURL

            return (
                DeeplinkInfo(
                    url: url,
                    callId: callId,
                    callType: callType,
                    baseURL: baseURL
                ),
                nil
            )
        }
    }
}
