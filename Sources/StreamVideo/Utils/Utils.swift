//
//  Utils.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 8.7.22.
//

import Foundation

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)

}
