//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    var availableFrame: CGRect
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    public init(
        participant: CallParticipant,
        id: String? = nil,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) {
        self.participant = participant
        self.id = id ?? participant.id
        self.availableFrame = availableFrame
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.onViewUpdate = onViewUpdate
    }
    
    public var body: some View {
        VideoRendererView(
            id: id,
            size: availableFrame.size,
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
                .frame(width: availableFrame.width)
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

struct CustomParticipantModifier: ViewModifier {
            
    var participant: CallParticipant
    @Binding var pinnedParticipant: CallParticipant?
    var participantCount: Int
    var availableFrame: CGRect
    var ratio: CGFloat
    
    public init(
        participant: CallParticipant,
        pinnedParticipant: Binding<CallParticipant?>,
        participantCount: Int,
        availableFrame: CGRect,
        ratio: CGFloat
    ) {
        self.participant = participant
        _pinnedParticipant = pinnedParticipant
        self.participantCount = participantCount
        self.availableFrame = availableFrame
        self.ratio = ratio
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.width, ratio: ratio)
            .overlay(
                ZStack {
                    VStack {
                        Spacer()
                        HStack {
                            Text(participant.name)
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality
                            )
                        }
                        .padding(.bottom, 2)
                    }
                    .padding()
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color.blue.opacity(0.7), lineWidth: 2)
                    }
                }
            )
    }
}

struct CustomIncomingCallView: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var callViewModel: CallViewModel
    @StateObject var viewModel: IncomingViewModel
                
    init(
        callInfo: IncomingCall,
        callViewModel: CallViewModel
    ) {
        self.callViewModel = callViewModel
        _viewModel = StateObject(
            wrappedValue: IncomingViewModel(callInfo: callInfo)
        )
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Incoming call")
                .foregroundColor(Color(colors.textLowEmphasis))
                .padding()
            
            StreamLazyImage(imageURL: callInfo.caller.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
            
            Text(callInfo.caller.name)
                .font(.title)
                .foregroundColor(Color(colors.textLowEmphasis))
                .padding()
            
            Spacer()
            
            HStack(spacing: 16) {
                Spacer()
                
                Button {
                    callViewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, 8)
                                
                Button {
                    callViewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, 8)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    var callInfo: IncomingCall {
        viewModel.callInfo
    }
}
