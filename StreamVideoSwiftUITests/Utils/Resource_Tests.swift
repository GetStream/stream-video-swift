//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
import XCTest

final class Resource_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Initialization Tests
    
    func test_initWithNameAndExtension() {
        // Given
        let name = "testResource"
        let fileExtension = "m4a"
        
        // When
        let resource = Resource(name: name, extension: fileExtension)
        
        // Then
        XCTAssertEqual(resource.name, name)
        XCTAssertEqual(resource.extension, fileExtension)
    }
    
    func test_initWithNameOnly() {
        // Given
        let name = "testResource"
        
        // When
        let resource = Resource(name: name)
        
        // Then
        XCTAssertEqual(resource.name, name)
        XCTAssertNil(resource.extension)
    }
    
    // MARK: - String Literal Initialization Tests
    
    func test_initFromStringLiteralWithExtension() {
        // Given
        let resource: Resource = "testResource.m4a"
        
        // Then
        XCTAssertEqual(resource.name, "testResource")
        XCTAssertEqual(resource.extension, "m4a")
    }
    
    func test_initFromStringLiteralWithoutExtension() {
        // Given
        let resource: Resource = "testResource"
        
        // Then
        XCTAssertEqual(resource.name, "testResource")
        XCTAssertNil(resource.extension)
    }
    
    func test_initFromStringLiteralWithMultipleDots() {
        // Given
        let resource: Resource = "test.resource.m4a"
        
        // Then
        XCTAssertEqual(resource.name, "test.resource")
        XCTAssertEqual(resource.extension, "m4a")
    }
    
    // MARK: - Edge Cases
    
    func test_initFromEmptyStringLiteral() {
        // Given
        let resource: Resource = ""
        
        // Then
        XCTAssertEqual(resource.name, "")
        XCTAssertNil(resource.extension)
    }
    
    func test_initFromStringLiteralWithOnlyExtension() {
        // Given
        let resource: Resource = ".m4a"
        
        // Then
        XCTAssertEqual(resource.name, "")
        XCTAssertNil(resource.extension)
    }

    // MARK: - fileName

    func test_fileName_withNameAndExtension() {
        let resource: Resource = "testResource.m4a"
        XCTAssertEqual(resource.fileName, "testResource.m4a")
    }

    func test_fileName_withNameOnly() {
        let resource: Resource = "testResource"
        XCTAssertEqual(resource.fileName, "testResource")
    }
}
