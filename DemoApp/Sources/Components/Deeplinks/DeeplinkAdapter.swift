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
    var encryptionKey: String?

    nonisolated(unsafe) static let empty = DeeplinkInfo(
        url: nil,
        callId: "",
        callType: "",
        baseURL: AppEnvironment.baseURL,
        encryptionKey: nil
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
                    baseURL: AppEnvironment.BaseURL.livestream,
                    encryptionKey: Self.encryptionKey(from: url)
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
                    baseURL: baseURL,
                    encryptionKey: Self.encryptionKey(from: url)
                ),
                nil
            )
        }
    }

    static func encryptionKey(from url: URL) -> String? {
        encryptionKey(fromQueryItems: url.queryParameters)
            ?? encryptionKey(fromRaw: url.query)
            ?? encryptionKey(fromRaw: url.fragment)
            ?? encryptionKey(fromRaw: url.absoluteString)
    }

    static func encryptionKey(fromRaw text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        let haystack = text.replacingOccurrences(of: "&amp;", with: "&")
        for marker in ["encryption_key=", "encryption_keys=", "encryptionKey="] {
            guard let range = haystack.range(of: marker, options: .caseInsensitive)
            else { continue }
            let rest = haystack[range.upperBound...]
            let end = rest.firstIndex {
                $0 == "&" || $0 == "#" || $0.isNewline || $0 == " "
            } ?? rest.endIndex
            let trimmed = formDecoded(String(rest[..<end]))
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func encryptionKey(
        fromQueryItems params: [String: String]
    ) -> String? {
        for name in ["encryption_key", "encryption_keys", "encryptionKey"] {
            if let value = params[name] {
                let decoded = formDecoded(value)
                if !decoded.isEmpty { return decoded }
            }
        }
        return nil
    }

    /// `+` is a space in form-urlencoded query values (`able+acid+anger`).
    private static func formDecoded(_ value: String) -> String {
        let plusAsSpace = value.replacingOccurrences(of: "+", with: " ")
        return (plusAsSpace.removingPercentEncoding ?? plusAsSpace)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
