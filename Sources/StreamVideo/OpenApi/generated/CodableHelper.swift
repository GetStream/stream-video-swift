//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

open class CodableHelper {
    private nonisolated(unsafe) static var customDateFormatter: DateFormatter?
    private nonisolated(unsafe) static var defaultDateFormatter: DateFormatter = OpenISO8601DateFormatter()

    private nonisolated(unsafe) static var customJSONDecoder: JSONDecoder?
    private nonisolated(unsafe) static var defaultJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
        return decoder
    }()

    private nonisolated(unsafe) static var customJSONEncoder: JSONEncoder?
    private nonisolated(unsafe) static var defaultJSONEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(CodableHelper.dateFormatter)
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    public static var dateFormatter: DateFormatter {
        get { customDateFormatter ?? defaultDateFormatter }
        set { customDateFormatter = newValue }
    }

    public static var jsonDecoder: JSONDecoder {
        get { customJSONDecoder ?? defaultJSONDecoder }
        set { customJSONDecoder = newValue }
    }

    public static var jsonEncoder: JSONEncoder {
        get { customJSONEncoder ?? defaultJSONEncoder }
        set { customJSONEncoder = newValue }
    }

    open class func decode<T>(_ type: T.Type, from data: Data) -> Swift.Result<T, Error> where T: Decodable {
        Swift.Result { try jsonDecoder.decode(type, from: data) }
    }

    open class func encode<T>(_ value: T) -> Swift.Result<Data, Error> where T: Encodable {
        Swift.Result { try jsonEncoder.encode(value) }
    }
}
