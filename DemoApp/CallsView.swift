//
//  CallsView.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.4.23.
//

import SwiftUI

struct CallsView: View {
    
    @StateObject var viewModel = CallsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.calls) { call in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(call.call.cid)
                                .bold()
                            Text("\(call.members.map(\.userId).joined(separator: ","))")
                                .font(.caption)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            if !call.call.backstage {
                                Text("Live")
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            if #available(iOS 15, *) {
                                Text(call.call.createdAt.formatted(date: .abbreviated, time: .shortened))
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
