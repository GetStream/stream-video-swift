//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
#if canImport(Gleap)
import Gleap
#endif

final class GleapAdapter {

    var isAvailable: Bool {
        #if canImport(Gleap)
        return true
        #else
        return false
        #endif
    }

    init() {
        #if canImport(Gleap)
        Gleap.initialize(withToken: "qsoyideVaZ7ZOehLLl8LqDC6YOPagLvr")
        Gleap.showFeedbackButton(false)
        log.debug("✅ Gleap has been activated.")
        #else
        log.warning("Cannot enable Gleap as the module hasn't been imported.")
        #endif
    }

    func login(_ user: User) {
        guard isAvailable else {
            return
        }
        let userProperty = GleapUserProperty()
        userProperty.name = user.name
        userProperty.customData = [
            "userId": user.id,
            "userType": "\(user.type)",
            "userRole": user.role,
            "userOriginalName": user.originalName ?? "-"
        ]

        Gleap.identifyContact(user.id, andData: userProperty)
    }

    func logout() {
        guard isAvailable else {
            return
        }
        Gleap.clearIdentity()
    }

    func showBugReport(
        with attachment: URL
    ) {
        guard isAvailable else {
            return
        }
        Gleap.addAttachment(withPath: attachment.path)
        Gleap.startFeedbackFlow("bugreporting", showBackButton: true)
    }
}

extension GleapAdapter: InjectionKey {
    static var currentValue = GleapAdapter()
}

extension InjectedValues {
    var gleap: GleapAdapter {
        get { InjectedValues[GleapAdapter.self] }
        set { InjectedValues[GleapAdapter.self] = newValue }
    }
}
