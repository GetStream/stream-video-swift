//
//  RoomView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI

struct RoomView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        Group {
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
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
    }
}
