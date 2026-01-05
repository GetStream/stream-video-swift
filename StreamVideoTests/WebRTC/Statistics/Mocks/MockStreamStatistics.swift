//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

@dynamicMemberLookup
struct MockStreamStatistics: StreamStatisticsProtocol {
    var timestamp_us: CFTimeInterval

    var type: String
    
    var id: String
    
    var values: [String: NSObject] = [:]
    
    subscript<T>(dynamicMember keyPath: KeyPath<StreamRTCStatistics.CodingKeys, T>) -> T? {
        set {
            if let intValue = newValue as? Int {
                values[NSExpression(forKeyPath: keyPath).keyPath] = NSNumber(value: intValue)
            } else if let doubleValue = newValue as? Double {
                values[NSExpression(forKeyPath: keyPath).keyPath] = NSNumber(value: doubleValue)
            } else if let stringValue = newValue as? String {
                values[NSExpression(forKeyPath: keyPath).keyPath] = stringValue as NSString
            } else {
                /* No-op */
            }
        }
        get {
            if Swift.type(of: T.self) == Int.self {
                return (values[NSExpression(forKeyPath: keyPath).keyPath] as? NSNumber)?.intValue as? T
            } else if Swift.type(of: T.self) == Double.self {
                return (values[NSExpression(forKeyPath: keyPath).keyPath] as? NSNumber)?.doubleValue as? T
            } else if Swift.type(of: T.self) == String.self {
                return (values[NSExpression(forKeyPath: keyPath).keyPath] as? NSString) as? T
            } else {
                return nil
            }
        }
    }
}

struct MockStreamStatisticsReport: StreamStatisticsReportProtocol {
    var stats: [String: any StreamStatisticsProtocol]
}
