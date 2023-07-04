//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallSettingsManager {
    
    var state: CallSettingsState { get }
    
    func updateState(
        newState state: Bool,
        current: Bool,
        action: (Bool) async throws  -> (),
        onUpdate: (Bool) -> ()
    ) async throws
}

extension CallSettingsManager {
    func updateState(
        newState state: Bool,
        current: Bool,
        action: (Bool) async throws  -> (),
        onUpdate: (Bool) -> ()
    ) async throws {
        let updatingState = await self.state.updatingState
        if state == current || updatingState == state {
            return
        }
        await self.state.setUpdatingState(state)
        try await action(state)
        onUpdate(state)
        await self.state.setUpdatingState(nil)
    }
}

actor CallSettingsState {
    var updatingState: Bool?
    func setUpdatingState(_ state: Bool?) {
        self.updatingState = state
    }
}

public enum CallSettingsStatus: String {
    case enabled
    case disabled
    
    var next: Self {
        self == .enabled ? .disabled : .enabled
    }
    
    var toBool: Bool {
        self == .enabled ? true : false
    }
}
