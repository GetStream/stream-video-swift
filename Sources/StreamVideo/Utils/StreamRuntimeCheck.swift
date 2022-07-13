//
//  StreamRuntimeCheck.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 13.7.22.
//

import Foundation

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the Stream SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    public static var assertionsEnabled = false

    /// For *internal use* only
    ///
    ///  Enables lazy mapping of DB models
    public static var _isLazyMappingEnabled = true
}
