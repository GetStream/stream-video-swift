//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct FBCallControlsView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            Button {
                viewModel.toggleCameraEnabled()
            } label: {
                Image(systemName: "video.fill")
            }
            
            Spacer()

            Button {
                viewModel.toggleMicrophoneEnabled()
            } label: {
                Image(systemName: "mic.fill")
            }
            
            Spacer()
                        
            Button {
                viewModel.toggleCameraPosition()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
            }
            
            Spacer()
            
            HangUpIconView(viewModel: viewModel)
        }
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .modifier(BackgroundModifier())
        .padding(.horizontal, 32)
    }
    
}

struct BackgroundModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24)
                )
        } else {
            content
                .background(Color.black.opacity(0.8))
                .cornerRadius(24)
        }
    }
    
}

struct CustomVideoCallParticipantView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
        
    let participant: CallParticipant
    var id: String
    var availableSize: CGSize
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    public init(
        participant: CallParticipant,
        id: String? = nil,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) {
        self.participant = participant
        self.id = id ?? participant.id
        self.availableSize = availableSize
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.onViewUpdate = onViewUpdate
    }
    
    public var body: some View {
        VideoRendererView(
            id: id,
            size: availableSize,
            contentMode: contentMode
        ) { view in
            onViewUpdate(participant, view)
        }
        .opacity(showVideo ? 1 : 0)
        .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
        .accessibility(identifier: "callParticipantView")
        .streamAccessibility(value: showVideo ? "1" : "0")
        .overlay(
            ZStack {
                LinearGradient(
                    colors: [Color.green, Color.black, Color.green],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: availableSize.width)
                .opacity(showVideo ? 0 : 1)

                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 50, height: 50)
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                }
                .overlay(
                    participant.isSpeaking ? Circle().stroke(Color.green, lineWidth: 2) : nil
                )
                .opacity(showVideo ? 0 : 1)
            }
        )
    }
    
    private var showVideo: Bool {
        participant.shouldDisplayTrack
    }
}
