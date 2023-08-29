//
//  DeeplinkAdapter.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/5/23.
//

import Foundation
import StreamVideo

internal struct DeeplinkInfo: Equatable {
    internal var callId: String
    internal var callType: String

    internal static let empty = DeeplinkInfo(callId: "", callType: "")
}

internal struct DeeplinkAdapter {
    internal var baseURL: URL

    internal init(baseURL: URL) {
        self.baseURL = baseURL
    }

    internal func canHandle(url: URL) -> Bool {
        url.absoluteString.contains(baseURL.absoluteString) || url.scheme == AppEnvironment.appURLScheme
    }

    internal func handle(url: URL) -> (deeplinkInfo: DeeplinkInfo, user: User?) {
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
