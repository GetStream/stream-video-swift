//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallStateMachine.Stage {

    static func joining(
        _ call: Call?,
        create: Bool,
        options: CreateCallOptions?,
        ring: Bool,
        notify: Bool,
        callSettings: CallSettings?
    ) -> StreamCallStateMachine.Stage {
        JoiningStage(
            call,
            create: create,
            options: options,
            ring: ring,
            notify: notify,
            callSettings: callSettings
        )
    }
}

extension StreamCallStateMachine.Stage {

    final class JoiningStage: StreamCallStateMachine.Stage {
        let create: Bool
        let options: CreateCallOptions?
        let ring: Bool
        let notify: Bool
        let callSettings: CallSettings?

        init(
            _ call: Call?,
            create: Bool,
            options: CreateCallOptions?,
            ring: Bool,
            notify: Bool,
            callSettings: CallSettings?
        ) {
            self.create = create
            self.options = options
            self.ring = ring
            self.notify = notify
            self.callSettings = callSettings
            super.init(id: .joining, call: call)
        }

        override func transition(
            from previousStage: StreamCallStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                Task {
                    do {
                        if let call {
                            let response = try await call.executeJoin(
                                create: create,
                                options: options,
                                ring: ring,
                                notify: notify,
                                callSettings: callSettings
                            )
                            transition?(.joined(call, response: response))
                        } else {
                            transition?(.error(call, error: ClientError("Unknown error in \(type(of: self)) Call stage.")))
                        }
                    } catch {
                        transition?(.error(call, error: error))
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
