//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol SFUAdapterEvent {
    var hostname: String { get set }

    var traceTag: String { get }
    var traceData: AnyEncodable? { get }
}

extension SFUAdapterEvent {
    var traceData: AnyEncodable? { nil }
}
