//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Intents

class IntentHandler: INExtension, INStartCallIntentHandling {
    override func handler(for intent: INIntent) -> Any {
        return self
    }

    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INStartCallIntent.self))
        let response = INStartCallIntentResponse(code: .continueInApp, userActivity: userActivity)

        completion(response)
    }
}
