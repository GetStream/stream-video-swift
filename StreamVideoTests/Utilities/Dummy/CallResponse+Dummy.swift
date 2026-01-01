//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallResponse {
    static func dummy(
        backstage: Bool = false,
        blockedUserIds: [String] = [],
        cid: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        createdBy: UserResponse = UserResponse.dummy(),
        currentSessionId: String = "",
        custom: [String: RawJSON] = [:],
        egress: EgressResponse = EgressResponse.dummy(),
        endedAt: Date? = nil,
        id: String = "",
        ingress: CallIngressResponse = CallIngressResponse.dummy(),
        recording: Bool = false,
        session: CallSessionResponse? = nil,
        settings: CallSettingsResponse = CallSettingsResponse.dummy(),
        startsAt: Date? = nil,
        team: String? = nil,
        thumbnails: ThumbnailResponse? = nil,
        transcribing: Bool = false,
        type: String = "",
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> CallResponse {
        .init(
            backstage: backstage,
            blockedUserIds: blockedUserIds,
            captioning: false,
            cid: cid,
            createdAt: createdAt,
            createdBy: createdBy,
            currentSessionId: currentSessionId,
            custom: custom,
            egress: egress,
            endedAt: endedAt,
            id: id,
            ingress: ingress,
            recording: recording,
            session: session,
            settings: settings,
            startsAt: startsAt,
            team: team,
            thumbnails: thumbnails,
            transcribing: transcribing,
            type: type,
            updatedAt: updatedAt
        )
    }
}
