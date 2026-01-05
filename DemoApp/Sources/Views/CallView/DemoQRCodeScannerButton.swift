//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoQRCodeScannerButton: View {

    @Injected(\.appearance) var appearance

    @State private var isQRScannerPresented = false
    @ObservedObject var viewModel: CallViewModel
    private let completion: (DeeplinkInfo?) -> Void
    private let deeplinkAdapter: DeeplinkAdapter

    init(
        viewModel: CallViewModel,
        completion: @escaping (DeeplinkInfo?) -> Void
    ) {
        self.viewModel = viewModel
        self.completion = completion
        deeplinkAdapter = DeeplinkAdapter()
    }

    var body: some View {
        #if !targetEnvironment(simulator) && !os(macOS)
        Button {
            isQRScannerPresented = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .foregroundColor(.init(appearance.colors.textLowEmphasis))
        }
        .padding(.trailing)
        .sheet(isPresented: $isQRScannerPresented) {
            CodeScannerView(codeTypes: [.qr]) { result in
                switch result {
                case let .success(scanResult):
                    if let url = URL(string: scanResult.string), url.isWeb {
                        if deeplinkAdapter.canHandle(url: url) {
                            let deeplinkInfo = deeplinkAdapter.handle(url: url).deeplinkInfo
                            completion(deeplinkInfo)
                        } else {
                            viewModel.toast = Toast(style: .error, message: "The recognised URL from the QR code isn't supported.")
                            completion(nil)
                        }
                    } else {
                        completion(.init(
                            callId: scanResult.string,
                            callType: .default,
                            baseURL: AppEnvironment.baseURL
                        ))
                    }
                case let .failure(error):
                    log.error(error)
                    viewModel.toast = Toast(style: .error, message: "\(error)")
                    completion(nil)
                }
                isQRScannerPresented = false
            }
            .ignoresSafeArea()
        }
        #else
        EmptyView()
        #endif
    }
}
