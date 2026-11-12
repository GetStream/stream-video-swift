//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

/// Holds the call the livestream view renders.
/// Replacing `call` publishes the new call state.
@MainActor
final class LivestreamSession: ObservableObject {
    private var stateCancellable: AnyCancellable?

    var call: Call {
        didSet {
            objectWillChange.send()
            bind()
        }
    }

    init(call: Call) {
        self.call = call
        bind()
    }

    private func bind() {
        stateCancellable = call.state.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
