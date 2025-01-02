//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class BroadcastUtils_Tests: XCTestCase {

    func test_broadcastUtils_adjustBiggerWidth() {
        // Given
        let width: Int32 = 233
        let height: Int32 = 177
        let size: Int32 = 200
        
        // When
        let result = BroadcastUtils.adjust(width: width, height: height, size: size)
        
        // Then
        XCTAssert(result.width == size)
        XCTAssert(result.height == 152) // Same ratio is kept
    }
    
    func test_broadcastUtils_adjustBiggerHeight() {
        // Given
        let width: Int32 = 177
        let height: Int32 = 233
        let size: Int32 = 200
        
        // When
        let result = BroadcastUtils.adjust(width: width, height: height, size: size)
        
        // Then
        XCTAssert(result.height == size)
        XCTAssert(result.width == 152) // Same ratio is kept
    }
    
    func test_toSafeDimensions_notEven() {
        // Given
        let width: Int32 = 177
        let height: Int32 = 233

        // When
        let result = BroadcastUtils.toSafeDimensions(width: width, height: height)
        
        // Then
        XCTAssert(result.width == 178)
        XCTAssert(result.height == 234)
    }
    
    func test_broadcastUtils_aspectFit() {
        // Given
        let width: Int32 = 233
        let height: Int32 = 177
        let size: Int32 = 200
        
        // When
        let result = BroadcastUtils.aspectFit(width: width, height: height, size: size)
        
        // Then
        XCTAssert(result.width == size)
        XCTAssert(result.height == 151)
    }
}
