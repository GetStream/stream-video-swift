//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class CallEventsMiddleware: EventMiddleware {
    
    var room: Room?
    
    func handle(event: Event) -> Event? {
        if let audioMuted = event as? Stream_Video_AudioMuted {
            room?.handleParticipantEvent(.audioStopped, for: audioMuted.userID)
        } else if let audioUnmuted = event as? Stream_Video_AudioUnmuted {
            room?.handleParticipantEvent(.audioStarted, for: audioUnmuted.userID)
        } else if let videoStarted = event as? Stream_Video_VideoStarted {
            room?.handleParticipantEvent(.videoStarted, for: videoStarted.userID)
        } else if let videoStopped = event as? Stream_Video_VideoStopped {
            room?.handleParticipantEvent(.videoStopped, for: videoStopped.userID)
        }
        
        return event
    }
}
