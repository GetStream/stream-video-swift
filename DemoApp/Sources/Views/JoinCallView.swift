//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct JoinCallView: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()

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
            .overlay( AppState.shared.loading ? ProgressView() : nil)
        }
    }
}
