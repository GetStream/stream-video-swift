//
//  RoomView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI
import StreamVideo

public struct RoomView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            VStack(spacing: 0) {
                if let focusParticipant = viewModel.focusParticipant {
                    ZStack(alignment: .bottomTrailing) {
                        ParticipantView(viewModel: viewModel, participant: focusParticipant) { _ in
                            viewModel.focusParticipant = nil
                        }
                        .overlay(RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.red.opacity(0.7), lineWidth: 5.0))
                        Text("SELECTED")
                            .font(.system(size: 10))
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.vertical, 35)
                            .padding(.horizontal, 10)
                    }

                } else {
                    ParticipantLayout(viewModel.allParticipants.values, spacing: 5) { participant in
                        ParticipantView(viewModel: viewModel, participant: participant) { participant in
                            viewModel.focusParticipant = participant
                        }
                    }
                }
             
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleCameraEnabled()
                    },
                    label: {
                        Image(systemName: viewModel.cameraTrackState.isPublished ? "video.slash.fill" : "video.fill")
                            .applyCallButtonStyle(color: .gray)
                    })
                    .disabled(viewModel.cameraTrackState.isBusy)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleMicrophoneEnabled()
                    },
                    label: {
                        Image(systemName: viewModel.microphoneTrackState.isPublished ? "mic.slash.circle.fill" : "mic.circle.fill")
                            .applyCallButtonStyle(color: .gray)
                    })
                    .disabled(viewModel.microphoneTrackState.isBusy)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleCameraPosition()
                    },
                    label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .applyCallButtonStyle(color: .gray)
                    })
                    
                    Spacer()
                    
                    Button {
                        viewModel.leaveCall()
                    } label: {
                        Image(systemName: "phone.circle.fill")
                            .applyCallButtonStyle(color: .red)
                    }
                    .padding(.all, 8)
                    
                    Spacer()
                }
            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
    }
}
