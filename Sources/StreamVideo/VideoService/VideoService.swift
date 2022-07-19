//
//  VideoService.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import Foundation
import LiveKit

class VideoService {
    
    func connect(
        url: String,
        token: String,
        options: VideoOptions
    ) async throws -> VideoRoom {
        let room = Room()
        
        let connectOptions = ConnectOptions(
            autoSubscribe: true,
            publishOnlyMode: nil
        )

        let roomOptions = RoomOptions(
            defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
            ),
            // Pass the simulcast option
            defaultVideoPublishOptions: VideoPublishOptions(
                simulcast: true
            ),
            adaptiveStream: true,
            dynacast: true,
            reportStats: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            room.connect(
                url,
                token,
                connectOptions: connectOptions,
                roomOptions: roomOptions
            )
            .then { _ in
                return continuation.resume(returning: VideoRoom.create(with: room))
            }
            .catch { error in
                return continuation.resume(throwing: error)
            }
        }
    }
    
}
