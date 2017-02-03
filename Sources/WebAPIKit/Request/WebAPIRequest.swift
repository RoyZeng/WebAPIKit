/**
 *  WebAPIKit
 *
 *  Copyright (c) 2017 Evan Liu. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation
import Alamofire

open class WebAPIRequest {

    open let provider: WebAPIProvider
    open let path: String
    open let method: HTTPMethod

    open var requireAuthentication: Bool?
    open var authentication: WebAPIAuthentication?

    /// `WebAPISender` to send out the http request.
    open var sender: WebAPISender?

    /// Query items in url.
    open var queryItems = [URLQueryItem]()

    /// Http header fileds.
    open var headers = HTTPHeaders()

    /// Parameters for POST, PUT, PATCH requests.
    /// To be encoded to `httpBody` by `parameterEncoding`.
    /// Will be ignored if `httpBody` is set.
    open var parameters = Parameters()
    /// Encoding to encode `parameters` to `httpBody`.
    open var parameterEncoding: ParameterEncoding?
    /// Http body for POST, PUT, PATCH requests.
    /// Will ignore `parameters` if value provided.
    open var httpBody: Data?

    public init(provider: WebAPIProvider, path: String, method: HTTPMethod = .get) {
        self.provider = provider
        self.path = path
        self.method = method
    }

    @discardableResult
    open func send(by sender: WebAPISender? = nil) -> Cancelable {
        do {
            let url = try makeURL()
            var request = try makeURLRequest(with: url)
            request = try processURLRequest(request)

            let sender = sender ?? self.sender ?? provider.sender ?? SessionManager.default
            return sender.send(request)
        } catch {
            print(error)
            return CancelBlock {}
        }
    }

    open func makeURL() throws -> URL {
        let url = provider.baseURL.appendingPathComponent(path)
        if queryItems.isEmpty {
            return url
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AFError.invalidURL(url: url)
        }
        components.queryItems = queryItems
        return try components.asURL()
    }

    open func makeURLRequest(with url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if !headers.isEmpty {
            request.allHTTPHeaderFields = headers
        }

        if let httpBody = httpBody {
            request.httpBody = httpBody
        } else if !parameters.isEmpty {
            let encoding = parameterEncoding ?? provider.parameterEncoding ?? URLEncoding.default
            return try encoding.encode(request, with: parameters)
        }

        return request
    }

    open func processURLRequest(_ request: URLRequest) throws -> URLRequest {
        return request
    }

}

// MARK: Config `sender`
extension WebAPIRequest {

    @discardableResult
    open func setSender(_ sender: WebAPISender) -> Self {
        self.sender = sender
        return self
    }

}

// MARK: Config `authentication`
extension WebAPIRequest {

    @discardableResult
    open func setRequireAuthentication(_ requireAuthentication: Bool) -> Self {
        self.requireAuthentication = requireAuthentication
        return self
    }

    @discardableResult
    open func setAuthentication(_ authentication: WebAPIAuthentication) -> Self {
        self.authentication = authentication
        return self
    }

}

// MARK: Config `queryItems`
extension WebAPIRequest {

    @discardableResult
    open func setQueryItems(_ queryItems: [URLQueryItem]) -> Self {
        self.queryItems = queryItems
        return self
    }

    @discardableResult
    open func setQueryItems(_ queryItems: [(name: String, value: String)]) -> Self {
        self.queryItems = queryItems.map { URLQueryItem(name: $0.name, value: $0.value) }
        return self
    }

    @discardableResult
    open func addQueryItem(name: String, value: String) -> Self {
        queryItems.append(URLQueryItem(name: name, value: value))
        return self
    }

}

// MARK: Config `headers`
extension WebAPIRequest {

    @discardableResult
    open func setHeaders(_ headers: [String: String]) -> Self {
        self.headers = headers
        return self
    }

    @discardableResult
    open func addHeader(key: String, value: String) -> Self {
        self.headers[key] = value
        return self
    }

    @discardableResult
    open func setHeaders(_ headers: [RequestHeaderKey: String]) -> Self {
        self.headers = [:]
        headers.forEach { self.headers[$0.rawValue] = $1 }
        return self
    }

    @discardableResult
    open func addHeader(key: RequestHeaderKey, value: String) -> Self {
        self.headers[key.rawValue] = value
        return self
    }

}

// MARK: Config `parameters` & `httpBody`
extension WebAPIRequest {

    @discardableResult
    open func setParameters(_ parameters: [String: Any]) -> Self {
        self.parameters = parameters
        return self
    }

    @discardableResult
    open func addParameter(key: String, value: Any) -> Self {
        parameters[key] = value
        return self
    }

    @discardableResult
    open func setParameterEncoding(_ parameterEncoding: ParameterEncoding) -> Self {
        self.parameterEncoding = parameterEncoding
        return self
    }

    @discardableResult
    open func setHttpBody(_ httpBody: Data) -> Self {
        self.httpBody = httpBody
        return self
    }

}