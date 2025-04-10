//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

#if compiler(>=6.0)
extension AnyPublisher: @unchecked @retroactive Sendable {}
#else
extension AnyPublisher: @unchecked Sendable {}
#endif
