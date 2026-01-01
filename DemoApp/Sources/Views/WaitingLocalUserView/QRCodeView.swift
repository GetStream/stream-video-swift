//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {
    let text: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: text) {
            Image(uiImage: qrImage)
                .interpolation(.none) // Prevents blurriness
                .resizable()
                .scaledToFit()
        }
    }
    
    /// Generates a QR code image from a given string
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
