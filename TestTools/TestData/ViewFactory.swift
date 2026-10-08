//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI

class TestViewFactory: ViewFactory {
    
    let isCustomGridFrame: Bool
    
    init(
        participantLayout: ParticipantsLayout? = nil,
        participantsCount: Int? = nil
    ) {
        isCustomGridFrame = participantLayout == .grid && (participantsCount == 2 || participantsCount == 3)
    }
        
    func makeVideoParticipantView(options: VideoParticipantViewOptions) -> some View {
        let uiImage = UIImage(data: try! Data(contentsOf: options.participant.profileImageURL!))!
        let image = Image(uiImage: uiImage).resizable()
        let zstack =
            ZStack {
                ZStack {
                    image
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .blur(radius: 8)
                        .clipped()
                }
                .edgesIgnoringSafeArea(.all)
                .background(Color(red: 16 / 255, green: 18 / 255, blue: 19 / 255))

                ZStack {
                    image
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 138, height: 138)
                        .clipShape(Circle())
                }
            }
        
        if isCustomGridFrame {
            return zstack.frame(maxWidth: options.availableFrame.width, maxHeight: options.availableFrame.height)
        } else {
            return zstack.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

enum ParticipantFactory {
    static func get(
        _ count: Int,
        withVideo hasVideo: Bool = false,
        withAudio hasAudio: Bool = false,
        speaking isSpeaking: Bool = false,
        connectionQuality: ConnectionQuality = .excellent
    ) -> [CallParticipant] {
        var factory: [CallParticipant] = []
        guard count > 0 else { return factory }
        
        for i in 1...count {
            let participant = CallParticipant(
                id: "test\(i)",
                userId: "test\(i)",
                roles: ["user"],
                name: "\(i) Test",
                profileImageURL: ImageFactory.get(i),
                trackLookupPrefix: nil,
                hasVideo: hasVideo,
                hasAudio: hasAudio,
                isScreenSharing: false,
                showTrack: false,
                isSpeaking: isSpeaking,
                isDominantSpeaker: false,
                sessionId: "test\(i)",
                connectionQuality: connectionQuality,
                joinedAt: Date(),
                audioLevel: 0,
                audioLevels: [],
                pin: nil,
                pausedTracks: []
            )
            factory.append(participant)
        }
        
        return factory
    }
}

enum UserFactory {
    static func get(_ count: Int) -> [Member] {
        var factory: [Member] = []
        guard count > 0 else { return factory }
        
        for i in (1...count) {
            let user = User(
                id: "test\(i)",
                name: "\(i) Test",
                imageURL: ImageFactory.get(i)
            )
            let participant = Member(user: user, updatedAt: .now)
            factory.append(participant)
        }
        
        return factory
    }
}
