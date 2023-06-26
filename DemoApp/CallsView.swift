//
//  CallsView.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.4.23.
//

import SwiftUI
import StreamVideo

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

extension Call: Identifiable {
    public var id: String {
        cId
    }
}
