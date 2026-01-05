//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct JoinCallView: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> Void

    @State private var callId = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TextField("Call Id", text: $callId)
                        .textFieldStyle(DemoTextfieldStyle())

                    Button {
                        presentationMode.wrappedValue.dismiss()
                        viewModel.joinCallAnonymously(callId: callId, completion: completion)
                    } label: {
                        CallButtonView(title: "Join", isDisabled: callId.isEmpty)
                            .disabled(callId.isEmpty)
                    }
                }
            }
            .padding()
            .navigationTitle("Join Call")
            .overlay(AppState.shared.loading ? ProgressView() : nil)
        }
    }
}
