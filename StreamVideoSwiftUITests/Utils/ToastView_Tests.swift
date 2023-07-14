//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

final class ToastView_Tests: XCTestCase {
    
    private let perceptualPrecision: Float = 0.96

    func test_toastView_errorSnapshot() {
        // Given
        let toast = Toast(style: .error, message: "An error occurred.")
        let view = EmptyView()
            .frame(
                width: defaultScreenSize.width,
                height: defaultScreenSize.height
            )
            .toastView(toast: .constant(toast))

        
        // Then
        AssertSnapshot(view, perceptualPrecision: perceptualPrecision)
    }
    
    func test_toastView_successSnapshot() {
        // Given
        let toast = Toast(style: .success, message: "Something good occurred.")
        let view = EmptyView()
            .frame(
                width: defaultScreenSize.width,
                height: defaultScreenSize.height
            )
            .toastView(toast: .constant(toast))

        
        // Then
        AssertSnapshot(view, perceptualPrecision: perceptualPrecision)
    }
    
    func test_toastView_warningSnapshot() {
        // Given
        let toast = Toast(style: .warning, message: "A warning occurred.")
        let view = EmptyView()
            .frame(
                width: defaultScreenSize.width,
                height: defaultScreenSize.height
            )
            .toastView(toast: .constant(toast))

        
        // Then
        AssertSnapshot(view, perceptualPrecision: perceptualPrecision)
    }
    
    func test_toastView_infoSnapshot() {
        // Given
        let toast = Toast(style: .info, message: "An info message.")
        let view = EmptyView()
            .frame(
                width: defaultScreenSize.width,
                height: defaultScreenSize.height
            )
            .toastView(toast: .constant(toast))

        
        // Then
        AssertSnapshot(view, perceptualPrecision: perceptualPrecision)
    }
    
    func test_toastView_errorSnapshotBottom() {
        // Given
        let toast = Toast(style: .error, message: "An error occurred.", placement: .bottom)
        let view = EmptyView()
            .frame(
                width: defaultScreenSize.width,
                height: defaultScreenSize.height
            )
            .toastView(toast: .constant(toast))

        
        // Then
        AssertSnapshot(view, perceptualPrecision: perceptualPrecision)
    }

}
