//
//  IncomingCall.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 23.7.22.
//

import Foundation

public struct IncomingCall: Identifiable {
    public let id: String
    public let callerId: String
    
    public init(id: String, callerId: String) {
        self.id = id
        self.callerId = callerId
    }
}
