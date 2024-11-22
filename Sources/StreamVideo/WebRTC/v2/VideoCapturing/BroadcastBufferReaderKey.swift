//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum BroadcastBufferReaderKey: InjectionKey {
    static var currentValue: BroadcastBufferReader = .init()
}

extension InjectedValues {
    var broadcastBufferReader: BroadcastBufferReader {
        get { Self[BroadcastBufferReaderKey.self] }
        set { Self[BroadcastBufferReaderKey.self] = newValue }
    }
}
