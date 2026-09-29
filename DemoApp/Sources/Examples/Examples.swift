//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct FBCallControlsView: View {
    
    @Injected(\.videoAppearance) var videoAppearance

    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        HStack(spacing: tokens.layout.spacingXl) {
            Button {
                viewModel.toggleCameraEnabled()
            } label: {
                videoAppearance.images.videoTurnOn
            }
            
            Spacer()

            Button {
                viewModel.toggleMicrophoneEnabled()
            } label: {
                videoAppearance.images.micTurnOn
            }
            
            Spacer()
                        
            Button {
                viewModel.toggleCameraPosition()
            } label: {
                videoAppearance.images.toggleCamera
            }
            
            Spacer()
            
            HangUpIconView(viewModel: viewModel)
        }
        .foregroundColor(Color(tokens.colors.textOnAccent))
        .padding(.vertical, tokens.layout.spacingXs)
        .padding(.horizontal, tokens.layout.spacingMd)
        .modifier(BackgroundModifier())
        .padding(.horizontal, tokens.layout.spacing2xl)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct BackgroundModifier: ViewModifier {
    
    @Injected(\.videoAppearance) var videoAppearance

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: tokens.layout.radius3xl)
                )
        } else {
            content
                .background(Color(tokens.colors.backgroundCoreOverlayDarkStrong))
                .cornerRadius(tokens.layout.radius3xl)
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct CustomVideoCallParticipantView: View {
    
    @Injected(\.videoAppearance) var videoAppearance
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
                    colors: [
                        Color(tokens.colors.accentSuccess),
                        Color(tokens.colors.backgroundCoreOverlayDarkStrong),
                        Color(tokens.colors.accentSuccess)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: availableFrame.width)
                .opacity(showVideo ? 0 : 1)

                ZStack {
                    Circle()
                        .fill(Color(tokens.colors.backgroundCoreOverlayDarkStrong))
                        .frame(width: 50, height: 50)
                    videoAppearance.images.micTurnOn
                        .foregroundColor(Color(tokens.colors.textOnAccent))
                }
                .overlay(
                    participant.isSpeaking
                        ? Circle().stroke(Color(videoAppearance.colors.indicatorSoundIndicatorSpeaking), lineWidth: 2)
                        : nil
                )
                .opacity(showVideo ? 0 : 1)
            }
        )
    }
    
    private var showVideo: Bool {
        participant.shouldDisplayTrack
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct CustomParticipantModifier: ViewModifier {
            
    @Injected(\.videoAppearance) var videoAppearance

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
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: tokens.layout.spacingXs) {
                            Text(participant.name)
                                .font(tokens.fonts.bodyBold)
                                .foregroundColor(Color(tokens.colors.textOnAccent))
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality
                            )
                        }
                        .padding(.bottom, tokens.layout.spacingXxxs)
                    }
                    .padding(tokens.layout.spacingMd)
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color(tokens.colors.accentPrimary), lineWidth: 2)
                    }
                }
            )
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct CustomIncomingCallView: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
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
        VStack(spacing: tokens.layout.spacingXs) {
            Spacer()
            Text("Incoming call")
                .foregroundColor(Color(tokens.colors.textSecondary))
                .padding(tokens.layout.spacingMd)
            
            StreamLazyImage(imageURL: callInfo.caller.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: tokens.layout.radiusMd))
                .padding(tokens.layout.spacingMd)
            
            Text(callInfo.caller.name)
                .font(tokens.fonts.title)
                .foregroundColor(Color(tokens.colors.textSecondary))
                .padding(tokens.layout.spacingMd)
            
            Spacer()
            
            HStack(spacing: tokens.layout.spacingMd) {
                Spacer()
                
                Button {
                    callViewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    videoAppearance.images.hangup
                        .foregroundColor(Color(videoAppearance.colors.controlDeclineCallButtonText))
                        .padding(tokens.layout.spacingMd)
                        .background(
                            RoundedRectangle(cornerRadius: tokens.layout.radiusMd)
                                .fill(Color(videoAppearance.colors.controlDeclineCallButtonBackground))
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, tokens.layout.spacingXs)
                                
                Button {
                    callViewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(videoAppearance.colors.controlAcceptCallButtonText))
                        .padding(tokens.layout.spacingMd)
                        .background(
                            RoundedRectangle(cornerRadius: tokens.layout.radiusMd)
                                .fill(Color(videoAppearance.colors.controlAcceptCallButtonBackground))
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, tokens.layout.spacingXs)
                
                Spacer()
            }
            .padding(tokens.layout.spacingMd)
        }
        .background(Color(tokens.colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
    }
    
    var callInfo: IncomingCall {
        viewModel.callInfo
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
