//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension RTCAudioStore {

    final class RestartMiddleware: RTCAudioStoreMiddleware {
        private struct Input {
            var file: StaticString
            var function: StaticString
            var line: UInt
        }

        private(set) weak var store: RTCAudioStore?
        private let subject: PassthroughSubject<Input, Never> = .init()
        private var cancellable: AnyCancellable?

        init(_ store: RTCAudioStore) {
            self.store = store

            cancellable = subject
                .debounce(for: .seconds(1.5), scheduler: DispatchQueue.global(qos: .userInteractive))
                .log(.debug, subsystems: .audioSession) { _ in "AudioSession restart started." }
                .sink { [weak self] in
                    self?.performRestart(
                        file: $0.file,
                        function: $0.function,
                        line: $0.line
                    )
                }
        }

        func apply(
            state: RTCAudioStore.State,
            action: RTCAudioStoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                case let .audioSession(audioSessionAction) = action
            else {
                return
            }

            switch audioSessionAction {
            case let .restart(file, function, line):
                subject.send(.init(file: file, function: function, line: line))
            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func performRestart(
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard let store else {
                return
            }
            let state = store.state
            store.dispatch(
                [
                    .audioSession(.isActive(false)),
                    .generic(.delay(seconds: 0.2)),
                    .audioSession(.isAudioEnabled(false)),
                    .generic(.delay(seconds: 0.2)),
                    .audioSession(
                        .setCategory(
                            state.category,
                            mode: state.mode,
                            options: state.options
                        )
                    ),
                    .generic(.delay(seconds: 0.2)),
                    .audioSession(.isAudioEnabled(true)),
                    .generic(.delay(seconds: 0.2)),
                    .audioSession(.isActive(true))
                ],
                file: file,
                function: function,
                line: line
            )
        }
    }
}
