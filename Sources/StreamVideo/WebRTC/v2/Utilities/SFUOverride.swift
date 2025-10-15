//
//  SFUOverride.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 15/10/25.
//

import Foundation

#if ALLOW_SFU_OVERRIDE

public enum SFUOverride: InjectionKey, CustomStringConvertible {
    case disabled
    case enabled(String)

    public var description: String {
        switch self {
        case .disabled:
            return ".disabled"
        case .enabled(let value):
            return ".enabled(\(value))"
        }
    }

    nonisolated(unsafe) public static var currentValue: SFUOverride = .enabled("sfu-aws-frankfurt-zwar-vp1-cd703fc954d5.stream-io-video.com")
}

extension InjectedValues {
    public var sfuOverride: SFUOverride {
        get { Self[SFUOverride.self] }
        set { Self[SFUOverride.self] = newValue }
    }
}

#endif
