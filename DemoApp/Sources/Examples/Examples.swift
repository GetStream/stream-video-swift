//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct FBCallControlsView: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.layout) private var layout

    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        HStack(spacing: layout.spacingXl) {
            Button {
                viewModel.toggleCameraEnabled()
            } label: {
                images.videoTurnOn
            }
            
            Spacer()

            Button {
                viewModel.toggleMicrophoneEnabled()
            } label: {
                images.micTurnOn
            }
            
            Spacer()
                        
            Button {
                viewModel.toggleCameraPosition()
            } label: {
                images.toggleCamera
            }
            
            Spacer()
            
            HangUpIconView(viewModel: viewModel)
        }
        .foregroundColor(Color(colors.textOnAccent))
        .padding(.vertical, layout.spacingXs)
        .padding(.horizontal, layout.spacingMd)
        .modifier(BackgroundModifier())
        .padding(.horizontal, layout.spacing2xl)
    }
}

struct BackgroundModifier: ViewModifier {
    
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: layout.radius3xl)
                )
        } else {
            content
                .background(Color(colors.backgroundCoreOverlayDarkStrong))
                .cornerRadius(layout.radius3xl)
        }
    }
}

struct CustomVideoCallParticipantView: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
        
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
                        Color(colors.accentSuccess),
                        Color(colors.backgroundCoreOverlayDarkStrong),
                        Color(colors.accentSuccess)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: availableFrame.width)
                .opacity(showVideo ? 0 : 1)

                ZStack {
                    Circle()
                        .fill(Color(colors.backgroundCoreOverlayDarkStrong))
                        .frame(width: 50, height: 50)
                    images.micTurnOn
                        .foregroundColor(Color(colors.textOnAccent))
                }
                .overlay(
                    participant.isSpeaking
                        ? Circle().stroke(Color(colors.indicatorSoundIndicatorSpeaking), lineWidth: 2)
                        : nil
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
            
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
                        HStack(spacing: layout.spacingXs) {
                            Text(participant.name)
                                .font(fonts.bodyBold)
                                .foregroundColor(Color(colors.textOnAccent))
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality
                            )
                        }
                        .padding(.bottom, layout.spacingXxxs)
                    }
                    .padding(layout.spacingMd)
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color(colors.accentPrimary), lineWidth: 2)
                    }
                }
            )
    }
}

struct CustomIncomingCallView: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
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
        VStack(spacing: layout.spacingXs) {
            Spacer()
            Text("Incoming call")
                .foregroundColor(Color(colors.textSecondary))
                .padding(layout.spacingMd)
            
            StreamLazyImage(imageURL: callInfo.caller.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: layout.radiusMd))
                .padding(layout.spacingMd)
            
            Text(callInfo.caller.name)
                .font(fonts.title)
                .foregroundColor(Color(colors.textSecondary))
                .padding(layout.spacingMd)
            
            Spacer()
            
            HStack(spacing: layout.spacingMd) {
                Spacer()
                
                Button {
                    callViewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    images.hangup
                        .foregroundColor(Color(colors.controlDeclineCallButtonText))
                        .padding(layout.spacingMd)
                        .background(
                            RoundedRectangle(cornerRadius: layout.radiusMd)
                                .fill(Color(colors.controlDeclineCallButtonBackground))
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, layout.spacingXs)
                                
                Button {
                    callViewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(colors.controlAcceptCallButtonText))
                        .padding(layout.spacingMd)
                        .background(
                            RoundedRectangle(cornerRadius: layout.radiusMd)
                                .fill(Color(colors.controlAcceptCallButtonBackground))
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.all, layout.spacingXs)
                
                Spacer()
            }
            .padding(layout.spacingMd)
        }
        .background(Color(colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
    }
    
    var callInfo: IncomingCall {
        viewModel.callInfo
    }
}
