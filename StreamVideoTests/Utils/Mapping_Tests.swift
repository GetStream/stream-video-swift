//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Mapping_Tests: XCTestCase {

    func test_userResponse_toUser() {
        // Given
        let date = Date()
        let userResponse = UserResponse(
            createdAt: date,
            custom: ["test": "test"],
            id: "test",
            image: "https://test.com",
            name: "test",
            role: "user",
            teams: [],
            updatedAt: date
        )
        
        // When
        let user = userResponse.toUser
        
        // Then
        XCTAssert(user.id == userResponse.id)
        XCTAssert(user.customData["test"]?.stringValue == userResponse.custom["test"]?.value as? String)
        XCTAssert(user.name == userResponse.name)
        XCTAssert(user.role == userResponse.role)
        XCTAssert(user.imageURL?.absoluteString == userResponse.image)
    }
    
    func test_anyCodable_toRawJSON() {
        // Given
        let custom: [String: AnyCodable] = [
            "string": "test",
            "number": 1,
            "bool": true,
            "dict": ["test": "test"],
            "array": ["test1", "test2"]
        ]
        
        // When
        let rawJSON = convert(custom)
        
        // Then
        let string = rawJSON["string"]?.stringValue
        let number = Int(rawJSON["number"]?.numberValue ?? 0)
        let bool = rawJSON["bool"]?.boolValue
        let dict = rawJSON["dict"]?.dictionaryValue
        let array = rawJSON["array"]?.stringArrayValue
        XCTAssert(string == custom["string"]?.value as? String)
        XCTAssert(number == custom["number"]?.value as? Int)
        XCTAssert(bool == custom["bool"]?.value as? Bool)
        XCTAssert(array == custom["array"]?.value as? [String])
        for (key, value) in dict! {
            let codableDict = custom["dict"]?.value as? [String: String]
            let codableValue = codableDict?[key] as? String
            XCTAssert(value.stringValue == codableValue)
        }
    }
    
    func test_callResponse_toCallData() {
        // Given
        let mockResponseBuilder = MockResponseBuilder()
        let callResponse = mockResponseBuilder.makeCallResponse(cid: "default:test")
        
        // When
        let callData = callResponse.toCallData(members: [], blockedUsers: [])
        
        // Then
        XCTAssert(callData.backstage == false)
        XCTAssert(callData.broadcasting == false)
        XCTAssert(callData.recording == false)
        XCTAssert(callData.autoRejectTimeout == 15000)
        XCTAssert(callData.callCid == "default:test")
        XCTAssert(callData.createdBy.id == "test")
    }

}
