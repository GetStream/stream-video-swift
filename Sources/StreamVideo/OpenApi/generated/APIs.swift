//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// We reverted the change of OpenAPIClientAPI to OpenAPIClient introduced in https://github.com/OpenAPITools/openapi-generator/pull/9624
// Because it was causing the following issue https://github.com/OpenAPITools/openapi-generator/issues/9953
// If you are affected by this issue, please consider removing the following two lines,
// By setting the option removeMigrationProjectNameClass to true in the generator
@available(*, deprecated, renamed: "OpenAPIClientAPI")
internal typealias OpenAPIClient = OpenAPIClientAPI

internal enum OpenAPIClientAPI {
    internal static var basePath = "https://chat.stream-io-api.com"
    internal static var customHeaders: [String: String] = [:]
    internal static var credential: URLCredential?
    internal static var requestBuilderFactory: RequestBuilderFactory = URLSessionRequestBuilderFactory()
    internal static var apiResponseQueue: DispatchQueue = .main
}

internal class RequestBuilder<T> {
    var credential: URLCredential?
    var headers: [String: String]
    internal let parameters: [String: Any]?
    internal let method: String
    internal let URLString: String
    internal let requestTask: RequestTask = RequestTask()
    internal let requiresAuthentication: Bool

    /// Optional block to obtain a reference to the request's progress instance when available.
    /// With the URLSession http client the request's progress only works on iOS 11.0, macOS 10.13, macCatalyst 13.0, tvOS 11.0, watchOS 4.0.
    /// If you need to get the request's progress in older OS versions, please use Alamofire http client.
    internal var onProgressReady: ((Progress) -> Void)?

    internal required init(
        method: String,
        URLString: String,
        parameters: [String: Any]?,
        headers: [String: String] = [:],
        requiresAuthentication: Bool
    ) {
        self.method = method
        self.URLString = URLString
        self.parameters = parameters
        self.headers = headers
        self.requiresAuthentication = requiresAuthentication

        addHeaders(OpenAPIClientAPI.customHeaders)
    }

    internal func addHeaders(_ aHeaders: [String: String]) {
        for (header, value) in aHeaders {
            headers[header] = value
        }
    }

    @discardableResult
    internal func execute(
        _ apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void
    ) -> RequestTask {
        requestTask
    }

    internal func addHeader(name: String, value: String) -> Self {
        if !value.isEmpty {
            headers[name] = value
        }
        return self
    }

    internal func addCredential() -> Self {
        credential = OpenAPIClientAPI.credential
        return self
    }
}

internal protocol RequestBuilderFactory {
    func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type
    func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type
}
