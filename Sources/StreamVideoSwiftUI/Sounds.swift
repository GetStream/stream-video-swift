//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class Sounds {
    public var bundle: Bundle = .streamVideoUI
    public var outgoingCallSound: Resource = .init(bundle: .streamVideoUI, name: "outgoing", extension: "m4a")
    public var incomingCallSound: Resource = .init(bundle: .streamVideoUI, name: "incoming", extension: "wav")

    public init() { /* Public init. */ }
}
