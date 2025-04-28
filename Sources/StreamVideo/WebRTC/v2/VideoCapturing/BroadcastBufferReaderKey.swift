//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

enum BroadcastBufferReaderKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: BroadcastBufferReader = .init()
}

extension InjectedValues {
    var broadcastBufferReader: BroadcastBufferReader {
        get { Self[BroadcastBufferReaderKey.self] }
        set { Self[BroadcastBufferReaderKey.self] = newValue }
    }
}
