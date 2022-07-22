//
//  VideoConfig.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 22.7.22.
//

import Foundation

public struct VideoConfig {
    var persitingSocketConnection: Bool
    
    public init(persitingSocketConnection: Bool = true) {
        self.persitingSocketConnection = persitingSocketConnection
    }
}
