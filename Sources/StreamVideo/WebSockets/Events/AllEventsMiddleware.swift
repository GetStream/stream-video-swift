//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class AllEventsMiddleware: EventMiddleware {
    
    var onEvent: ((PublicWSEvent) -> Void)?
    
    func handle(event: Event) -> Event? {
        let publicEvent = PublicWSEvent(
            data: event.asDictionary
        )
        onEvent?(publicEvent)
        return event
    }
}

public struct PublicWSEvent: Event {
    public let data: [String: Any]
}

extension Event {
    var asDictionary: [String: Any] {
        let mirror = Mirror(reflecting: self)
        let name = "\(mirror.subjectType)"
        var dict = Dictionary(
            uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        dict["eventName"] = name
        return dict
    }
}
