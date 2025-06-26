//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

public final class DefaultViewFactory: ViewFactory, @unchecked Sendable {

    private nonisolated init() { /* Private init. */ }

    public nonisolated static let shared = DefaultViewFactory()
}
