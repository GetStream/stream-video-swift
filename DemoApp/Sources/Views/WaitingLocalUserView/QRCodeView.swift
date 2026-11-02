//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {

    let text: String

    @State private var qrImage: (text: String, image: UIImage)?

    var body: some View {
        Group {
            if let qrImage, qrImage.text == text {
                Image(uiImage: qrImage.image)
                    .interpolation(.none) // Prevents blurriness
                    .resizable()
                    .scaledToFit()
            }
        }
        .task(id: text) {
            guard qrImage?.text != text else { return }

            let image = await Generator.shared.generateQRCode(from: text)
            // Text changes and disappearance cancel the view's task, but
            // synchronous Core Image work can finish after cancellation.
            guard !Task.isCancelled, let image else { return }
            qrImage = (text, image)
        }
    }

    private actor Generator {
        static let shared = Generator()

        // Initialize and reuse the context on this actor, away from main.
        private lazy var context = CIContext()

        func generateQRCode(from string: String) -> UIImage? {
            guard !Task.isCancelled else { return nil }

            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(string.utf8)

            if let outputImage = filter.outputImage {
                if let cgImage = context.createCGImage(
                    outputImage, from: outputImage.extent
                ) {
                    return UIImage(cgImage: cgImage)
                }
            }
            return nil
        }
    }
}
