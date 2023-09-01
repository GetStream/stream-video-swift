//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo

final class PiPTrackSelectionUtils {
    
    @Injected(\.utils) private var utils
    
    func pipVideoRenderer(
        from callParticipants: [String: CallParticipant],
        currentSessionId: String?
    ) -> VideoRenderer? {
        let participants = callParticipants.values.filter { participant in
            participant.id != currentSessionId
        }
        
        let pipScreensharingId = participants.first { participant in
            participant.isScreensharing
        }?.id
        
        if let pipScreensharingId,
            let view = utils.videoRendererFactory.view(
                for: pipScreensharingId,
                isScreensharing: true
            ) {
            return view
        }
        
        let firstId = participants.first?.id
        if let firstId, let view = utils.videoRendererFactory.view(
            for: firstId, isScreensharing: false
        ) {
            return view
        }
        
        return utils.videoRendererFactory.views.values.first
    }
}
