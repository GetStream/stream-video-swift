//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallsView: View {
    
    @StateObject var viewModel = CallsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.calls) { call in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(call.cId)
                                .bold()
                            Text("\(call.state.members.map(\.user.id).joined(separator: ","))")
                                .font(.caption)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            if !call.state.backstage {
                                Text("Live")
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            if #available(iOS 15, *) {
                                Text(call.state.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .onAppear {
                        viewModel.onCallAppear(call)
                    }
                }
            }
        }
    }
}
