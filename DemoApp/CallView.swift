//
//  CallView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct CallView: View {
    
    @StateObject var viewModel: CallViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: CallViewModel())
    }
        
    var body: some View {
        ZStack {
            if viewModel.shouldShowRoomView {
                RoomView(viewModel: viewModel)
            } else {
                ConnectView(viewModel: viewModel)
            }

        }
    }
}

struct ConnectView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                viewModel.makeCall()
            } label: {
                Text("Start a call")
            }
            .disabled(viewModel.loading)
            
            Spacer()
        }
        .overlay(
            viewModel.loading ? ProgressView().offset(y: 32) : nil
        )
    }
    
}
