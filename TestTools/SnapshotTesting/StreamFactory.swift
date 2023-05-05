//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
@testable import StreamVideo
@testable import StreamVideoSwiftUI

class TestViewFactory: ViewFactory {
    
    let isCustomGridFrame: Bool
    
    init(
        participantLayout: ParticipantsLayout? = nil,
        participantsCount: Int? = nil
    ) {
        isCustomGridFrame = participantLayout == .grid && (participantsCount == 2 || participantsCount == 3)
    }
        
    func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) -> some View {
        let uiImage = UIImage(data: try! Data(contentsOf: participant.profileImageURL!))!
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
                .background(Color(Colors().callBackground))

                ZStack {
                    image
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 138, height: 138)
                        .clipShape(Circle())
                }
            }
        
        if isCustomGridFrame {
            return zstack.frame(maxWidth: availableSize.width, maxHeight: availableSize.height)
        } else {
            return zstack.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ParticipantFactory {
    static func get(
        _ count: Int,
        withVideo hasVideo: Bool = false,
        withAudio hasAudio: Bool = false,
        speaking isSpeaking: Bool = false,
        connectionQuality: ConnectionQuality = .excellent
    ) -> [CallParticipant] {
        var factory: [CallParticipant] = []
        for i in 1...count {
            let participant = CallParticipant(
                id: "test\(i)",
                userId: "test\(i)",
                roles: ["user"],
                name: "\(i) Test",
                profileImageURL: i % 2 == 0 ? ImageFactory.coffee : ImageFactory.olive,
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
                isPinned: false
            )
            factory.append(participant)
        }
        
        return factory
    }
}

struct UserFactory {
    static func get(_ count: Int) -> [User] {
        var factory: [User] = []
        for i in 1...count {
            let participant = User(
                id: "test\(i)",
                name: "\(i) Test",
                imageURL: i % 2 == 0 ? ImageFactory.coffee : ImageFactory.olive
            )
            factory.append(participant)
        }
        
        return factory
    }
}

struct ImageFactory {
    static let olive = Bundle.testResources.url(forResource: "olive", withExtension: "png")
    static let coffee = Bundle.testResources.url(forResource: "coffee", withExtension: "png")
}

extension Bundle {
    
    private final class StreamVideoTestResources {}
    
    static let bundleName = "StreamVideo_StreamVideoTestResources"
    
    static let testResources: Bundle = {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: StreamVideoTestResources.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return Bundle(for: StreamVideoTestResources.self)
    }()
}
