//
//  RTCAudioStore+CallKitAct.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    final class CallKitReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: RTCAudioSession

        init(_ source: RTCAudioSession) {
            self.source = source
        }

        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> State {
            guard case let .callKit(action) = action else {
                return state
            }

            var updatedState = state

            switch action {
            case let .activate(audioSession):
                source.audioSessionDidActivate(audioSession)
                updatedState.isActive = source.isActive

            case let .deactivate(audioSession):
                source.audioSessionDidDeactivate(audioSession)
                updatedState.isActive = source.isActive
            }

            return updatedState
        }
    }
}



