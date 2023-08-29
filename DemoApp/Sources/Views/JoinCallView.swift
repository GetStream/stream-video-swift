//
//  JoinCallView.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import SwiftUI
import StreamVideo

struct JoinCallView: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()

    @State private var callId = ""

    var body: some View {
        VStack {
            Text("Join Call")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.bottom])

            VStack(spacing: 16) {
                TextField("Enter call id", text: $callId)

                Button {
                    presentationMode.wrappedValue.dismiss()
                    viewModel.joinCallAnonymously(callId: callId, completion: completion)
                } label: {
                    Text("Join call")
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding()
        .overlay( AppState.shared.loading ? ProgressView() : nil)
    }
}
