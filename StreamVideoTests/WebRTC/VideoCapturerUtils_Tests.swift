//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class VideoCapturerUtils_Tests: XCTestCase {

    func test_cmVideoDimensions_area() {
        // Given
        let full = CMVideoDimensions.full
        let half = CMVideoDimensions.half
        let quarter = CMVideoDimensions.quarter
        
        // Then
        XCTAssert(full.area == 921_600)
        XCTAssert(half.area == 307_200)
        XCTAssert(quarter.area == 172_800)
    }
    
    func test_mergeRanges() {
        // Given
        let range1: ClosedRange<Int> = 1...3
        let range2: ClosedRange<Int> = 2...4
        
        // When
        let merged = merge(range: range1, with: range2)
        
        // Then
        XCTAssert(merged.lowerBound == 1)
        XCTAssert(merged.upperBound == 4)
    }
    
    func test_mergeRanges_noCommon() {
        // Given
        let range1: ClosedRange<Int> = 1...3
        let range2: ClosedRange<Int> = 5...7
        
        // When
        let merged = merge(range: range1, with: range2)
        
        // Then
        XCTAssert(merged.lowerBound == 1)
        XCTAssert(merged.upperBound == 7)
    }
    
    func test_clamped_toLimitsUpper() {
        // Given
        let value = 5
        
        // When
        let result = value.clamped(to: 1...4)
        
        // Then
        XCTAssert(result == 4)
    }
    
    func test_clamped_toLimitsLower() {
        // Given
        let value = 1
        
        // When
        let result = value.clamped(to: 2...4)
        
        // Then
        XCTAssert(result == 2)
    }
    
    func test_make_codecs() {
        // Given
        let targetResolution = CMVideoDimensions(width: 1024, height: 720)
        let preferredBitrate = 1_000_000_000
        
        // When
        let codecs = VideoCapturingUtils.makeCodecs(
            with: targetResolution,
            preferredBitrate: preferredBitrate
        )
        
        // Then
        XCTAssert(codecs.count == 3)
        XCTAssert(codecs[0].dimensions.width == targetResolution.width / 4)
        XCTAssert(codecs[0].dimensions.height == targetResolution.height / 4)
        XCTAssert(codecs[1].dimensions.width == targetResolution.width / 2)
        XCTAssert(codecs[1].dimensions.height == targetResolution.height / 2)
        XCTAssert(codecs[2].dimensions.width == targetResolution.width)
        XCTAssert(codecs[2].dimensions.height == targetResolution.height)
        XCTAssert(codecs[2].maxBitrate == preferredBitrate)
    }
}
