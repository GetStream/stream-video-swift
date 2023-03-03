//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class RecordingEventsMiddleware: EventMiddleware {
    
    var onRecordingEvent: ((RecordingEvent) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let event = event as? CallRecordingStartedEvent {
            let recordingEvent = RecordingEvent(
                callCid: event.callCid,
                type: event.type,
                action: .started
            )
            onRecordingEvent?(recordingEvent)
        } else if let event = event as? CallRecordingStoppedEvent {
            let recordingEvent = RecordingEvent(
                callCid: event.callCid,
                type: event.type,
                action: .stopped
            )
            onRecordingEvent?(recordingEvent)
        }
        return event
    }
}
