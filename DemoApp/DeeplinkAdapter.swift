//
//  DeeplinkAdapter.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/5/23.
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

    func canHandle(url: URL) -> Bool {
        url.absoluteString.contains(baseURL.absoluteString) || url.scheme == Config.appURLScheme
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
        let user = url.queryParameters["user_id"]
            .flatMap { userId in User.builtInUsers.filter({ $0.id == userId }).first }

        log.debug("Deeplink handled was: \(url)")
        return (DeeplinkInfo(callId: callId, callType: callType), user)
    }
}
