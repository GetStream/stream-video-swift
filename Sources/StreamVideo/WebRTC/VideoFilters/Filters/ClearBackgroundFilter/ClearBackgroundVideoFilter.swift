//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation

@available(iOS 15.0, *)
public final class ClearBackgroundVideoFilter: VideoFilter, @unchecked Sendable {
    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    public init() {
        let name = String(describing: type(of: self)).lowercased()
        let processor = BackgroundImageFilterProcessor()

        super.init(
            id: "io.getstream.\(name)",
            name: name,
            filter: { input in
                let clear = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
                    .cropped(to: input.originalImage.extent)

                return processor.applyFilter(
                    input.originalPixelBuffer,
                    backgroundImage: clear
                ) ?? input.originalImage
            }
        )
    }
}
