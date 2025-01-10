//
//  LocalSFUDebugConfiguration.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 10/1/25.
//

import Foundation

public struct SFUOverrideConfiguration: Hashable {
    public var edgeName: String
    public var twirpConfiguration: TwirpConfiguration
    public var url: String
    public var ws: String

    public enum TwirpConfiguration: Hashable {
        case none
        case http
        case https
    }

    public init(edgeName: String, twirpConfiguration: TwirpConfiguration) {
        self.edgeName = edgeName
        self.twirpConfiguration = twirpConfiguration
        self.url = {
            switch twirpConfiguration {
            case .none:
                return "\(edgeName)/twirp"
            case .http:
                return "http://\(edgeName)/twirp"
            case .https:
                return "https://\(edgeName)/twirp"
            }
        }()
        self.ws = "wss://\(edgeName)/ws"
    }

    public static var empty = SFUOverrideConfiguration(edgeName: "", twirpConfiguration: .none)
}

extension SFUOverrideConfiguration: InjectionKey {
    public static var currentValue: SFUOverrideConfiguration?
}

extension InjectedValues {
    public var sfuOverride: SFUOverrideConfiguration? {
        get { Self[SFUOverrideConfiguration.self] }
        set { Self[SFUOverrideConfiguration.self] = newValue }
    }
}
