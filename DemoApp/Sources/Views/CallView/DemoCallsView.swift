//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Injected(\.streamVideo) var streamVideo
    
    @StateObject var viewModel = DemoCallsViewModel()
    @ObservedObject var callViewModel: CallViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.streamEmployees) { employee in
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        callViewModel.startCall(
                            callType: .default,
                            callId: UUID().uuidString,
                            members: [
                                MemberRequest(userId: employee.id),
                                MemberRequest(userId: streamVideo.user.id)
                            ],
                            ring: true
                        )
                    }, label: {
                        HStack {
                            LazyImage(imageURL: employee.imageURL)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            Text(employee.name)
                            Spacer()
                        }
                    })
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadEmployees()
        }
    }
}
